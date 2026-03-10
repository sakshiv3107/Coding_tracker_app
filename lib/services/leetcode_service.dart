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
    
    // First pass: try each proxy once with a moderate timeout (25s)
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

    // Second pass: retry with a long timeout (60s) specifically to allow for Render to spin up
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

    // Critical Fallback: Use individual REST endpoints of the primary proxy 
    // This fetches data in separate requests to ensure better reliability
    try {
      debugPrint("LeetCode API: Using full REST fallback for $username");
      
      final profileFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/userProfile/$username"));
      final calendarFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/$username/calendar"));
      final contestFuture = http.get(Uri.parse("https://alfa-leetcode-api.onrender.com/$username/contest"));
      
      final results = await Future.wait([profileFuture, calendarFuture, contestFuture]);
      
      if (results[0].statusCode == 200) {
        final profileData = jsonDecode(results[0].body);
        final calendarBody = results[1].statusCode == 200 ? jsonDecode(results[1].body) : null;
        final contestBody = results[2].statusCode == 200 ? jsonDecode(results[2].body) : null;
        
        // Use normalized names from REST responses
        final stats = LeetcodeStats(
          totalSolved: profileData["totalSolved"] ?? 0,
          easy: profileData["easySolved"] ?? 0,
          medium: profileData["mediumSolved"] ?? 0,
          hard: profileData["hardSolved"] ?? 0,
          avatar: profileData["avatar"] ?? "",
          ranking: profileData["ranking"] ?? 0,
          rating: (contestBody?["contestRating"] ?? 0.0).toDouble(),
          submissionCalendar: {}, // Will fill below
          activeDays: 0,
          contestRating: (contestBody?["contestRating"] != null && contestBody!["contestRating"] > 0) 
              ? (contestBody["contestRating"] as num).toDouble() : null,
          highestRating: (contestBody?["contestHighestRating"] as num?)?.toDouble(),
          globalRanking: contestBody?["contestGlobalRanking"],
          totalContests: contestBody?["contestAttend"],
        );

        // Parse calendar from REST response
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
        
        // Parse contest history from REST response
        final List<LeetCodeContestHistory> history = [];
        if (contestBody != null && contestBody["contestRankingHistory"] != null) {
          for (var item in contestBody["contestRankingHistory"]) {
            if (item["attended"] == true) {
              history.add(LeetCodeContestHistory(
                contestTitle: item["contest"]["title"],
                rating: (item["rating"] as num).toDouble(),
                rank: item["rank"] ?? 0,
                date: DateTime.fromMillisecondsSinceEpoch((item["contest"]["startTime"] as int) * 1000),
              ));
            }
          }
        }

        return LeetcodeStats(
          totalSolved: stats.totalSolved,
          easy: stats.easy,
          medium: stats.medium,
          hard: stats.hard,
          avatar: stats.avatar,
          ranking: stats.ranking,
          rating: stats.rating,
          submissionCalendar: cal,
          activeDays: cal.length,
          contestRating: stats.contestRating,
          highestRating: stats.highestRating,
          globalRanking: stats.globalRanking,
          totalContests: stats.totalContests,
          contestHistory: history,
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
    // Some proxies return data directly at root, others nest under "data"
    final data = jsonResponse.containsKey("data") ? jsonResponse["data"] : jsonResponse;
    
    // Check for matchedUser in various places
    final matchedUser = data["matchedUser"] ?? data;

    if (matchedUser == null || (matchedUser is Map && matchedUser.isEmpty)) {
      throw Exception("User '$username' not found");
    }

    final profile = matchedUser["profile"] ?? {};
    final submissionStatsData = matchedUser["submitStats"] ?? matchedUser["submitStatsGlobal"];
    
    if (submissionStatsData == null) {
      debugPrint("LeetCode API Warning: Could not find submission stats in response");
    }
    
    final submitStats = submissionStatsData != null ? (submissionStatsData["acSubmissionNum"] as List?) : null;
    
    // Some proxies return contest ranking at root or as separate fields
    final contestRanking = data["userContestRanking"] ?? 
        (data["contestRating"] != null ? data : null);
    
    final calendarRaw = matchedUser["submissionCalendar"] ?? data["submissionCalendar"];

    // Parse submission calendar
    final Map<DateTime, int> submissionCalendar = {};
    if (calendarRaw != null && calendarRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> rawCalendar = 
            calendarRaw is String ? jsonDecode(calendarRaw) : calendarRaw as Map<String, dynamic>;
        
        rawCalendar.forEach((key, value) {
          final timestamp = int.tryParse(key);
          if (timestamp != null) {
            // Use UTC for consistent date normalization
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
            // Normalize to date only (midnight) in local time for UI display
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

    final contestHistoryData = (data["userContestRankingHistory"] ?? data["contestRankingHistory"]) as List?;
    final recentSubmissionsData = (data["recentSubmissionList"] ?? data["recentSubmissions"]) as List?;

    final List<LeetCodeContestHistory> contestHistory = [];
    if (contestHistoryData != null) {
      for (var item in contestHistoryData) {
        if (item["attended"] == true) {
          contestHistory.add(LeetCodeContestHistory(
            contestTitle: item["contest"]["title"],
            rating: (item["rating"] as num).toDouble(),
            rank: item["rank"] ?? 0,
            date: DateTime.fromMillisecondsSinceEpoch((item["contest"]["startTime"] as int) * 1000),
          ));
        }
      }
    }

    final List<RecentSubmission> recentSubmissions = [];
    if (recentSubmissionsData != null) {
      for (var item in recentSubmissionsData) {
        recentSubmissions.add(RecentSubmission(
          title: item["title"],
          titleSlug: item["titleSlug"],
          difficulty: "", 
          status: item["statusDisplay"],
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(item["timestamp"]) * 1000),
        ));
      }
    }

    // Calculate Streak
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    int activeDays = submissionCalendar.length;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // Sort dates to calculate streak
    final sortedDates = submissionCalendar.keys.toList()..sort();
    
    if (sortedDates.isNotEmpty) {
      // Calculate longest streak
      for (int i = 0; i < sortedDates.length; i++) {
        if (i > 0) {
          final diff = sortedDates[i].difference(sortedDates[i-1]).inDays;
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

      // Calculate current streak
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
      if (r != null) {
        rating = (r as num).toDouble();
      }
    }

    double? highestRating;
    if (contestHistory.isNotEmpty) {
      highestRating = contestHistory.map((e) => e.rating).reduce((a, b) => a > b ? a : b);
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
      totalContests: contestRanking?["attendedContestsCount"],
      contestHistory: contestHistory,
      recentSubmissions: recentSubmissions,
    );
  }
}