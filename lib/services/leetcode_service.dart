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
          submitStats {
            acSubmissionNum {
              difficulty
              count
            }
          }
        }
        userContestRanking(username: \$username) {
          rating
        }
      }
    """;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Referer": "https://leetcode.com",
          "Origin": "https://leetcode.com"
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        if (!kIsWeb && url.contains("leetcode.com")) {
          return _fetchViaProxy(username, query);
        }
        throw Exception("Server Error: ${response.statusCode}");
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse["errors"] != null) {
        throw Exception(jsonResponse["errors"][0]["message"]);
      }

      return _parseResponse(jsonResponse, username);
    } catch (e) {
      if (kIsWeb) {
        return _fetchViaProxy(username, query);
      }
      rethrow;
    }
  }

  Future<LeetcodeStats> _fetchViaProxy(String username, String query) async {
    final response = await http.post(
      Uri.parse("https://alfa-leetcode-api.onrender.com/graphql"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {'username': username},
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception("All connection attempts failed.");
    }

    return _parseResponse(jsonDecode(response.body), username);
  }

  LeetcodeStats _parseResponse(Map<String, dynamic> jsonResponse, String username) {
    final data = jsonResponse["data"];
    final matchedUser = data["matchedUser"];

    if (matchedUser == null) {
      throw Exception("User '$username' not found");
    }

    final profile = matchedUser["profile"];
    final submitStats = matchedUser["submitStats"]["acSubmissionNum"];
    final contestRanking = data["userContestRanking"];
    final calendarString = matchedUser["submissionCalendar"] as String;

    // Parse submission calendar
    final Map<DateTime, int> submissionCalendar = {};
    if (calendarString.isNotEmpty) {
      final Map<String, dynamic> rawCalendar = jsonDecode(calendarString);
      rawCalendar.forEach((key, value) {
        final timestamp = int.parse(key);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        // Normalize to date only (midnight)
        final normalizedDate = DateTime(date.year, date.month, date.day);
        submissionCalendar[normalizedDate] = value as int;
      });
    }

    int total = 0, easy = 0, medium = 0, hard = 0;

    for (var stat in submitStats) {
      if (stat["difficulty"] == "All") total = stat["count"];
      if (stat["difficulty"] == "Easy") easy = stat["count"];
      if (stat["difficulty"] == "Medium") medium = stat["count"];
      if (stat["difficulty"] == "Hard") hard = stat["count"];
    }

    double rating = 0;
    if (contestRanking != null && contestRanking["rating"] != null) {
      rating = (contestRanking["rating"] as num).toDouble();
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
    );
  }
}