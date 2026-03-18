import 'platform_stats.dart';

class HackerRankStats {
  final String username;
  final int totalSolved;
  final String? rank;
  final String? avatarUrl;
  final int followers;
  final String? country;
  final Map<DateTime, int> submissionHistory;
  final Map<String, dynamic> extraMetrics;

  HackerRankStats({
    required this.username,
    required this.totalSolved,
    this.rank,
    this.avatarUrl,
    required this.followers,
    this.country,
    this.submissionHistory = const {},
    this.extraMetrics = const {},
  });

  factory HackerRankStats.fromMultipleSources({
    required dynamic profileJson,
    required dynamic badgesJson,
    required dynamic scoresJson,
    required Map<DateTime, int> history,
  }) {
    // Safe profile parsing
    final profileMap = profileJson is Map<String, dynamic> ? profileJson : {};
    final model = profileMap['model'] is Map<String, dynamic> ? profileMap['model'] : {};
    
    // Safe badges parsing
    List badges = [];
    if (badgesJson is Map<String, dynamic>) {
      badges = badgesJson['models'] is List ? badgesJson['models'] : [];
    } else if (badgesJson is List) {
      badges = badgesJson;
    }
    
    // Sum solved problems from all badges
    int solvedCount = 0;
    for (var b in badges) {
      if (b is Map) {
        solvedCount += (b['solved'] as num? ?? 0).toInt();
      }
    }

    // Safe scores parsing to find Algorithm rank
    String? rank;
    List tracks = [];
    if (scoresJson is List) {
      tracks = scoresJson;
    } else if (scoresJson is Map<String, dynamic>) {
      tracks = scoresJson['tracks'] is List 
          ? scoresJson['tracks'] 
          : (scoresJson['models'] is List ? scoresJson['models'] : []);
    }

    for (var track in tracks) {         
      if (track is Map && track['slug'] == 'algorithms') {
        final practice = track['practice'];
        if (practice is Map) {
          rank = practice['rank']?.toString();
        }
        if (rank == "null" || rank == "0") rank = null;
        break;
      }
    }

    return HackerRankStats(
      username: model['username']?.toString() ?? '',
      totalSolved: solvedCount,
      rank: rank ?? 'N/A',
      avatarUrl: model['avatar']?.toString(),
      followers: (model['followers_count'] as num? ?? 0).toInt(),
      country: model['country']?.toString(),
      submissionHistory: history,
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
