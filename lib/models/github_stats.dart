class GithubStats {
  final String login;
  final String avatarUrl;
  final String name;
  final String? bio;
  final int publicRepos;
  final int followers;
  final int following;
  final int totalStars;
  final Map<String, double> topLanguages;
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
    required this.topLanguages,
    required this.contributionCalendar,
  });

  factory GithubStats.fromJson(Map<String, dynamic> json, Map<DateTime, int> calendar, int stars, Map<String, double> languages) {
    return GithubStats(
      login: json['login'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      name: json['name'] ?? json['login'] ?? '',
      bio: json['bio'],
      publicRepos: json['public_repos'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      totalStars: stars,
      topLanguages: languages,
      contributionCalendar: calendar,
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
}
