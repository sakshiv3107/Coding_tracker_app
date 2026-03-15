import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/platform_stats.dart';

class HackerRankService {
  Future<PlatformStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("HackerRank username is empty");
    }

    // This is an unofficial endpoint, but often works for public profile summary
    final url = "https://www.hackerrank.com/rest/contests/master/users/$username/profile";

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final model = data["model"];
        
        if (model == null) {
          throw Exception("User not found on HackerRank");
        }

        // HackerRank solves are usually listed in badges or specialized sections
        // For a simple aggregate, we can sum problems solved in different tracks if available
        // But the profile model usually has basic info.
        
        return PlatformStats(
          platform: "HackerRank",
          username: username,
          totalSolved: model["solved_problems_count"] ?? 0,
          rank: model["rank"]?.toString(),
          avatarUrl: model["avatar"],
          extraMetrics: {
            "country": model["country"],
            "personal_best_rank": model["personal_best_rank"],
            "total_badges": model["badges_count"] ?? 0,
          },
        );
      } else {
        throw Exception("Failed to fetch HackerRank data (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("HackerRank Error: $e");
    }
  }
}
