import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';

class LeetcodeService {
  // ─── In-memory cache ───────────────────────────────────────────────────────
  LeetcodeStats? _cache;
  DateTime? _lastFetch;
  final Duration _cacheDuration = const Duration(minutes: 5);

  // ─── Stale-while-revalidate controller ────────────────────────────────────
  // Prevents multiple background refreshes from racing
  final Map<String, Completer<LeetcodeStats>> _inFlight = {};

  static const String _cacheKeyPrefix = 'lc_cache_';
  static const String _cacheTimePrefix = 'lc_cache_time_';

  // ─── GraphQL query ─────────────────────────────────────────────────────────
  final String _query = """
    query userPublicProfile(\$username: String!) {
      matchedUser(username: \$username) {
        profile {
          ranking
          userAvatar
        }
        submissionCalendar
        submitStats: submitStatsGlobal {
          acSubmissionNum {
            difficulty
            count
          }
        }
        badges {
          name
          icon
          hoverText
          creationDate
        }
      }
      userContestRanking(username: \$username) {
        rating
        globalRanking
        topPercentage
        attendedContestsCount
      }
      userContestRankingHistory(username: \$username) {
        attended
        rating
        rank
        contest {
          title
          startTime
        }
      }
      recentSubmissionList(username: \$username, limit: 10) {
        title
        titleSlug
        timestamp
        statusDisplay
        lang
      }
      tagProblemCounts(username: \$username) {
        advanced {
          tagName
          problemsSolved
        }
        intermediate {
          tagName
          problemsSolved
        }
        fundamental {
          tagName
          problemsSolved
        }
      }
    }
    """;

  // ─── Public entry point ────────────────────────────────────────────────────
  Future<LeetcodeStats> fetchData(
    String username, {
    bool forceRefresh = false,
    void Function(LeetcodeStats)? onBackgroundRefresh,
  }) async {
    if (username.isEmpty) throw Exception("Username cannot be empty");

    // 1. In-memory cache hit (Fresh)
    if (!forceRefresh &&
        _cache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      debugPrint("LeetCode: returning fresh in-memory cache");
      return _cache!;
    }

    // 2. Disk cache hit → return immediately, refresh in background (SWR)
    if (!forceRefresh) {
      final diskData = await _loadFromDisk(username);
      if (diskData != null) {
        debugPrint("LeetCode: returning disk cache, refreshing in background");
        _cache = diskData;
        _lastFetch = DateTime.now();

        // Fire-and-forget background refresh
        _backgroundRefresh(username, onBackgroundRefresh);
        return diskData;
      }
    }

    // 3. No cache or forced → fetch fresh
    return _fetchFresh(username);
  }

  // ─── Background refresh ────────────────────────────────────────────────────
  void _backgroundRefresh(
    String username,
    void Function(LeetcodeStats)? onRefresh,
  ) {
    if (_inFlight.containsKey(username)) return;

    final completer = Completer<LeetcodeStats>();
    _inFlight[username] = completer;

    _fetchFresh(username).then((stats) {
      _cache = stats;
      _lastFetch = DateTime.now();
      _saveToDisk(username, stats);
      onRefresh?.call(stats);
      completer.complete(stats);
    }).catchError((e) {
      debugPrint("LeetCode: background refresh failed → $e");
      completer.completeError(e);
    }).whenComplete(() {
      _inFlight.remove(username);
    });
  }

