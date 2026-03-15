import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/hackerrank_stats.dart';

class HackerRankService {
  Future<HackerRankStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("HackerRank username is empty");
    }

    // Stable REST endpoints identified via network analysis
    final profileUrl = "https://www.hackerrank.com/rest/contests/master/hackers/$username/profile";
    final badgesUrl = "https://www.hackerrank.com/rest/hackers/$username/badges";
    final scoresUrl = "https://www.hackerrank.com/rest/hackers/$username/scores_elo";

    Future<Map<String, dynamic>> fetchJson(String url) async {
      String finalUrl = url;
      if (kIsWeb) {
        // Use corsproxy.io for web
        finalUrl = "https://corsproxy.io/?${Uri.encodeComponent(url)}";
      }
      
      final response = await http.get(Uri.parse(finalUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Status ${response.statusCode}");
      }
    }

    try {
      final results = await Future.wait([
        fetchJson(profileUrl),
        fetchJson(badgesUrl),
        fetchJson(scoresUrl),
      ]);

      return HackerRankStats.fromMultipleSources(
        profileJson: results[0],
        badgesJson: results[1],
        scoresJson: results[2],
      );
    } catch (e) {
      if (e.toString().contains("TimeoutException")) {
        throw Exception("HackerRank request timed out. Please try again.");
      }
      throw Exception("HackerRank Error: $e");
    }
  }
}
