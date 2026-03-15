import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gfg_stats.dart';

class GfgService {
  Future<GfgStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("GeeksforGeeks username is empty");
    }

    // Using a popular unofficial GFG API
    String url = "https://gfg-stats.vercel.app/user/$username";
    
    if (kIsWeb) {
      url = "https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}";
    }

    try {
      debugPrint("GFG fetching for username: '$username'");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data["error"] != null) {
          throw Exception(data["error"]);
        }

        return GfgStats.fromJson(data);
      } else {
        throw Exception("Failed to fetch GeeksforGeeks data (Status: ${response.statusCode})");
      }
    } catch (e) {
      if (e.toString().contains("TimeoutException")) {
        throw Exception("GeeksforGeeks server is slow or timed out. Please try again.");
      }
      throw Exception("GeeksforGeeks Error: $e");
    }
  }
}
