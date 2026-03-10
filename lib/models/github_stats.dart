class GithubStats {
  final String login;
  final String avatarUrl;
  final String name;
  final String? bio;
  final int publicRepos;
  final int followers;
  final int following;
  final int totalStars;
  final int totalStarredRepos;
  final Map<String, double> topLanguages;
  final int totalContributions;
  final Map<DateTime, int> contributionCalendar;

  GithubStats({
    required this.login,
    required this.avatarUrl,
    required this.name,
    this.bio,
    required this.publicRepos,
    required this.followers,
    required this.following,
    required this.totalStars,
    required this.totalStarredRepos,
    required this.topLanguages,
    required this.totalContributions,
    required this.contributionCalendar,
  });

  /// REST API constructor
  factory GithubStats.fromJson(
    Map<String, dynamic> json,
    Map<DateTime, int> calendar,
    int totalStars,
    int starredRepos,
    Map<String, double> languages,
    int totalContributions,
  ) {
    return GithubStats(
      login: json['login'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      name: json['name'] ?? json['login'] ?? '',
      bio: json['bio'],
      publicRepos: json['public_repos'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      totalStars: totalStars,
      totalStarredRepos: starredRepos,
      topLanguages: languages,
      totalContributions: totalContributions,
      contributionCalendar: calendar,
    );
  }

  /// GraphQL constructor
  factory GithubStats.fromGraphQL(
    Map<String, dynamic> user,
    Map<DateTime, int> calendar,
    int totalStars,
    int totalStarredRepos,
    Map<String, double> topLanguages,
  ) {
    return GithubStats(
      login: user["login"] ?? "",
      avatarUrl: user["avatarUrl"] ?? "",
      name: user["name"] ?? user["login"] ?? "",
      bio: user["bio"],
      publicRepos: user["repositories"]?["totalCount"] ?? 0,
      followers: user["followers"]?["totalCount"] ?? 0,
      following: user["following"]?["totalCount"] ?? 0,
      totalStars: totalStars,
      totalStarredRepos: totalStarredRepos,
      topLanguages: topLanguages,
      totalContributions: user["contributionsCollection"]?["contributionCalendar"]?["totalContributions"] ?? 0,
      contributionCalendar: calendar,
    );
  }
}

class GithubStarredRepository {
  final String name;
  final String owner;
  final String? description;
  final int stars;
  final String? language;
  final String htmlUrl;

  GithubStarredRepository({
    required this.name,
    required this.owner,
    this.description,
    required this.stars,
    this.language,
    required this.htmlUrl,
  });

  factory GithubStarredRepository.fromJson(Map<String, dynamic> json) {
    return GithubStarredRepository(
      name: json['name'] ?? '',
      owner: json['owner']?['login'] ?? '',
      description: json['description'],
      stars: json['stargazers_count'] ?? 0,
      language: json['language'],
      htmlUrl: json['html_url'] ?? '',
    );
  }
}

class GithubRepository {
  final String name;
  final String? description;
  final int stars;
  final int forks;
  final String? language;
  final DateTime updatedAt;
  final String htmlUrl;

  GithubRepository({
    required this.name,
    this.description,
    required this.stars,
    required this.forks,
    this.language,
    required this.updatedAt,
    required this.htmlUrl,
  });

  factory GithubRepository.fromJson(Map<String, dynamic> json) {
    return GithubRepository(
      name: json['name'] ?? '',
      description: json['description'],
      stars: json['stargazers_count'] ?? 0,
      forks: json['forks_count'] ?? 0,
      language: json['language'],
      updatedAt: DateTime.parse(json['updated_at']),
      htmlUrl: json['html_url'] ?? '',
    );
  }

  /// GraphQL version
  factory GithubRepository.fromGraphQL(Map<String, dynamic> json) {
    return GithubRepository(
      name: json["name"] ?? "",
      description: json["description"],
      stars: json["stargazerCount"] ?? 0,
      forks: json["forkCount"] ?? 0,
      language: json["primaryLanguage"]?["name"],
      updatedAt: DateTime.parse(json["updatedAt"]),
      htmlUrl: json["url"] ?? "",
    );
  }
}