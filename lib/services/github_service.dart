import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/github_stats.dart';

class GithubService {
  static const String _url = "https://api.github.com/graphql";
  static const String _token = String.fromEnvironment("GITHUB_TOKEN");

  Map<String, String> get _headers => {
    "Authorization": "Bearer $_token",
    "Content-Type": "application/json",
  };

  Future<GithubStats> fetchStats(String username) async {
    try {
      const query = """
      query getUserStats(\$username: String!) {
        user(login: \$username) {
          name
          login
          bio
          avatarUrl
          followers {
            totalCount
          }
          starredRepositories {
            totalCount
          }
          repositories(first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) {
            totalCount
            nodes {
              name
              description
              stargazerCount
              forkCount
              updatedAt
              url
              primaryLanguage {
                name
                color
              }
            }
          }
          contributionsCollection {
            contributionCalendar {
              totalContributions
              weeks {
                contributionDays {
                  date
                  contributionCount
                }
              }
            }
          }
        }
      }
      """;

      final response = await http.post(
        Uri.parse(_url),
        headers: _headers,
        body: jsonEncode({
          "query": query,
          "variables": {"username": username},
        }),
      );

      // FIX 1: was "GitHub API Error: \${response.statusCode}" — backslash
      //        prevented interpolation, showing literal text instead of code.
      if (response.statusCode != 200) {
        throw Exception("GitHub API Error: ${response.statusCode}");
      }

      final json = jsonDecode(response.body);

      if (json["errors"] != null) {
        final msg = json["errors"][0]["message"] ?? "Unknown GraphQL error";
        throw Exception("GitHub GraphQL Error: $msg");
      }

      final user = json["data"]["user"];

      // FIX 2: was "GitHub user '\$username' not found" — same backslash bug.
      if (user == null) {
        throw Exception("GitHub user '$username' not found");
      }

      int totalStars = 0;
      Map<String, int> languageCounts = {};
      final repos = user["repositories"]["nodes"] as List;

      for (var repo in repos) {
        totalStars += (repo["stargazerCount"] ?? 0) as int;
        final lang = repo["primaryLanguage"]?["name"];
        if (lang != null) {
          languageCounts[lang] = (languageCounts[lang] ?? 0) + 1;
        }
      }

      int totalLangRepos = languageCounts.values.fold(
        0,
        (sum, count) => sum + count,
      );
      Map<String, double> topLanguages = {};
      if (totalLangRepos > 0) {
        var sortedLangs = languageCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (var entry in sortedLangs.take(5)) {
          topLanguages[entry.key] = entry.value / totalLangRepos;
        }
      }

      Map<DateTime, int> calendar = {};
      final weeks =
          user["contributionsCollection"]["contributionCalendar"]["weeks"]
              as List;
      for (var week in weeks) {
        for (var day in week["contributionDays"]) {
          final date = DateTime.parse(day["date"] as String);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          calendar[normalizedDate] = day["contributionCount"] as int;
        }
      }

      return GithubStats.fromGraphQL(
        user,
        calendar,
        totalStars,
        user["starredRepositories"]?["totalCount"] ?? 0,
        topLanguages,
      );
    } catch (e) {
      // FIX 3: was "GitHub API Error for \$username: \$e" — same backslash bug.
      debugPrint("GitHub API Error for $username: $e");
      rethrow;
    }
  }

  Future<List<GithubStarredRepository>> fetchStarredRepos(
    String username,
  ) async {
    final response = await http.get(
      Uri.parse("https://api.github.com/users/$username/starred"),
      headers: {
        "Authorization": "Bearer $_token",
        "Accept": "application/vnd.github.v3+json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to fetch starred repositories: ${response.statusCode}",
      );
    }

    final List json = jsonDecode(response.body);
    return json.map((repo) => GithubStarredRepository.fromJson(repo)).toList();
  }

  Future<List<GithubRepository>> fetchLatestRepos(String username) async {
    const query = """
    query latestRepos(\$username: String!) {
      user(login: \$username) {
        repositories(first: 6, orderBy: {field: UPDATED_AT, direction: DESC}) {
          nodes {
            name
            description
            stargazerCount
            forkCount
            updatedAt
            url
            primaryLanguage {
              name
              color
            }
          }
        }
      }
    }
    """;

    final response = await http.post(
      Uri.parse(_url),
      headers: _headers,
      body: jsonEncode({
        "query": query,
        "variables": {"username": username},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch repositories: ${response.statusCode}");
    }

    final json = jsonDecode(response.body);
    final repos = json["data"]["user"]["repositories"]["nodes"] as List;

    return repos.map<GithubRepository>((repo) {
      return GithubRepository(
        name: repo["name"],
        description: repo["description"],
        stars: repo["stargazerCount"],
        forks: repo["forkCount"],
        language: repo["primaryLanguage"]?["name"],
        updatedAt: DateTime.parse(repo["updatedAt"]),
        htmlUrl: repo["url"],
      );
    }).toList();
  }
}
