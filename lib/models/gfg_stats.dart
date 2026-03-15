import 'platform_stats.dart';

class GfgStats {
  final String username;
  final String? name;
  final String? profilePic;
  final int totalSolved;
  final int score;
  final String? rank;
  final int monthlyRank;
  final Map<String, int> difficultySolved;

  GfgStats({
    required this.username,
    this.name,
    this.profilePic,
    required this.totalSolved,
    required this.score,
    this.rank,
    this.monthlyRank = 0,
    this.difficultySolved = const {},
  });

  factory GfgStats.fromJson(Map<String, dynamic> json) {
    // Handling potential variations in API response
    final info = json['info'] ?? json;
    
    // Some APIs return difficulty details
    final solvedData = json['solvedData'] ?? {};
    
    return GfgStats(
      username: info['userName'] ?? info['handle'] ?? '',
      name: info['name'],
      profilePic: info['profilePic'],
      totalSolved: info['totalSolved'] is int ? info['totalSolved'] : int.tryParse(info['totalSolved']?.toString() ?? '0') ?? 0,
      score: info['codingScore'] ?? info['score'] ?? 0,
      rank: info['globalRank']?.toString() ?? info['rank']?.toString(),
      monthlyRank: info['monthlyRank'] ?? 0,
      difficultySolved: {
        'School': solvedData['School'] ?? 0,
        'Basic': solvedData['Basic'] ?? 0,
        'Easy': solvedData['Easy'] ?? 0,
        'Medium': solvedData['Medium'] ?? 0,
        'Hard': solvedData['Hard'] ?? 0,
      },
    );
  }

  PlatformStats toPlatformStats() {
    return PlatformStats(
      platform: "GeeksforGeeks",
      username: username,
      totalSolved: totalSolved,
      rank: rank,
      rating: score,
      avatarUrl: profilePic,
      extraMetrics: {
        'Score': score,
        'Monthly Rank': monthlyRank,
        ...difficultySolved,
      },
    );
  }
}
