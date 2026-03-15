import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/leetcode_stats.dart';

class LeetcodeService {
  Future<LeetcodeStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("Username cannot be empty");
    }

    final String url = kIsWeb
        ? "https://corsproxy.io/?https://leetcode.com/graphql"
        : "https://leetcode.com/graphql";

    final query = """
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

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Referer": "https://leetcode.com",
          "Origin": "https://leetcode.com",
          if (!kIsWeb) "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username},
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse["errors"] != null) {
          debugPrint("LeetCode API Error: ${jsonResponse["errors"][0]["message"]}");
          throw Exception(jsonResponse["errors"][0]["message"]);
        }
        debugPrint("LeetCode API: Successfully fetched data for $username");
        return _parseResponse(jsonResponse, username);
      } else {
        debugPrint("LeetCode API: Failed with status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("LeetCode API: Request failed: $e");
      if (e is Exception && e.toString().contains("User '$username' not found")) {
        rethrow;
      }
    }

    debugPrint("LeetCode API: Attempting fetch via proxy for $username");
    return _fetchViaProxy(username, query);
  }

  Future<LeetcodeStats> _fetchViaProxy(String username, String query) async {
    final List<String> proxies = [
      "https://leetcode-api-f6df.onrender.com/graphql",
      "https://alfa-leetcode-api.onrender.com/graphql",
    ];

    Object? lastError;

    for (final proxy in proxies) {
      try {
        final response = await http.post(
          Uri.parse(proxy),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'variables': {'username': username},
          }),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body["errors"] != null && body["data"] == null) {
            throw Exception(body["errors"][0]["message"]);
          }
          return _parseResponse(body, username);
        }
      } catch (e) {
        lastError = e;
      }
    }

    for (final proxy in proxies) {
      try {
        final response = await http.post(
          Uri.parse(proxy),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'variables': {'username': username},
          }),
        ).timeout(const Duration(seconds: 70));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          return _parseResponse(body, username);
        }
      } catch (e) {
        lastError = e;
      }
    }

    // REST fallback
    try {
      debugPrint("LeetCode API: Using full REST fallback for $username");

      // Fetch all 5 endpoints in parallel
      final profileFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/userProfile/$username"));
      final calendarFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/$username/calendar"));
      final contestFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/$username/contest"));
      final contestHistoryFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/$username/contest/history"));
      final recentFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/$username/submission?limit=15"));

      final results = await Future.wait([profileFuture, calendarFuture, contestFuture, contestHistoryFuture, recentFuture]);

      if (results[0].statusCode == 200) {
        final profileData = jsonDecode(results[0].body);
        final calendarBody = results[1].statusCode == 200 ? jsonDecode(results[1].body) : null;
        final contestBody = results[2].statusCode == 200 ? jsonDecode(results[2].body) : null;
        final contestHistoryBody = results[3].statusCode == 200 ? jsonDecode(results[3].body) : null;
        final recentBody = results[4].statusCode == 200 ? jsonDecode(results[4].body) : null;
        debugPrint("LeetCode API: /submission status=${results[4].statusCode}");

        debugPrint("LeetCode API: /contest status=${results[2].statusCode}");
        debugPrint("LeetCode API: /contest/history status=${results[3].statusCode}");
        if (contestHistoryBody != null) {
          debugPrint("LeetCode API: /contest/history keys=${contestHistoryBody.keys?.toList()}");
        }

        final Map<DateTime, int> cal = {};
        if (calendarBody != null && calendarBody["submissionCalendar"] != null) {
          final calRaw = calendarBody["submissionCalendar"];
          final Map<String, dynamic> calMap = calRaw is String ? jsonDecode(calRaw) : calRaw;
          calMap.forEach((key, val) {
            final ts = int.tryParse(key);
            if (ts != null) {
              final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
              cal[DateTime(d.year, d.month, d.day)] = val;
            }
          });
        }

        // Parse contest history — prefer dedicated /contest/history endpoint,
        // fall back to history inside /contest summary body
        final List<LeetCodeContestHistory> history = [];

        // /contest/history returns either a List directly or {contestHistory: [...]}
        List? rawHistory;
        if (contestHistoryBody is List) {
          rawHistory = contestHistoryBody;
        } else if (contestHistoryBody is Map) {
          rawHistory = contestHistoryBody["contestHistory"] ??
              contestHistoryBody["contestRankingHistory"] ??
              contestHistoryBody["userContestRankingHistory"] ??
              contestHistoryBody["data"];
        }

        // Fallback to /contest body if /contest/history gave nothing
        rawHistory ??= contestBody?["contestRankingHistory"] ??
            contestBody?["userContestRankingHistory"];

        debugPrint("LeetCode API: raw contest history entries: ${rawHistory?.length ?? 0}");

        if (rawHistory != null ) {
          for (var item in rawHistory) {
            try {
              final rating = item["rating"] ?? item["contestRating"];
              final contest = item["contest"] ?? item;
              final startTime = contest["startTime"] ??
                  contest["start_time"] ??
                  item["startTime"];
              debugPrint("  entry: rating=$rating startTime=$startTime title=${contest['title'] ?? item['contestTitle']}");
              if (rating != null && (rating as num) > 0 && startTime != null) {
                history.add(LeetCodeContestHistory(
                  contestTitle: contest["title"] ?? item["contestTitle"] ?? 'Contest',
                  rating: (rating).toDouble(),
                  rank: item["rank"] ?? item["ranking"] ?? item["contestRank"] ?? 0,
                  date: DateTime.fromMillisecondsSinceEpoch(
                      (startTime as int) * 1000),
                ));
              }
            } catch (e) {
              debugPrint("LeetCode API: Skipping contest entry: $e");
            }
          }
        }
        debugPrint("LeetCode API: REST fallback parsed ${history.length} contest entries");

        final contestRating = (contestBody?["contestRating"] != null &&
                contestBody!["contestRating"] > 0)
            ? (contestBody["contestRating"] as num).toDouble()
            : null;

        double? highestRating;
        if (history.isNotEmpty) {
          highestRating = history.map((e) => e.rating).reduce((a, b) => a > b ? a : b);
        } else {
          highestRating = (contestBody?["contestHighestRating"] as num?)?.toDouble();
        }

        // ── Streak from calendar ─────────────────────────────────────────
        int currentStreak = 0;
        int longestStreak = 0;
        if (cal.isNotEmpty) {
          final sorted = cal.keys.toList()..sort();
          int temp = 1;
          for (int i = 1; i < sorted.length; i++) {
            if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
              temp++;
              if (temp > longestStreak) longestStreak = temp;
            } else {
              longestStreak = longestStreak > temp ? longestStreak : temp;
              temp = 1;
            }
          }
          longestStreak = longestStreak > temp ? longestStreak : temp;
          final today = DateTime.now();
          DateTime check = DateTime(today.year, today.month, today.day);
          if (!cal.containsKey(check)) {
            check = check.subtract(const Duration(days: 1));
          }
          while (cal.containsKey(check)) {
            currentStreak++;
            check = check.subtract(const Duration(days: 1));
          }
        }

        // ── Recent submissions from /submission endpoint ──────────────────
        final List<RecentSubmission> recentSubmissions = [];
        final rawSubs = recentBody is List ? recentBody
            : (recentBody is Map ? (recentBody["submission"] ?? recentBody["submissions"] ?? recentBody["recentSubmissionList"]) : null);
        if (rawSubs is List) {
          debugPrint("LeetCode API: REST recent submissions: ${rawSubs.length}");
          for (var item in rawSubs) {
            try {
              final ts = item["timestamp"] ?? item["time"];
              final timestamp = ts is String ? int.tryParse(ts) : (ts as int?);
              recentSubmissions.add(RecentSubmission(
                title: item["title"] ?? item["problem"] ?? "",
                titleSlug: item["titleSlug"] ?? item["title_slug"] ?? "",
                difficulty: item["difficulty"] ?? "",
                status: item["statusDisplay"] ?? item["status"] ?? item["verdict"] ?? "Unknown",
                timestamp: timestamp != null
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
                    : DateTime.now(),
              ));
            } catch (e) {
              debugPrint("LeetCode API: Skipping submission entry: $e");
            }
          }
        }

        return LeetcodeStats(
          totalSolved: profileData["totalSolved"] ?? 0,
          easy: profileData["easySolved"] ?? 0,
          medium: profileData["mediumSolved"] ?? 0,
          hard: profileData["hardSolved"] ?? 0,
          avatar: profileData["avatar"] ?? "",
          ranking: profileData["ranking"] ?? 0,
          rating: contestRating ?? 0,
          submissionCalendar: cal,
          activeDays: cal.length,
          streak: currentStreak,
          longestStreak: longestStreak,
          contestRating: contestRating,
          highestRating: highestRating,
          globalRanking: contestBody?["contestGlobalRanking"],
          topPercentage: contestBody?["contestTopPercentage"] != null
              ? (contestBody!["contestTopPercentage"] as num).toDouble()
              : null,
          totalContests: contestBody?["contestAttend"],
          contestHistory: history,
          recentSubmissions: recentSubmissions,
        );
      }
    } catch (e) {
      debugPrint("LeetCode API: REST fallback failed: $e");
    }

    if (lastError.toString().contains("SocketException") ||
        lastError.toString().contains("Failed host lookup") ||
        lastError.toString().contains("TimeoutException") ||
        lastError.toString().contains("Failed to fetch")) {
      throw Exception("TIMEOUT_ERROR");
    }

    throw lastError ?? Exception("Connectivity issue. Please check your internet connection.");
  }

  LeetcodeStats _parseResponse(Map<String, dynamic> jsonResponse, String username) {
    final data = jsonResponse.containsKey("data") ? jsonResponse["data"] : jsonResponse;
    final matchedUser = data["matchedUser"] ?? data;

    if (matchedUser == null || (matchedUser is Map && matchedUser.isEmpty)) {
      throw Exception("User '$username' not found");
    }

    final profile = matchedUser["profile"] ?? {};
    final submissionStatsData = matchedUser["submitStats"] ?? matchedUser["submitStatsGlobal"];

    if (submissionStatsData == null) {
      debugPrint("LeetCode API Warning: Could not find submission stats in response");
    }

    final submitStats = submissionStatsData != null
        ? (submissionStatsData["acSubmissionNum"] as List?)
        : null;

    final contestRanking = data["userContestRanking"] ??
        (data["contestRating"] != null ? data : null);

    final calendarRaw = matchedUser["submissionCalendar"] ?? data["submissionCalendar"];

    final Map<DateTime, int> submissionCalendar = {};
    if (calendarRaw != null && calendarRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> rawCalendar = calendarRaw is String
            ? jsonDecode(calendarRaw)
            : calendarRaw as Map<String, dynamic>;

        rawCalendar.forEach((key, value) {
          final timestamp = int.tryParse(key);
          if (timestamp != null) {
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
            final localDate = DateTime(date.year, date.month, date.day);
            submissionCalendar[localDate] = value as int;
          }
        });
        debugPrint("LeetCode API: Parsed ${submissionCalendar.length} active days");
      } catch (e) {
        debugPrint("LeetCode API Error: Failed to parse submission calendar: $e");
      }
    }

    int total = 0, easy = 0, medium = 0, hard = 0;
    if (submitStats != null) {
      for (var stat in submitStats) {
        if (stat["difficulty"] == "All") total = stat["count"];
        if (stat["difficulty"] == "Easy") easy = stat["count"];
        if (stat["difficulty"] == "Medium") medium = stat["count"];
        if (stat["difficulty"] == "Hard") hard = stat["count"];
      }
    }

    final contestHistoryData =
        (data["userContestRankingHistory"] ?? data["contestRankingHistory"]) as List?;
    final recentSubmissionsData =
        (data["recentSubmissionList"] ?? data["recentSubmissions"]) as List?;

    // ── Parse contest history (attended filter removed) ──────────────────
    final List<LeetCodeContestHistory> contestHistory = [];
    if (contestHistoryData != null) {
      debugPrint("=== CONTEST DEBUG: ${contestHistoryData.length} raw entries ===");
      for (int i = 0; i < contestHistoryData.length; i++) {
        final item = contestHistoryData[i];
        debugPrint("  [$i] attended=${item['attended']} rating=${item['rating']} title=${item['contest']?['title']}");
        try {
          final rating = item["rating"];
          final startTime = item["contest"]?["startTime"];
          if (rating != null && (rating as num) > 0 && startTime != null) {
            final parsedDate = DateTime.fromMillisecondsSinceEpoch(
                (startTime as int) * 1000);
            debugPrint("  -> adding: rating=${rating .toStringAsFixed(1)} date=$parsedDate title=${item['contest']['title']}");
            contestHistory.add(LeetCodeContestHistory(
              contestTitle: item["contest"]["title"] ?? 'Contest',
              rating: (rating).toDouble(),
              rank: item["rank"] ?? 0,
              date: parsedDate,
            ));
          }
        } catch (e) {
          debugPrint("LeetCode API: Skipping malformed contest entry: $e");
        }
      }
      debugPrint("=== CONTEST DEBUG: parsed ${contestHistory.length} entries ===");
    } else {
      debugPrint("=== CONTEST DEBUG: contestHistoryData is NULL ===");
    }
    // ──────────────────────────────────────────────────────────────────────
    final List<RecentSubmission> recentSubmissions = [];
    if (recentSubmissionsData != null) {
      for (var item in recentSubmissionsData) {
        recentSubmissions.add(RecentSubmission(
          title: item["title"],
          titleSlug: item["titleSlug"],
          difficulty: "",
          status: item["statusDisplay"],
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              int.parse(item["timestamp"]) * 1000),
        ));
      }
    }

    final List<LeetCodeBadge> badges = [];
    final badgesData = matchedUser["badges"] as List?;
    if (badgesData != null) {
      for (var badge in badgesData) {
        String icon = badge["icon"] ?? "";
        if (icon.isNotEmpty && !icon.startsWith("http")) {
          icon = "https://leetcode.com$icon";
        }
        badges.add(LeetCodeBadge(
          name: badge["name"] ?? "",
          icon: icon,
          description: badge["hoverText"],
          earnedDate: badge["creationDate"],
        ));
      }
    }

    // ── Parse Skill Tags ───────────────────────────────────────────────
    final Map<String, int> tagStats = {};
    final tagData = data["tagProblemCounts"];
    if (tagData != null) {
      for (var level in ["fundamental", "intermediate", "advanced"]) {
        final List? categories = tagData[level];
        if (categories != null) {
          for (var item in categories) {
            final name = item["tagName"] ?? "";
            final count = item["problemsSolved"] ?? 0;
            if (name.isNotEmpty) {
              tagStats[name] = (tagStats[name] ?? 0) + (count as int);
            }
          }
        }
      }
    }

    // Streak calculation
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    final int activeDays = submissionCalendar.length;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final sortedDates = submissionCalendar.keys.toList()..sort();

    if (sortedDates.isNotEmpty) {
      for (int i = 0; i < sortedDates.length; i++) {
        if (i > 0) {
          final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
          if (diff == 1) {
            tempStreak++;
          } else if (diff > 1) {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        } else {
          tempStreak = 1;
        }
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;

      DateTime checkDate = normalizedToday;
      if (!submissionCalendar.containsKey(checkDate)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      while (submissionCalendar.containsKey(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    double rating = 0;
    if (contestRanking != null) {
      final r = contestRanking["rating"] ?? contestRanking["contestRating"];
      if (r != null) rating = (r as num).toDouble();
    }

    double? highestRating;
    if (contestHistory.isNotEmpty) {
      highestRating = contestHistory
          .map((e) => e.rating)
          .reduce((a, b) => a > b ? a : b);
    }

    return LeetcodeStats(
      totalSolved: total,
      easy: easy,
      medium: medium,
      hard: hard,
      avatar: profile["userAvatar"] ?? "",
      ranking: profile["ranking"] ?? 0,
      rating: rating,
      submissionCalendar: submissionCalendar,
      streak: currentStreak,
      longestStreak: longestStreak,
      activeDays: activeDays,
      contestRating: rating > 0 ? rating : null,
      highestRating: highestRating,
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