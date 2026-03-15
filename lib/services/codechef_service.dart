import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/platform_stats.dart';

class CodeChefService {
  Future<PlatformStats> fetchData(String username) async {
    // Community API proxy for CodeChef - updated to a working variant
    // Community API proxy for CodeChef - updated to a working variant
    String urlStr = "https://codechefapi.vercel.app/handle/$username";
    
    if (kIsWeb) {
      urlStr = "https://corsproxy.io/?${Uri.encodeComponent(urlStr)}";
    }
    
    final url = Uri.parse(urlStr);
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["success"] == true || json["name"] != null) {
          return PlatformStats(
            platform: "CodeChef",
            username: username,
            avatarUrl: json["profile"],
            totalSolved: json["numberOfProblemsSolved"] ?? 0,
            rating: json["currentRating"],
            maxRating: json["highestRating"],
            rank: json["stars"] ?? "N/A",
            extraMetrics: {
              "globalRank": json["globalRank"],
              "countryRank": json["countryRank"],
            },
          );
        }
      }
      throw Exception("CodeChef user '$username' not found");
    } catch (e) {
      throw Exception("Failed to fetch CodeChef data: $e");
    }
  }
}
