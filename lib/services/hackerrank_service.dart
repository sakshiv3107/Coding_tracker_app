import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/hackerrank_stats.dart';
import '../core/exceptions.dart';

class HackerRankService {
  Future<HackerRankStats> fetchData(String username) async {
    if (username.trim().isEmpty) {
      throw ValidationException("HackerRank username required");
    }

    // Stable REST endpoints identified via network analysis
    final profileUrl = "https://www.hackerrank.com/rest/contests/master/hackers/$username/profile";
    final badgesUrl = "https://www.hackerrank.com/rest/hackers/$username/badges";
    final scoresUrl = "https://www.hackerrank.com/rest/hackers/$username/scores_elo";
    final historyUrl = "https://www.hackerrank.com/rest/hackers/$username/submission_histories";

    Future<dynamic> fetchJson(String url, {bool isProfile = false}) async {
      String finalUrl = url;
      if (kIsWeb) {
        finalUrl = "https://corsproxy.io/?${Uri.encodeComponent(url)}";
      }
      
      try {
        final response = await http.get(Uri.parse(finalUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else if (response.statusCode == 404 && isProfile) {
          throw UserNotFoundException("User '$username' not found on HackerRank.");
        } else {
          throw Exception("Status ${response.statusCode}");
        }
      } catch (e) {
        if (e is UserNotFoundException) rethrow;
        rethrow;
      }
    }

    try {
      final results = await Future.wait([
        fetchJson(profileUrl, isProfile: true),
        fetchJson(badgesUrl),
        fetchJson(scoresUrl),
        fetchJson(historyUrl),
      ]);

      // Parse submission history
      final Map<DateTime, int> historyMap = {};
      final dynamic historyData = results[3];
      
      if (historyData is Map) {
        historyData.forEach((dateStr, count) {
          final date = DateTime.tryParse(dateStr.toString());
          if (date != null) {
            historyMap[DateTime(date.year, date.month, date.day)] = 
                (count is num) ? count.toInt() : 0;
          }
        });
      } else if (historyData is List) {
        // If it's an empty list or unexpected array, just keep historyMap empty
        debugPrint("HackerRank: submission_histories returned a List instead of Map");
      }

      return HackerRankStats.fromMultipleSources(
        profileJson: results[0],
        badgesJson: results[1],
        scoresJson: results[2],
        history: historyMap,
      );
    } catch (e) {
      if (e is UserNotFoundException || e is ValidationException) {
        rethrow;
      }
      if (e.toString().contains("TimeoutException")) {
        throw Exception("HackerRank request timed out. Please try again.");
      }
      throw Exception("HackerRank Error: $e");
    }
  }
}
