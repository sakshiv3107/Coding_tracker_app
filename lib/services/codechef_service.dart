import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/platform_stats.dart';
import '../models/submission.dart';
import '../core/exceptions.dart';

class CodeChefService {
  Future<PlatformStats> fetchData(String username) async {
    if (username.trim().isEmpty) throw ValidationException("CodeChef username required");

    // Community API proxy for CodeChef
    String urlStr = "https://codechefapi.vercel.app/handle/$username";
    
    if (kIsWeb) {
      urlStr = "https://corsproxy.io/?${Uri.encodeComponent(urlStr)}";
    }
    
    final url = Uri.parse(urlStr);
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 404) {
        throw UserNotFoundException("User '$username' not found on CodeChef");
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Some APIs return 200 but with an error field
        if (json["status"] == "Failed" || json["success"] == false) {
          throw UserNotFoundException("User '$username' not found on CodeChef");
        }

        if (json["name"] != null || json["success"] == true) {
          final List<Submission> submissions = [];
          final rawSubs = json['recentSubmissions'] ?? json['submissions'];
          if (rawSubs is List) {
            for (var s in rawSubs) {
              try {
                final ts = (s['timestamp'] is int ? s['timestamp'] : int.tryParse(s['timestamp'].toString()) ?? 0);
                submissions.add(Submission(
                  title: s['problemName'] ?? s['title'] ?? 'Problem',
                  status: s['result'] ?? s['status'] ?? 'Success',
                  timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
                ));
              } catch (_) {}
            }
          }

          // ── Subscriptions Calendar (Heatmap) ────────────────────────────────
          final Map<DateTime, int> submissionCalendar = {};
          final rawHeat = json['heatMap'];
          if (rawHeat is List) {
            for (var entry in rawHeat) {
              if (entry is Map && entry['date'] != null && entry['value'] != null) {
                try {
                  final d = DateTime.parse(entry['date'].toString());
                  submissionCalendar[DateTime(d.year, d.month, d.day)] = (entry['value'] as num).toInt();
                } catch (_) {}
              }
            }
          }

          return PlatformStats(
            platform: "CodeChef",
            username: username,
            avatarUrl: json["profile"] ?? json["profilePic"],
            totalSolved: json["numberOfProblemsSolved"] ?? json["problemsSolved"] ?? 0,
            rating: json["currentRating"] ?? json["rating"],
            maxRating: json["highestRating"] ?? json["maxRating"],
            ranking: json["stars"]?.toString() ?? "N/A",
            recentSubmissions: submissions,
            submissionCalendar: submissionCalendar,
            extraMetrics: {
              "globalRank": json["globalRank"] ?? "N/A",
              "countryRank": json["countryRank"] ?? "N/A",
            },
          );
        }
      }
      throw Exception("CodeChef: HTTP ${response.statusCode}");
    } on UserNotFoundException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) rethrow;
      throw Exception("CodeChef connectivity error: $e");
    }
  }
}


