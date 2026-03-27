import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leetcode_stats.dart';
import '../models/submission.dart';
import '../core/exceptions.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LeetcodeService
// Strategy: GraphQL-only with robust caching (Memory + Disk).
// ═══════════════════════════════════════════════════════════════════════════

class LeetcodeService {
  // ── In-memory cache ─────────────────────────────────────────────────────────
  LeetcodeStats? _cache;
  DateTime? _lastFetch;
  static const Duration _memCacheDuration = Duration(minutes: 5);

  // ── In-flight dedup ──────────────────────────────────────────────────────────
  final Map<String, Completer<LeetcodeStats>> _inFlight = {};

  // ── Shared prefs keys ────────────────────────────────────────────────────────
  static const String _cacheKeyPrefix = 'lc_cache_v3_';
  static const String _cacheTimePrefix = 'lc_cache_time_v3_';

  // ── Timeouts & Durations ────────────────────────────────────────────────────
  static const Duration _singleSourceTimeout = Duration(seconds: 15);
  static const Duration _diskCacheDuration = Duration(hours: 24);

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  Future<LeetcodeStats> fetchData(
    String username, {
    bool forceRefresh = false,
    void Function(LeetcodeStats)? onBackgroundRefresh,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) throw ValidationException("LeetCode username required");

    // 1 ── Memory cache
    if (!forceRefresh && _isCacheFresh(cleanUsername)) {
      debugPrint("[LC] ✅ memory cache hit");
      return _cache!;
    }

    // 2 ── Disk cache → return + SWR
    if (!forceRefresh) {
      final disk = await _loadFromDisk(cleanUsername);
      if (disk != null) {
        debugPrint("[LC] ✅ disk cache hit — refreshing in background");
        _cache = disk;
        _lastFetch = DateTime.now();
        _backgroundRefresh(cleanUsername, onBackgroundRefresh);
        return disk;
      }
    }

    // 3 ── Full fetch
    return _fetchFresh(cleanUsername);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL Orchestration
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isCacheFresh(String username) =>
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
    debugPrint("[LC] 🔄 Fetching fresh GraphQL data for: $username");

    try {
      final gqlStats = await _fetchGraphQL(username);
      _cache = gqlStats;
      _lastFetch = DateTime.now();
      await _saveToDisk(username, gqlStats);
      return gqlStats;
    } catch (e) {
      debugPrint("[LC] ❌ Fetch failed: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRAPHQL CORE
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _gqlQuery = r"""
    query combinedUserInfo($username: String!) {
      matchedUser(username: $username) {
        profile { 
          ranking 
          userAvatar 
          realName 
          aboutMe 
          reputation
        }
        submissionCalendar
        submitStatsGlobal { 
          acSubmissionNum { difficulty count } 
        }
        badges { 
          name 
          icon 
          hoverText 
          creationDate 
        }
        tagProblemCounts {
          advanced { tagName problemsSolved }
          intermediate { tagName problemsSolved }
          fundamental { tagName problemsSolved }
        }
      }
      userContestRanking(username: $username) {
        rating 
        globalRanking 
        topPercentage 
        attendedContestsCount
      }
      userContestRankingHistory(username: $username) {
        attended 
        rating 
        ranking
        problemsSolved 
        totalProblems
        contest { title startTime }
      }
      recentSubmissionList(username: $username, limit: 15) {
        title
        titleSlug
        statusDisplay
        lang
        timestamp
      }
    }
  """;

  Future<String> _fetchCsrfToken() async {
    try {
      final res = await http.get(
        Uri.parse("https://leetcode.com/"),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        },
      ).timeout(const Duration(seconds: 10));
      
      final cookies = res.headers["set-cookie"] ?? "";
      final match = RegExp(r'csrftoken=([^;]+)').firstMatch(cookies);
      String token = match?.group(1) ?? "";
      
      if (token.isEmpty) {
        // Fallback: Check if it's in a different cookie format or redirected
        debugPrint("[LC] ⚠️ CSRF not in Set-Cookie, attempt fallback check...");
        token = "dummy_csrf_token"; 
      }
      
      return token;
    } catch (e) {
      debugPrint("[LC] CSRF fetch error: $e");
      return "dummy_csrf_token";
    }
  }

  Future<LeetcodeStats> _fetchGraphQL(String username) async {
    final csrf = await _fetchCsrfToken(); 
    const url = "https://leetcode.com/graphql";
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Referer": "https://leetcode.com/",
          "Origin": "https://leetcode.com",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Cookie": "csrftoken=$csrf",
          "x-csrftoken": csrf,
        },
        body: jsonEncode({
          "query": _gqlQuery,
          "variables": {"username": username},
        }),
      ).timeout(_singleSourceTimeout);

      if (response.statusCode == 400) {
        debugPrint("[LC] 400 Bad Request: ${response.body}");
        throw Exception("Invalid request (400). This usually means a CSRF mismatch or structure error.");
      }
      if (response.statusCode == 429) {
        debugPrint("[LC] 429 Too Many Requests: ${response.body}");
        throw Exception("Too many requests (429). Please wait a moment.");
      }
      if (response.statusCode != 200) {
        debugPrint("[LC] ${response.statusCode} Server Error: ${response.body}");
        throw Exception("Server error (${response.statusCode})");
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (json["errors"] != null) {
        final errorMsg = json["errors"][0]["message"]?.toString() ?? "Unknown error";
        if (errorMsg.contains("User not found") || errorMsg.contains("does not exist")) {
          throw UserNotFoundException("User '$username' not found on LeetCode. Check spelling/case.");
        }
        throw Exception("LeetCode error: $errorMsg");
      }

      return _parseGraphQLResponse(json, username);
    } on TimeoutException {
      throw Exception("Connection timeout. Please check your internet.");
    } catch (e) {
      if (e is UserNotFoundException) rethrow;
      debugPrint("[LC] GQL Error details: $e");
      throw Exception("Failed to sync LeetCode: ${e.toString().replaceAll("Exception: ", "")}");
    }
  }

