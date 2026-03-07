import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_stats.dart';

class GithubService {
  static const String _url = "https://api.github.com/graphql";

  static const String _token = "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";

  Future<GithubStats> fetchStats(String username) async {
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
      headers: {
        "Authorization": "Bearer $_token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {"username": username}
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("GitHub API Error: ${response.statusCode}");
    }

    final json = jsonDecode(response.body);

    if (json["errors"] != null) {
      throw Exception(json["errors"][0]["message"]);
    }

    final user = json["data"]["user"];

    if (user == null) {
      throw Exception("GitHub user '$username' not found");
    }

    /// Calculate total stars
    int totalStars = 0;

    /// Language counts
    Map<String, int> languageCounts = {};

    final repos = user["repositories"]["nodes"];

    for (var repo in repos) {
      totalStars += (repo["stargazerCount"] ?? 0) as int;

      final lang = repo["primaryLanguage"]?["name"];
      if (lang != null) {
        languageCounts[lang] = (languageCounts[lang] ?? 0) + 1;
      }
    }

    /// Top language percentages

    int totalLangRepos =
        languageCounts.values.fold(0, (sum, count) => sum + count);

    Map<String, double> topLanguages = {};

    if (totalLangRepos > 0) {
      var sortedLangs = languageCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedLangs.take(5)) {
        topLanguages[entry.key] = entry.value / totalLangRepos;
      }
    }

    /// Contribution Heatmap
    Map<DateTime, int> calendar = {};

    final weeks = user["contributionsCollection"]["contributionCalendar"]["weeks"];

    for (var week in weeks) {
      for (var day in week["contributionDays"]) {
        final date = DateTime.parse(day["date"]);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        calendar[normalizedDate] = day["contributionCount"];
      }
    }

    /// Convert GraphQL response to your model
    return GithubStats.fromGraphQL(
      user,
      calendar,
      totalStars,
      topLanguages,
    );
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
      headers: {
        "Authorization": "Bearer $_token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "query": query,
        "variables": {"username": username}
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch repositories");
    }

    final json = jsonDecode(response.body);
    final repos = json["data"]["user"]["repositories"]["nodes"];

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