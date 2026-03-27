import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/platform_stats.dart';
import '../models/submission.dart';
import '../core/exceptions.dart';

class CodeforcesService {
  Future<PlatformStats> fetchData(String username) async {
    if (username.trim().isEmpty) throw ValidationException("Codeforces username required");

    String infoUrlStr = "https://codeforces.com/api/user.info?handles=$username";
    String statusUrlStr = "https://codeforces.com/api/user.status?handle=$username";

    if (kIsWeb) {
      infoUrlStr = "https://corsproxy.io/?${Uri.encodeComponent(infoUrlStr)}";
      statusUrlStr = "https://corsproxy.io/?${Uri.encodeComponent(statusUrlStr)}";
    }

    final infoUrl = Uri.parse(infoUrlStr);
    final statusUrl = Uri.parse(statusUrlStr);
    
    try {
      final infoResponse = await http.get(infoUrl).timeout(const Duration(seconds: 20));
      
      if (infoResponse.statusCode == 404 || infoResponse.statusCode == 400) {
        throw UserNotFoundException("User '$username' not found on Codeforces");
      }

      final infoJson = jsonDecode(infoResponse.body);
      if (infoJson["status"] == "FAILED") {
        final comment = infoJson["comment"]?.toString() ?? "";
        if (comment.contains("not found")) {
          throw UserNotFoundException("User '$username' not found on Codeforces");
        }
        throw Exception(comment);
      }

      if (infoJson["status"] == "OK") {
        final user = infoJson["result"][0];
        
        // Fetch status for solved count and recent submissions
        final statusResponse = await http.get(statusUrl).timeout(const Duration(seconds: 20));
        int solvedCount = 0;
        List<Submission> recentSubmissions = [];
        
        if (statusResponse.statusCode == 200) {
          final statusJson = jsonDecode(statusResponse.body);
          if (statusJson["status"] == "OK") {
            final submissions = statusJson["result"] as List;
            
            // Calculate total solved (unique problems with OK verdict)
            final solvedSet = submissions
                .where((s) => s["verdict"] == "OK")
                .map((s) => "${s["problem"]["contestId"] ?? 0}_${s["problem"]["index"] ?? 'X'}")
                .toSet();
            solvedCount = solvedSet.length;

            // Extract top 10 most recent submissions
            recentSubmissions = submissions.take(10).map((s) {
              final prob = (s["problem"] ?? {}) as Map<String, dynamic>;
              return Submission(
                title: prob["name"]?.toString() ?? "Problem",
                status: s["verdict"]?.toString().replaceAll("_", " ") ?? "Unknown",
                lang: s["programmingLanguage"]?.toString(),
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (s["creationTimeSeconds"] as int? ?? 0) * 1000,
                ),
              );
            }).toList();
          }
        }

        return PlatformStats(
          platform: "Codeforces",
          username: username,
          avatarUrl: user["avatar"],
          totalSolved: solvedCount,
          rating: user["rating"],
          maxRating: user["maxRating"],
          ranking: user["rank"],
          recentSubmissions: recentSubmissions,
          extraMetrics: {
            "contribution": user["contribution"] ?? 0,
            "friendOfCount": user["friendOfCount"] ?? 0,
            "organization": user["organization"] ?? "N/A",
          },
        );
      }
      throw Exception("Codeforces: Unknown error");
    } on UserNotFoundException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) rethrow;
      throw Exception("Codeforces connectivity error: $e");
    }
  }
}
