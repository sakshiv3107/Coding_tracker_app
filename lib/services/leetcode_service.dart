import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';
// import '../widgets/recent_submission_section.dart';
import '../models/submission.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LeetcodeService
// Strategy (mobile/desktop):
//   1. In-memory cache (5 min) → return instantly
//   2. Disk cache (24 hr)      → return + background-refresh
//   3. Parallel race across 4 sources, first success wins:
//        A. Self-hosted Vercel proxy  (most reliable, no CORS issues)
//        B. leetcode.com/graphql      (direct, works on Android/iOS)
//        C. alfa-leetcode-api REST    (fallback, warm instance only)
//        D. leetcode-rest-api Vercel  (last resort)
// ═══════════════════════════════════════════════════════════════════════════════

class LeetcodeService {
  // ── In-memory cache ─────────────────────────────────────────────────────────
  LeetcodeStats? _cache;
  DateTime? _lastFetch;
  static const Duration _memCacheDuration = Duration(minutes: 5);
  static const Duration _diskCacheDuration = Duration(hours: 24);

  // ── In-flight dedup ──────────────────────────────────────────────────────────
  final Map<String, Completer<LeetcodeStats>> _inFlight = {};

  // ── Shared prefs keys ────────────────────────────────────────────────────────
  static const String _cacheKeyPrefix = 'lc_cache_';
  static const String _cacheTimePrefix = 'lc_cache_time_';

  // ── !! REPLACE with your Vercel project URL after deploying api/leetcode.js ──
  // !! If you haven't deployed yet, leave as empty string and the source will
  // !! be skipped automatically.
  static const String _vercelProxyBase = "";
  // Example: "https://my-lc-proxy.vercel.app"