  // ─── Parallel Strategy ───────────────────────────────────────────────────
  /// Fires all sources simultaneously and returns the FIRST SUCCESSFUL one.
  /// This is MUCH more stable than Future.any because it ignores individual failures.
  Future<LeetcodeStats> _fetchFresh(String username) async {
    debugPrint("LeetCode: starting optimized parallel fetch for $username");

    // GraphQL Endpoints (CORS-enabled or server-to-server)
    final urls = [
      "https://alfa-leetcode-api.onrender.com/graphql",
      "https://leetcode-api-f6df.onrender.com/graphql",
      if (!kIsWeb) "https://leetcode.com/graphql",
    ];

    final List<Future<LeetcodeStats>> tasks = [];

    // 1. Add GraphQL Sources
    for (var url in urls) {
      tasks.add(_fetchGraphQL(username, url));
    }

    // 2. Add REST Fallback Sources
    tasks.add(_fetchRest(username, "https://alfa-leetcode-api.onrender.com"));
    tasks.add(_fetchRest(username, "https://leetcode-rest-api.vercel.app"));

    // 3. Race for the first success
    try {
      final stats = await _firstSuccess(tasks);
      
      // Update cache
      _cache = stats;
      _lastFetch = DateTime.now();
      _saveToDisk(username, stats);
      
      return stats;
    } catch (e) {
      debugPrint("LeetCode: all sources failed: $e");
      throw Exception("All sources failed. Check your connection or try again later.");
    }
  }

  // ─── Helper: First Success ────────────────────────────────────────────────
  /// Returns the first SUCCESSFUL future, ignoring errors unless ALL fail.
  Future<T> _firstSuccess<T>(List<Future<T>> futures) async {
    final completer = Completer<T>();
    int count = 0;
    final List<dynamic> errors = [];

    for (var f in futures) {
      f.then((value) {
        if (!completer.isCompleted) completer.complete(value);
      }).catchError((e) {
        errors.add(e);
        count++;
        if (count == futures.length && !completer.isCompleted) {
          completer.completeError(Exception(errors.join(", ")));
        }
      });
    }

    return completer.future.timeout(
      const Duration(seconds: 15), 
      onTimeout: () => throw TimeoutException("Fetching LeetCode data timed out."),
    );
  }

