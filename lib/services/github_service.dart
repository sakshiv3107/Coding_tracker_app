import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_stats.dart';

class GithubService {
  static const String _baseUrl = "https://api.github.com";

  Future<GithubStats> fetchStats(String username) async {
    // Fetch User Profile (REST)
    final userResponse = await http.get(Uri.parse("$_baseUrl/users/$username"));
    if (userResponse.statusCode != 200) {
      throw Exception("GitHub user '$username' not found");
    }
    final userData = jsonDecode(userResponse.body);

    // Fetch Repositories (REST) - to calculate total stars and top languages
    final reposResponse = await http.get(Uri.parse("$_baseUrl/users/$username/repos?per_page=100&sort=updated"));
    if (reposResponse.statusCode != 200) {
      throw Exception("Failed to fetch repositories");
    }
    final List<dynamic> reposData = jsonDecode(reposResponse.body);
    
    int totalStars = 0;
    Map<String, int> languageCounts = {};
    for (var repo in reposData) {
      totalStars += (repo['stargazers_count'] as int? ?? 0);
      String? lang = repo['language'];
      if (lang != null) {
        languageCounts[lang] = (languageCounts[lang] ?? 0) + 1;
      }
    }

    // Sort and calculate top language percentages
    int totalLangRepos = languageCounts.values.fold(0, (sum, count) => sum + count);
    Map<String, double> topLanguages = {};
    if (totalLangRepos > 0) {
      var sortedLangs = languageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Top 5 languages
      for (var entry in sortedLangs.take(5)) {
        topLanguages[entry.key] = entry.value / totalLangRepos;
      }
    }

    // 3. Fetch Contribution Calendar
    // Since official REST API doesn't provide this, we use a stable public bridge
    // which is common for GitHub stats apps.
    Map<DateTime, int> calendar = {};
    try {
      final calendarResponse = await http.get(
        Uri.parse("https://github-contributions-api.deno.dev/api/v1/$username")
      ).timeout(const Duration(seconds: 10));
      
      if (calendarResponse.statusCode == 200) {
        final data = jsonDecode(calendarResponse.body);
        final contributions = data['contributions'] as List;
        for (var day in contributions) {
          final date = DateTime.parse(day['date']);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          calendar[normalizedDate] = day['count'] as int;
        }
      }
    } catch (e) {
      print("Heatmap fetch error: $e");
      // Continue without heatmap data if it fails
    }

    return GithubStats.fromJson(userData, calendar, totalStars, topLanguages);
  }

  Future<List<GithubRepository>> fetchLatestRepos(String username) async {
    final response = await http.get(Uri.parse("$_baseUrl/users/$username/repos?per_page=6&sort=updated"));
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch repositories");
    }
    
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => GithubRepository.fromJson(json)).toList();
  }
}
