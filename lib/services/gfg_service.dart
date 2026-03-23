import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gfg_stats.dart';

class GfgService {
  // Try several potential API endpoints as fallbacks
  final List<String> _endpoints = [
    "https://gfg-api-six.vercel.app/api/user/",
    "https://geeks-for-geeks-api.vercel.app/user/",
    "https://gfg-stats.vercel.app/user/",
  ];

  Future<GfgStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("GeeksforGeeks username is empty");
    }

    Exception? lastException;

    for (String baseUrl in _endpoints) {
      String url = "$baseUrl$username";
      
      if (kIsWeb) {
        url = "https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}";
      }

      try {
        debugPrint("GFG: trying endpoint $url");
        final response = await http.get(
          Uri.parse(url),
          headers: {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "application/json",
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data["error"] != null && data["error"].toString().isNotEmpty) {
            debugPrint("GFG API returned error: ${data["error"]}");
            continue; // Try next endpoint
          }

          // Validate if it's a valid response (has some expected fields)
          if (data["info"] != null || data["totalSolved"] != null || data["userName"] != null) {
             return GfgStats.fromJson(data);
          }
        } else {
          debugPrint("GFG endpoint $baseUrl failed with status: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("GFG endpoint $baseUrl failed: $e");
        lastException = Exception(e.toString());
      }
    }

    // If all fail, throw a descriptive error
    throw lastException ?? Exception("Failed to fetch GeeksforGeeks data from all available sources (404/Timeout).");
  }
}