  // ─── GraphQL fetch with retry ──────────────────────────────────────────────
  Future<LeetcodeStats> _fetchGraphQL(String username, String url, {int retries = 1}) async {
    int attempt = 0;
    while (attempt <= retries) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Referer": "https://leetcode.com",
            if (!kIsWeb) "User-Agent": "Mozilla/5.0",
          },
          body: jsonEncode({
            'query': _query,
            'variables': {'username': username},
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 429 && attempt < retries) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          attempt++;
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception("HTTP ${response.statusCode}");
        }

        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse["errors"] != null) {
          throw Exception(jsonResponse["errors"][0]["message"]);
        }

        return _parseGraphQLResponse(jsonResponse, username);
      } catch (e) {
        if (attempt >= retries) rethrow;
        attempt++;
      }
    }
    throw Exception("GraphQL failed");
  }

  // ─── REST fallback fetch ───────────────────────────────────────────────────
  Future<LeetcodeStats> _fetchRest(String username, String baseUrl) async {
    Future<http.Response> getWithRetry(String endpoint) async {
      int attempt = 0;
      while (attempt <= 1) {
        try {
          final res = await http.get(Uri.parse("$baseUrl/$endpoint")).timeout(const Duration(seconds: 8));
          if (res.statusCode == 429 && attempt < 1) {
            await Future.delayed(const Duration(seconds: 2));
            attempt++;
            continue;
          }
          return res;
        } catch (e) {
          if (attempt >= 1) rethrow;
          attempt++;
        }
      }
      throw Exception("REST retry failed");
    }

    try {
      // Fetch required pieces in parallel
      final results = await Future.wait([
        getWithRetry("userProfile/$username"),
        getWithRetry("$username/calendar"),
        getWithRetry("$username/contest"),
      ]);

      if (results[0].statusCode != 200) throw Exception("REST profile failed");

      final profileData = jsonDecode(results[0].body) as Map<String, dynamic>;
      final calendarBody = results[1].statusCode == 200 ? jsonDecode(results[1].body) : null;
      final contestBody = results[2].statusCode == 200 ? jsonDecode(results[2].body) : null;

      // Basic parsing logic (minimized for speed)
      final Map<DateTime, int> cal = {};
      final rawCal = calendarBody?["submissionCalendar"];
      if (rawCal != null) {
        final Map<String, dynamic> calMap = rawCal is String ? jsonDecode(rawCal) : rawCal;
        calMap.forEach((key, val) {
          final ts = int.tryParse(key);
          if (ts != null) {
            final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
            cal[DateTime(d.year, d.month, d.day)] = val is int ? val : 0;
          }
        });
      }

      return LeetcodeStats(
        totalSolved: (profileData["totalSolved"] ?? 0) as int,
        easy: (profileData["easySolved"] ?? 0) as int,
        medium: (profileData["mediumSolved"] ?? 0) as int,
        hard: (profileData["hardSolved"] ?? 0) as int,
        avatar: profileData["avatar"]?.toString() ?? "",
        ranking: (profileData["ranking"] ?? 0) as int,
        rating: ((contestBody?["contestRating"] ?? 0) as num).toDouble(),
        submissionCalendar: cal,
        activeDays: cal.length,
        streak: 0,
        longestStreak: 0,
        contestRating: contestBody?["contestRating"] != null
            ? (contestBody!["contestRating"] as num).toDouble()
            : null,
        highestRating: contestBody?["contestHighestRating"] != null
            ? (contestBody!["contestHighestRating"] as num).toDouble()
            : null,
        globalRanking: contestBody?["contestGlobalRanking"],
        topPercentage: contestBody?["contestTopPercentage"] != null
            ? (contestBody!["contestTopPercentage"] as num).toDouble()
            : null,
        totalContests: contestBody?["contestAttend"],
        contestHistory: [], // Usually not needed for dashboard
        recentSubmissions: [],
      );
    } catch (e) {
      throw Exception("REST fallback failed: $e");
    }
  }

  // ─── Disk cache ────────────────────────────────────────────────────────────
  Future<LeetcodeStats?> _loadFromDisk(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('$_cacheKeyPrefix$username');
      final timeMs = prefs.getInt('$_cacheTimePrefix$username');

      if (json == null || timeMs == null) return null;

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timeMs),
      );

      // Disk cache valid for 24 hours; stale beyond that
      if (cacheAge > const Duration(hours: 24)) return null;

      return LeetcodeStats.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint("LeetCode: disk cache read failed → $e");
      return null;
    }
  }

  Future<void> _saveToDisk(String username, LeetcodeStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_cacheKeyPrefix$username',
        jsonEncode(stats.toJson()),
      );
      await prefs.setInt(
        '$_cacheTimePrefix$username',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint("LeetCode: disk cache write failed → $e");
    }
  }

  /// Call this to wipe both in-memory and disk cache for a user.
  Future<void> clearCache(String username) async {
    _cache = null;
    _lastFetch = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix$username');
      await prefs.remove('$_cacheTimePrefix$username');
    } catch (_) {}
  }

  // ─── GraphQL response parser ───────────────────────────────────────────────
  LeetcodeStats _parseGraphQLResponse(
    Map<String, dynamic> jsonResponse,
    String username,
  ) {
    final data = jsonResponse.containsKey("data")
        ? jsonResponse["data"] as Map<String, dynamic>
        : jsonResponse;

    final matchedUser =
        (data["matchedUser"] ?? data) as Map<String, dynamic>?;

    if (matchedUser == null || matchedUser.isEmpty) {
      throw Exception("User '$username' not found");
    }

    final profile = (matchedUser["profile"] ?? {}) as Map<String, dynamic>;
    final submissionStatsData =
        matchedUser["submitStats"] ?? matchedUser["submitStatsGlobal"];
    final submitStats = submissionStatsData != null
        ? (submissionStatsData["acSubmissionNum"] as List?)
        : null;
    final contestRanking =
        data["userContestRanking"] as Map<String, dynamic>?;

    // Submission calendar
    final Map<DateTime, int> submissionCalendar = {};
    final calendarRaw = matchedUser["submissionCalendar"];
    if (calendarRaw != null && calendarRaw.toString().isNotEmpty) {
      try {
        final Map<String, dynamic> rawCalendar = calendarRaw is String
            ? jsonDecode(calendarRaw)
            : calendarRaw as Map<String, dynamic>;
        rawCalendar.forEach((key, value) {
          final ts = int.tryParse(key);
          if (ts != null) {
            final date =
                DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
            submissionCalendar[DateTime(date.year, date.month, date.day)] =
                value as int;
          }
        });
      } catch (_) {}
    }

    // Solve counts
    int total = 0, easy = 0, medium = 0, hard = 0;
    if (submitStats != null) {
      for (final stat in submitStats) {
        final s = stat as Map<String, dynamic>;
        if (s["difficulty"] == "All") total = s["count"] as int;
        if (s["difficulty"] == "Easy") easy = s["count"] as int;
        if (s["difficulty"] == "Medium") medium = s["count"] as int;
        if (s["difficulty"] == "Hard") hard = s["count"] as int;
      }
    }

    // Contest history
    final List<LeetCodeContestHistory> contestHistory = [];
    final historyData = data["userContestRankingHistory"] as List?;
    if (historyData != null) {
      for (final item in historyData) {
        try {
          final i = item as Map<String, dynamic>;
          if (i["rating"] != null && i["contest"]?["startTime"] != null) {
            contestHistory.add(LeetCodeContestHistory(
              contestTitle: i["contest"]["title"] ?? "Contest",
              rating: (i["rating"] as num).toDouble(),
              rank: i["rank"] ?? 0,
              date: DateTime.fromMillisecondsSinceEpoch(
                (i["contest"]["startTime"] as int) * 1000,
              ),
            ));
          }
        } catch (_) {}
      }
    }

    // Recent submissions
    final List<RecentSubmission> recentSubmissions = [];
    final recentData = data["recentSubmissionList"] as List?;
    if (recentData != null) {
      for (final item in recentData) {
        try {
          final i = item as Map<String, dynamic>;
          recentSubmissions.add(RecentSubmission(
            title: i["title"] ?? "",
            titleSlug: i["titleSlug"] ?? "",
            difficulty: "",
            status: i["statusDisplay"] ?? "",
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              int.parse(i["timestamp"].toString()) * 1000,
            ),
          ));
        } catch (_) {}
      }
    }

    // Badges
    final List<LeetCodeBadge> badges = [];
    final badgesData = matchedUser["badges"] as List?;
    if (badgesData != null) {
      for (final badge in badgesData) {
        final b = badge as Map<String, dynamic>;
        String icon = b["icon"] ?? "";
        if (icon.isNotEmpty && !icon.startsWith("http")) {
          icon = "https://leetcode.com$icon";
        }
        badges.add(LeetCodeBadge(
          name: b["name"] ?? "",
          icon: icon,
          description: b["hoverText"],
          earnedDate: b["creationDate"],
        ));
      }
    }

    // Tag stats
    final Map<String, int> tagStats = {};
    final tagData = data["tagProblemCounts"] as Map<String, dynamic>?;
    if (tagData != null) {
      for (final level in ["fundamental", "intermediate", "advanced"]) {
        final categories = tagData[level] as List?;
        if (categories != null) {
          for (final item in categories) {
            final i = item as Map<String, dynamic>;
            final name = i["tagName"] ?? "";
            final count = (i["problemsSolved"] ?? 0) as int;
            if (name.isNotEmpty) {
              tagStats[name] = (tagStats[name] ?? 0) + count;
            }
          }
        }
      }
    }

    final double rating = contestRanking?["rating"] != null
        ? (contestRanking!["rating"] as num).toDouble()
        : 0;

    return LeetcodeStats(
      totalSolved: total,
      easy: easy,
      medium: medium,
      hard: hard,
      avatar: profile["userAvatar"] ?? "",
      ranking: profile["ranking"] ?? 0,
      rating: rating,
      submissionCalendar: submissionCalendar,
      streak: 0,
      longestStreak: 0,
      activeDays: submissionCalendar.length,
      contestRating: rating > 0 ? rating : null,
      highestRating: null,
      globalRanking: contestRanking?["globalRanking"],
      topPercentage: contestRanking?["topPercentage"] != null
          ? (contestRanking!["topPercentage"] as num).toDouble()
          : null,
      totalContests: contestRanking?["attendedContestsCount"],
      contestHistory: contestHistory,
      recentSubmissions: recentSubmissions,
      badges: badges,
      tagStats: tagStats,
    );
  }
}