  // ── Timeouts ─────────────────────────────────────────────────────────────────
  static const Duration _singleSourceTimeout = Duration(seconds: 20);
  static const Duration _raceTimeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  Future<LeetcodeStats> fetchData(
    String username, {
    bool forceRefresh = false,
    void Function(LeetcodeStats)? onBackgroundRefresh,
  }) async {
    if (username.isEmpty) throw Exception("Username cannot be empty");

    // 1 ── Memory cache
    if (!forceRefresh && _isCacheFresh()) {
      debugPrint("[LC] ✅ memory cache hit");
      return _cache!;
    }

    // 2 ── Disk cache → return + SWR
    if (!forceRefresh) {
      final disk = await _loadFromDisk(username);
      if (disk != null) {
        debugPrint("[LC] ✅ disk cache hit — refreshing in background");
        _cache = disk;
        _lastFetch = DateTime.now();
        _backgroundRefresh(username, onBackgroundRefresh);
        return disk;
      }
    }

    // 3 ── Full fetch
    return _fetchFresh(username);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL FETCH ORCHESTRATION
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isCacheFresh() =>
      _cache != null &&
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _memCacheDuration;

  void _backgroundRefresh(
    String username,
    void Function(LeetcodeStats)? onRefresh,
  ) {
    if (_inFlight.containsKey(username)) return;
    final completer = Completer<LeetcodeStats>();
    _inFlight[username] = completer;

    _fetchFresh(username)
        .then((stats) {
          _cache = stats;
          _lastFetch = DateTime.now();
          _saveToDisk(username, stats);
          onRefresh?.call(stats);
          completer.complete(stats);
        })
        .catchError((e) {
          debugPrint("[LC] ❌ background refresh failed: $e");
          completer.completeError(e);
        })
        .whenComplete(() => _inFlight.remove(username));
  }

  Future<LeetcodeStats> _fetchFresh(String username) async {
    debugPrint("[LC] 🔄 Starting multi-source assembly for: $username");
    
    // We run parallel 'Best Effort' jobs for each major data part
    final results = await Future.wait([
      _fetchPart((u) => _getProfile(u), username, "Profile"),
      _fetchPart((u) => _getSubmissions(u), username, "Submissions"),
    ]);

    final profileStats = results[0];
    final subStats = results[1];

    if (profileStats == null) {
      throw Exception("Could not fetch profile data for '$username' from any source.");
    }

    // Join the results
    final combined = LeetcodeStats(
      totalSolved: profileStats.totalSolved,
      easy: profileStats.easy,
      medium: profileStats.medium,
      hard: profileStats.hard,
      avatar: profileStats.avatar,
      ranking: profileStats.ranking,
      rating: profileStats.rating,
      submissionCalendar: profileStats.submissionCalendar,
      activeDays: profileStats.activeDays,
      streak: profileStats.streak,
      longestStreak: profileStats.longestStreak,
      contestRating: profileStats.contestRating,
      highestRating: profileStats.highestRating,
      globalRanking: profileStats.globalRanking,
      topPercentage: profileStats.topPercentage,
      totalContests: profileStats.totalContests,
      contestHistory: profileStats.contestHistory,
      badges: profileStats.badges,
      tagStats: profileStats.tagStats,
      // Take missions from subStats if available, otherwise from profileStats
      recentSubmissions: (subStats?.recentSubmissions?.isNotEmpty ?? false) 
          ? subStats!.recentSubmissions 
          : profileStats.recentSubmissions,
    );

    _cache = combined;
    _lastFetch = DateTime.now();
    await _saveToDisk(username, combined);
    
    debugPrint("[LC] 🏁 Combined fetch successful: solved=${combined.totalSolved}, submissions=${combined.recentSubmissions?.length}");
    return combined;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<LeetcodeStats?> _fetchPart(Future<LeetcodeStats> Function(String) fetcher, String username, String label) async {
    try {
      return await _race([fetcher(username)], timeout: _raceTimeout);
    } catch (e) {
      debugPrint("[LC] ⚠️ Failed to fetch $label for $username: $e");
      return null;
    }
  }

  Future<LeetcodeStats> _getProfile(String username) async {
    final tasks = <Future<LeetcodeStats>>[];
    if (_vercelProxyBase.isNotEmpty) {
      tasks.add(_fetchGraphQL(username, "$_vercelProxyBase/api/leetcode", label: "Proxy GQL Profile", query: _gqlProfileQuery));
      tasks.add(_fetchRest(username, _vercelProxyBase, label: "Proxy REST Profile"));
    }
    tasks.add(_fetchGraphQL(username, "https://leetcode.com/graphql", label: "Direct GQL Profile", query: _gqlProfileQuery));
    tasks.add(_fetchRest(username, "https://alfa-leetcode-api.onrender.com", label: "alfa REST Profile"));
    return _race(tasks, timeout: _raceTimeout);
  }

  Future<LeetcodeStats> _getSubmissions(String username) async {
    final tasks = <Future<LeetcodeStats>>[];
    if (_vercelProxyBase.isNotEmpty) {
      tasks.add(_fetchGraphQL(username, "$_vercelProxyBase/api/leetcode", label: "Proxy GQL Subs", query: _gqlSubQuery));
    }
    tasks.add(_fetchGraphQL(username, "https://leetcode.com/graphql", label: "Direct GQL Subs", query: _gqlSubQuery));
    tasks.add(_fetchRest(username, "https://alfa-leetcode-api.onrender.com", label: "alfa REST Subs"));
    return _race(tasks, timeout: _raceTimeout);
  }

  static const String _gqlProfileQuery = r"""
    query userPublicProfile($username: String!) {
      matchedUser(username: $username) {
        profile { ranking userAvatar }
        submissionCalendar
        submitStatsGlobal { acSubmissionNum { difficulty count } }
        badges { name icon hoverText creationDate }
        tagProblemCounts {
          advanced { tagName problemsSolved }
          intermediate { tagName problemsSolved }
          fundamental { tagName problemsSolved }
        }
      }
      userContestRanking(username: $username) {
        rating globalRanking topPercentage attendedContestsCount
      }
      userContestRankingHistory(username: $username) {
        attended rating rank problemsSolved totalProblems
        contest { title startTime }
      }
    }
  """;

  static const String _gqlSubQuery = r"""
    query getRecentSubmissions($username: String!) {
      recentSubmissionList(username: $username, limit: 20) {
        title
        titleSlug
        statusDisplay
        lang
        timestamp
      }
    }
  """;

  /// Returns the result of the first future that completes successfully.
  Future<T> _race<T>(List<Future<T>> futures, {required Duration timeout}) {
    if (futures.isEmpty) throw Exception("No sources configured");

    final completer = Completer<T>();
    var errorCount = 0;
    final errors = <dynamic>[];

    for (final f in futures) {
      f
          .then((value) {
            if (!completer.isCompleted) completer.complete(value);
          })
          .catchError((e) {
            errors.add(e);
            errorCount++;
            if (errorCount == futures.length && !completer.isCompleted) {
              completer.completeError(
                Exception(
                  "All ${futures.length} sources failed:\n${errors.join('\n')}",
                ),
              );
            }
          });
    }

    return completer.future.timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException("Race timed out after ${timeout.inSeconds}s"),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCE A — Vercel Proxy (GET /?username=xxx)
  // ═══════════════════════════════════════════════════════════════════════════



  static const String _userAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  Future<LeetcodeStats> _fetchGraphQL(
    String username,
    String url, {
    required String label,
    int maxRetries = 1,
    String? query,
  }) async {
    final finalQuery = query ?? _gqlProfileQuery;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Referer": "https://leetcode.com/",
                "Origin": "https://leetcode.com",
                "x-csrftoken": "dummy",
                "Cookie": "csrftoken=dummy",
              },
              body: jsonEncode({
                "query": finalQuery,
                "variables": {"username": username},
              }),
            )
            .timeout(_singleSourceTimeout);

        if (res.statusCode == 429 && attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        }
        if (res.statusCode != 200) {
          throw Exception("[$label] HTTP ${res.statusCode}");
        }

        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json["errors"] != null) {
          throw Exception("[$label] GQL: ${json["errors"][0]["message"]}");
        }

        debugPrint("[LC] ✅ $label succeeded");
        return _parseGraphQLResponse(json, username);
      } catch (e) {
        if (attempt >= maxRetries) {
          debugPrint("[LC] ❌ $label failed: $e");
          rethrow;
        }
      }
    }
    throw Exception("[$label] exhausted retries");
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOURCE C/D — REST Fallback
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // alfa-leetcode-api endpoint map (confirmed working as of Mar 2025):
  //   GET /userProfile/:username          → profile stats
  //   GET /:username/calendar             → submissionCalendar
  //   GET /:username/contest              → { contestRanking, contestRankingInfo }
  //   GET /submission?username=x&limit=10 → { submission: [...] }   ← NOT /acSubmission
  //
  // ═══════════════════════════════════════════════════════════════════════════

  Future<LeetcodeStats> _fetchRest(
    String username,
    String baseUrl, {
    required String label,
  }) async {
    debugPrint("[LC] Source $label → $baseUrl");

    Future<Map<String, dynamic>?> tryGet(String path) async {
      try {
        final res = await http
            .get(Uri.parse("$baseUrl/$path"))
            .timeout(_singleSourceTimeout);

        if (res.statusCode == 200) {
          return jsonDecode(res.body) as Map<String, dynamic>;
        }
        debugPrint("[LC]   $label/$path → HTTP ${res.statusCode}");
        return null;
      } catch (e) {
        debugPrint("[LC]   $label/$path → error: $e");
        return null;
      }
    }

    // Fire endpoints in parallel
    final results = await Future.wait([
      tryGet("$username"),
      tryGet("$username/submissionCalendar"),
      tryGet("$username/contest"),
      tryGet("$username/submission"), // index 3
      tryGet("$username/acSubmission"), // index 4
      tryGet("$username/skillStats"), // index 5
    ]);

    final profileData = results[0];
    final calBody = results[1];
    final contestBody = results[2];
    final submitBody = results[3];
    final acSubmitBody = results[4];
    final skillBody = results[5];

    if (profileData == null) {
      throw Exception("[$label] profile endpoint returned null/error");
    }

    // ── Submission calendar ──────────────────────────────────────────────────
    final Map<DateTime, int> calendar = {};
    final rawCal = calBody?["submissionCalendar"];
    if (rawCal != null) {
      final Map<String, dynamic> calMap = rawCal is String
          ? jsonDecode(rawCal) as Map<String, dynamic>
          : rawCal as Map<String, dynamic>;
      calMap.forEach((key, val) {
        final ts = int.tryParse(key);
        if (ts != null) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          calendar[DateTime(d.year, d.month, d.day)] = val is int ? val : 0;
        }
      });
    }

    // ── Recent submissions ───────────────────────────────────────────────────
    final List<Submission> recentSubmissions = [];
    var rawSubs =
        submitBody?["submission"] ?? submitBody?["recentSubmissionList"];
    if (rawSubs is! List || (rawSubs as List).isEmpty) {
      rawSubs = acSubmitBody?["submission"] ?? acSubmitBody?["acSubmission"];
    }

    if (rawSubs is List) {
      for (final s in rawSubs) {
        try {
          final tsMs =
              (int.tryParse(s["timestamp"]?.toString() ?? '') ?? 0) * 1000;
          recentSubmissions.add(
            Submission(
              title: s["title"]?.toString() ?? "",
              titleSlug: s["titleSlug"]?.toString() ?? "",
              difficulty: s["difficulty"]?.toString() ?? "",
              status:
                  s["statusDisplay"]?.toString() ??
                  s["status"]?.toString() ??
                  "",
              lang: s["lang"]?.toString() ?? s["language"]?.toString() ?? "",
              timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
            ),
          );
        } catch (e) {
          debugPrint("[LC] $label: skipped malformed submission: $e");
        }
      }
    }

    // ── Contest history ──────────────────────────────────────────────────────
    // alfa-leetcode-api shape (confirmed):
    //   contestBody = {
    //     contestRanking: { ... },
    //     contestRankingInfo: {
    //       contestParticipation: [ { contest: { title, startTime }, rating, rank, ... } ]
    //     }
    //   }
    final List<LeetCodeContestHistory> contestHistory = [];

    // Support both nested (new) and flat (old) layout
    final rankingInfo =
        contestBody?["contestRankingInfo"] as Map<String, dynamic>?;
    final participationRaw =
        rankingInfo?["contestParticipation"] ??
        contestBody?["contestParticipation"];
    final participation = participationRaw as List?;

    if (participation != null) {
      for (final item in participation) {
        try {
          final i = item as Map<String, dynamic>;
          final contest = i["contest"] as Map<String, dynamic>?;
          final stRaw = contest?["startTime"];
          if (stRaw == null) continue;

          final startMs =
              (stRaw is int ? stRaw : int.tryParse(stRaw.toString()) ?? 0) *
              1000;

          contestHistory.add(
            LeetCodeContestHistory(
              contestTitle: contest?["title"]?.toString() ?? "Contest",
              rating: ((i["rating"] ?? i["newRating"] ?? 0) as num).toDouble(),
              rank: (i["rank"] ?? i["ranking"] ?? 0) as int,
              solved: i["problemsSolved"] as int?,
              totalProblems: i["totalProblems"] as int?,
              date: DateTime.fromMillisecondsSinceEpoch(startMs),
            ),
          );
        } catch (e) {
          debugPrint("[LC] $label: skipped malformed contest entry: $e");
        }
      }
    }

    // ── Contest ranking summary ──────────────────────────────────────────────
    // May live at top level or inside contestRankingInfo
    final summary = rankingInfo ?? contestBody;

    final streaks = _calculateStreaks(calendar);

    // ── Tag stats ─────────────────────────────────────────────────────────────
    final Map<String, int> tagStats = {};
    if (skillBody != null) {
      final tags =
          skillBody["tagSkillStats"] ?? skillBody["skillStats"] ?? skillBody;
      if (tags is Map) {
        for (final level in ["fundamental", "intermediate", "advanced"]) {
          final cats = tags[level] as List?;
          if (cats != null) {
            for (final item in cats) {
              final i = item as Map<String, dynamic>;
              final name = i["tagName"]?.toString() ?? "";
              if (name.isNotEmpty) {
                tagStats[name] =
                    (tagStats[name] ?? 0) + _toInt(i["problemsSolved"]);
              }
            }
          }
        }
      }
    }

    debugPrint(
      "[LC] ✅ $label succeeded — "
      "solved=${profileData["totalSolved"]} "
      "contests=${contestHistory.length} "
      "submissions=${recentSubmissions.length} "
      "tags=${tagStats.length}",
    );

    return LeetcodeStats(
      totalSolved: _toInt(profileData["totalSolved"]),
      easy: _toInt(profileData["easySolved"]),
      medium: _toInt(profileData["mediumSolved"]),
      hard: _toInt(profileData["hardSolved"]),
      avatar: profileData["avatar"]?.toString() ?? "",
      ranking: _toInt(profileData["ranking"]),
      rating: _toDouble(summary?["contestRating"]),
      submissionCalendar: calendar,
      activeDays: calendar.length,
      streak: streaks['streak'] ?? 0,
      longestStreak: streaks['longestStreak'] ?? 0,
      contestRating: summary?["contestRating"] != null
          ? _toDouble(summary!["contestRating"])
          : null,
      highestRating: summary?["contestHighestRating"] != null
          ? _toDouble(summary!["contestHighestRating"])
          : null,
      globalRanking: summary?["contestGlobalRanking"] as int?,
      topPercentage: summary?["contestTopPercentage"] != null
          ? _toDouble(summary!["contestTopPercentage"])
          : null,
      totalContests: summary?["contestAttend"] as int?,
      contestHistory: contestHistory,
      recentSubmissions: recentSubmissions,
      tagStats: tagStats,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GraphQL Response Parser (Sources A + B)
  // ═══════════════════════════════════════════════════════════════════════════

  LeetcodeStats _parseGraphQLResponse(
    Map<String, dynamic> json,
    String username,
  ) {
    final data = (json["data"] ?? json) as Map<String, dynamic>;
    final matchedUser = data["matchedUser"] as Map<String, dynamic>?;

    if (matchedUser == null) {
      throw Exception("User '$username' not found on LeetCode");
    }

    final profile =
        (matchedUser["profile"] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final statsData =
        matchedUser["submitStats"] ?? matchedUser["submitStatsGlobal"];
    final submitStats = (statsData?["acSubmissionNum"] as List?) ?? [];
    final contestRanking = data["userContestRanking"] as Map<String, dynamic>?;

    // ── Submission calendar ──────────────────────────────────────────────────
    final Map<DateTime, int> calendar = {};
    final rawCal = matchedUser["submissionCalendar"];
    if (rawCal != null && rawCal.toString().isNotEmpty) {
      try {
        final calMap = rawCal is String
            ? jsonDecode(rawCal) as Map<String, dynamic>
            : rawCal as Map<String, dynamic>;
        calMap.forEach((key, value) {
          final ts = int.tryParse(key);
          if (ts != null) {
            final d = DateTime.fromMillisecondsSinceEpoch(
              ts * 1000,
              isUtc: true,
            );
            calendar[DateTime(d.year, d.month, d.day)] = value as int;
          }
        });
      } catch (e) {
        debugPrint("[LC] calendar parse error: $e");
      }
    }

    // ── Solve counts ─────────────────────────────────────────────────────────
    int total = 0, easy = 0, medium = 0, hard = 0;
    for (final stat in submitStats) {
      final s = stat as Map<String, dynamic>;
      switch (s["difficulty"]) {
        case "All":
          total = _toInt(s["count"]);
          break;
        case "Easy":
          easy = _toInt(s["count"]);
          break;
        case "Medium":
          medium = _toInt(s["count"]);
          break;
        case "Hard":
          hard = _toInt(s["count"]);
          break;
      }
    }

    // ── Contest history ──────────────────────────────────────────────────────
    final List<LeetCodeContestHistory> contestHistory = [];
    final historyList = data["userContestRankingHistory"] as List?;
    if (historyList != null) {
      for (final item in historyList) {
        try {
          final i = item as Map<String, dynamic>;
          final contest = i["contest"] as Map<String, dynamic>?;
          if (i["rating"] == null || contest?["startTime"] == null) continue;

          contestHistory.add(
            LeetCodeContestHistory(
              contestTitle: contest?["title"]?.toString() ?? "Contest",
              rating: _toDouble(i["rating"]),
              rank: _toInt(i["rank"]),
              solved: i["problemsSolved"] as int?,
              totalProblems: i["totalProblems"] as int?,
              date: DateTime.fromMillisecondsSinceEpoch(
                _toInt(contest!["startTime"]) * 1000,
              ),
            ),
          );
        } catch (e) {
          debugPrint("[LC] skipped contest history entry: $e");
        }
      }
    }

    // ── Recent submissions ───────────────────────────────────────────────────
    final List<Submission> recentSubmissions = [];
    final recentList = data["recentSubmissionList"] as List?;

    debugPrint("[LC] Raw submissions count: ${recentList?.length ?? 'NULL'}");
    if (recentList != null) {
      for (final item in recentList) {
        try {
          final i = item as Map<String, dynamic>;
          // Safe parse — never force-unwrap
          final tsMs =
              (int.tryParse(i["timestamp"]?.toString() ?? '') ?? 0) * 1000;
          recentSubmissions.add(
            Submission(
              title: i["title"]?.toString() ?? "",
              titleSlug: i["titleSlug"]?.toString() ?? "",
              difficulty: "",
              status: i["statusDisplay"]?.toString() ?? "",
              lang: i["lang"]?.toString() ?? "",
              timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
            ),
          );
        } catch (e) {
          debugPrint("[LC] skipped recent submission entry: $e");
        }
      }
    }

    // ── Badges ───────────────────────────────────────────────────────────────
    final List<LeetCodeBadge> badges = [];
    final badgesList = matchedUser["badges"] as List?;
    if (badgesList != null) {
      for (final b in badgesList) {
        final badge = b as Map<String, dynamic>;
        var icon = badge["icon"]?.toString() ?? "";
        if (icon.isNotEmpty && !icon.startsWith("http")) {
          icon = "https://leetcode.com$icon";
        }
        badges.add(
          LeetCodeBadge(
            name: badge["name"]?.toString() ?? "",
            icon: icon,
            description: badge["hoverText"]?.toString(),
            earnedDate: badge["creationDate"]?.toString(),
          ),
        );
      }
    }

    // ── Tag stats ─────────────────────────────────────────────────────────────
    final Map<String, int> tagStats = {};
    final tagData = matchedUser["tagProblemCounts"] as Map<String, dynamic>?;
    if (tagData != null) {
      for (final level in ["fundamental", "intermediate", "advanced"]) {
        final cats = tagData[level] as List?;
        if (cats != null) {
          for (final item in cats) {
            final i = item as Map<String, dynamic>;
            final name = i["tagName"]?.toString() ?? "";
            if (name.isNotEmpty) {
              tagStats[name] =
                  (tagStats[name] ?? 0) + _toInt(i["problemsSolved"]);
            }
          }
        }
      }
    }

    final double rating = _toDouble(contestRanking?["rating"]);
    double? highestRating;
    if (contestHistory.isNotEmpty) {
      highestRating = contestHistory
          .map((h) => h.rating)
          .reduce((a, b) => a > b ? a : b);
    }

    final streaks = _calculateStreaks(calendar);

    debugPrint(
      "[LC] ✅ GraphQL parse done — "
      "solved=$total easy=$easy medium=$medium hard=$hard "
      "contests=${contestHistory.length} "
      "submissions=${recentSubmissions.length} "
      "badges=${badges.length}",
    );

    return LeetcodeStats(
      totalSolved: total,
      easy: easy,
      medium: medium,
      hard: hard,
      avatar: profile["userAvatar"]?.toString() ?? "",
      ranking: _toInt(profile["ranking"]),
      rating: rating,
      submissionCalendar: calendar,
      streak: streaks['streak'] ?? 0,
      longestStreak: streaks['longestStreak'] ?? 0,
      activeDays: calendar.length,
      contestRating: rating > 0 ? rating : null,
      highestRating: highestRating,
      globalRanking: contestRanking?["globalRanking"] as int?,
      topPercentage: contestRanking?["topPercentage"] != null
          ? _toDouble(contestRanking!["topPercentage"])
          : null,
      totalContests: contestRanking?["attendedContestsCount"] as int?,
      contestHistory: contestHistory,
      recentSubmissions: recentSubmissions,
      badges: badges,
      tagStats: tagStats,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISK CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<LeetcodeStats?> _loadFromDisk(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cacheKeyPrefix$username');
      final timeMs = prefs.getInt('$_cacheTimePrefix$username');
      if (raw == null || timeMs == null) return null;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timeMs),
      );
      if (age > _diskCacheDuration) return null;

      return LeetcodeStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint("[LC] disk cache read error: $e");
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
      debugPrint("[LC] disk cache write error: $e");
    }
  }

  Future<void> clearCache(String username) async {
    _cache = null;
    _lastFetch = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix$username');
      await prefs.remove('$_cacheTimePrefix$username');
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAK CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, int> _calculateStreaks(Map<DateTime, int> calendar) {
    if (calendar.isEmpty) return {'streak': 0, 'longestStreak': 0};

    final sorted =
        calendar.keys.map((d) => DateTime(d.year, d.month, d.day)).toList()
          ..sort();

    // Longest streak
    int maxStreak = 1;
    int tempStreak = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
        if (tempStreak > maxStreak) maxStreak = tempStreak;
      } else if (diff > 1) {
        tempStreak = 1;
      }
    }

    // Current streak
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yest = todayDate.subtract(const Duration(days: 1));

    int current = 0;
    if (calendar.containsKey(todayDate) || calendar.containsKey(yest)) {
      current = 1;
      var check = calendar.containsKey(todayDate) ? todayDate : yest;
      while (true) {
        check = check.subtract(const Duration(days: 1));
        if (calendar.containsKey(
          DateTime(check.year, check.month, check.day),
        )) {
          current++;
        } else {
          break;
        }
      }
    }

    return {'streak': current, 'longestStreak': maxStreak};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
