import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leetcode_stats.dart';

class LeetcodeService {
  Future<LeetcodeStats> fetchData(String username) async {
    if (username.isEmpty) {
      throw Exception("Username cannot be empty");
    }

    final profileUrl = Uri.parse(
      "https://alfa-leetcode-api.onrender.com/$username");

    final solvedUrl = Uri.parse(
      "https://alfa-leetcode-api.onrender.com/$username/solved");

    final profileResponse = await http.get(profileUrl).timeout(const Duration(seconds: 15));
    final solvedResponse = await http.get(solvedUrl).timeout(const Duration(seconds: 15));

    if (profileResponse.statusCode == 404 || solvedResponse.statusCode == 404) {
      throw Exception("LeetCode user '$username' not found");
    }

    if (profileResponse.statusCode != 200 || solvedResponse.statusCode != 200) {
      throw Exception("API Error: ${profileResponse.statusCode}");
    }

    final data = jsonDecode(solvedResponse.body);
    final profile = jsonDecode(profileResponse.body);
    print(data);

    int total = data["totalSolved"] ?? data["solvedProblem"] ?? 0;
    int easy = data["easySolved"] ?? 0;
    int medium = data["mediumSolved"] ?? 0;
    int hard = data["hardSolved"] ?? 0;

    return LeetcodeStats(
      totalSolved: total,
      easy: easy,
      medium: medium,
      hard: hard,
      avatar: "https://leetcode.com${profile["avatar"]}",
      ranking: int.tryParse(profile["ranking"].toString()) ?? 0,
    );
  }
}
