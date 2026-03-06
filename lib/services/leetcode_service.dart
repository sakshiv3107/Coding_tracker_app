import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leetcode_stats.dart';

class LeetcodeService {
  Future<LeetcodeStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("Username cannot be empty");
    }

    try {
      // Use LeetCode REST API via Vercel wrapper
      final url = Uri.parse(
        "https://leetcode-api-faisalshohag.vercel.app/user/$username",
      );

      final response = await http
          .get(
            url,
            headers: {
              "Content-Type": "application/json",
              "User-Agent":
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw Exception(
          "LeetCode user '$username' not found. Please check the username.",
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to fetch data from LeetCode (Status: ${response.statusCode})",
        );
      }

      final responseData = jsonDecode(response.body);

      // Check if the request was successful
      if (responseData["status"] == "error" || responseData["data"] == null) {
        throw Exception(
          "LeetCode Error: Unable to fetch user data. Please verify the username.",
        );
      }

      final data = responseData["data"];

      // Extract submission stats
      int total = data["totalSolved"] ?? 0;
      int easy = data["easySolved"] ?? 0;
      int medium = data["mediumSolved"] ?? 0;
      int hard = data["hardSolved"] ?? 0;

      // Validate that we got valid data
      if (total == 0 && easy == 0 && medium == 0 && hard == 0) {
        throw Exception(
          "No submission data available. User profile may be private or has no submissions.",
        );
      }

      return LeetcodeStats(
        totalSolved: total,
        easy: easy,
        medium: medium,
        hard: hard,
      );
    } on TimeoutException {
      throw Exception(
        "Request timeout. LeetCode server is not responding. Please try again.",
      );
    } on FormatException catch (e) {
      throw Exception("Invalid response format from LeetCode: $e");
    } catch (e) {
      throw Exception("Error fetching LeetCode stats: $e");
    }
  }
}