  LeetcodeStats _parseGraphQLResponse(Map<String, dynamic> json, String username) {
    final data = json["data"] as Map<String, dynamic>?;
    final matchedUser = data?["matchedUser"] as Map<String, dynamic>?;

    if (matchedUser == null) {
      throw UserNotFoundException("User '$username' not found.");
    }

    final profile = matchedUser["profile"] as Map<String, dynamic>? ?? {};
    final statsData = matchedUser["submitStatsGlobal"];
    final submitStats = (statsData?["acSubmissionNum"] as List?) ?? [];
    final contestRanking = data?["userContestRanking"] as Map<String, dynamic>?;

    // ── Solve counts
    int total = 0, easy = 0, medium = 0, hard = 0;
    for (final stat in submitStats) {
      final s = stat as Map<String, dynamic>;
      final diff = s["difficulty"]?.toString();
      final count = int.tryParse(s["count"]?.toString() ?? '0') ?? 0;
      switch (diff) {
        case "All":    total  = count; break;
        case "Easy":   easy   = count; break;
        case "Medium": medium = count; break;
        case "Hard":   hard   = count; break;
      }
    }

    // ── Submission calendar
    final Map<DateTime, int> calendar = {};
    final rawCal = matchedUser["submissionCalendar"];
    if (rawCal != null) {
      try {
        final Map<String, dynamic> calMap = rawCal is String 
            ? jsonDecode(rawCal) as Map<String, dynamic> 
            : rawCal as Map<String, dynamic>;
        
        calMap.forEach((key, value) {
          final ts = int.tryParse(key);
          if (ts != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000).toLocal();
            calendar[DateTime(date.year, date.month, date.day)] = (value as num).toInt();
          }
        });
      } catch (e) {
        debugPrint("[LC] Calendar parse error: $e");
      }
    }

