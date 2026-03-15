import 'platform_stats.dart';

class HackerRankStats {
  final String username;
  final int totalSolved;
  final String? rank;
  final String? avatarUrl;
  final int followers;
  final String? country;
  final Map<String, dynamic> extraMetrics;

  HackerRankStats({
    required this.username,
    required this.totalSolved,
    this.rank,
    this.avatarUrl,
    required this.followers,
    this.country,
    this.extraMetrics = const {},
  });

  factory HackerRankStats.fromMultipleSources({
    required Map<String, dynamic> profileJson,
    required Map<String, dynamic> badgesJson,
    required Map<String, dynamic> scoresJson,
  }) {
    final model = profileJson['model'] ?? {};
    final badges = badgesJson['models'] as List? ?? [];
    
    // Sum solved problems from all badges
    int solvedCount = 0;
    for (var b in badges) {
      solvedCount += (b['solved'] as num? ?? 0).toInt();
    }

    // Find Algorithms rank as primary rank
    String? rank;
    final tracks = scoresJson is List
        ? scoresJson
        : (scoresJson['tracks'] is List ? scoresJson['tracks'] : []);
    for (var track in tracks) {         
      if (track['slug'] == 'algorithms') {
        rank = track['practice']?['rank']?.toString();
        if (rank == "null" || rank == "0") rank = null;
        break;
      }
    }

    return HackerRankStats(
      username: model['username'] ?? '',
      totalSolved: solvedCount,
      rank: rank ?? 'N/A',
      avatarUrl: model['avatar'],
      followers: model['followers_count'] ?? 0,
      country: model['country'],
      extraMetrics: {
        'level': model['level'],
        'badges_count': badges.length,
      },
    );
  }

  PlatformStats toPlatformStats() {
    return PlatformStats(
      platform: "HackerRank",
      username: username,
      totalSolved: totalSolved,
      rank: rank,
      avatarUrl: avatarUrl,
      extraMetrics: {
        'Country': country,
        'Followers': followers,
        ...extraMetrics,
      },
    );
  }
}