    // ── Contest history
    final List<LeetCodeContestHistory> contestHistory = [];
    final historyList = data?["userContestRankingHistory"] as List?;
    if (historyList != null) {
      for (final item in historyList) {
        try {
          final i = item as Map<String, dynamic>;
          if (i["attended"] != true) continue;
          
          final contest = i["contest"] as Map<String, dynamic>?;
          if (contest == null) continue;

          contestHistory.add(LeetCodeContestHistory(
            contestTitle: contest["title"]?.toString() ?? "Contest",
            rating: (i["rating"] as num? ?? 0).toDouble(),
            rank: (i["rank"] as num? ?? 0).toInt(),
            solved: (i["problemsSolved"] as num?)?.toInt(),
            totalProblems: (i["totalProblems"] as num?)?.toInt(),
            date: DateTime.fromMillisecondsSinceEpoch((contest["startTime"] as num? ?? 0).toInt() * 1000),
          ));
        } catch (_) {}
      }
    }

    // ── Recent submissions
    final List<Submission> recentSubmissions = [];
    final recentList = data?["recentSubmissionList"] as List?;
    if (recentList != null) {
      for (final item in recentList) {
        try {
          final i = item as Map<String, dynamic>;
          recentSubmissions.add(Submission(
            title: i["title"]?.toString() ?? "Problem",
            titleSlug: i["titleSlug"]?.toString() ?? "",
            status: i["statusDisplay"]?.toString() ?? "Completed",
            lang: i["lang"]?.toString() ?? "",
            timestamp: DateTime.fromMillisecondsSinceEpoch((_toInt(i["timestamp"])) * 1000),
          ));
        } catch (_) {}
      }
    }

    // ── Badges
    final List<LeetCodeBadge> badges = [];
    final badgesList = matchedUser["badges"] as List?;
    if (badgesList != null) {
      for (final b in badgesList) {
        final badge = b as Map<String, dynamic>;
        var icon = badge["icon"]?.toString() ?? "";
        if (icon.isNotEmpty && !icon.startsWith("http")) {
          icon = "https://leetcode.com$icon";
        }
        badges.add(LeetCodeBadge(
          name: badge["name"]?.toString() ?? "",
          icon: icon,
          description: badge["hoverText"]?.toString(),
          earnedDate: badge["creationDate"]?.toString(),
        ));
      }
    }

    // ── Tag stats
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
              tagStats[name] = (tagStats[name] ?? 0) + _toInt(i["problemsSolved"]);
            }
          }
        }
      }
    }

    final double rating = _toDouble(contestRanking?["rating"]);
    double? highestRating;
    if (contestHistory.isNotEmpty) {
      highestRating =
          contestHistory.map((h) => h.rating).reduce((a, b) => a > b ? a : b);
    }

    final streaks = _calculateStreaks(calendar);

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

      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timeMs));
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
      await prefs.setString('$_cacheKeyPrefix$username', jsonEncode(stats.toJson()));
      await prefs.setInt('$_cacheTimePrefix$username', DateTime.now().millisecondsSinceEpoch);
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
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, int> _calculateStreaks(Map<DateTime, int> calendar) {
    if (calendar.isEmpty) return {'streak': 0, 'longestStreak': 0};

    final sorted = calendar.keys
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList()
      ..sort();

    int maxStreak = 0;
    int tempStreak = 0;
    if (sorted.isNotEmpty) {
      maxStreak = 1;
      tempStreak = 1;
      for (var i = 1; i < sorted.length; i++) {
        final diff = sorted[i].difference(sorted[i - 1]).inDays;
        if (diff == 1) {
          tempStreak++;
          if (tempStreak > maxStreak) maxStreak = tempStreak;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yest = todayDate.subtract(const Duration(days: 1));

    int current = 0;
    if (calendar.containsKey(todayDate) || calendar.containsKey(yest)) {
      current = 1;
      var check = calendar.containsKey(todayDate) ? todayDate : yest;
      while (true) {
        check = check.subtract(const Duration(days: 1));
        if (calendar.containsKey(DateTime(check.year, check.month, check.day))) {
          current++;
        } else {
          break;
        }
      }
    }

    return {'streak': current, 'longestStreak': maxStreak};
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}