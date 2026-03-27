import 'submission.dart';

class LeetcodeStats {
  final int totalSolved;
  final int easy;
  final int medium;
  final int hard;
  final String avatar;
  final int ranking;
  final double rating;
  final Map<DateTime, int> submissionCalendar;
  final int streak;
  final int longestStreak;
  final int activeDays;
  final List<LeetCodeBadge>? badges;

  // Contest Info
  final double? contestRating;
  final double? highestRating;
  final int? globalRanking;
  final double? topPercentage;
  final int? totalContests;
  final List<LeetCodeContestHistory>? contestHistory;

  // Recent Submissions
  final List<Submission>? recentSubmissions;

  // Tag Stats for Radar Chart
  final Map<String, int>? tagStats;

  LeetcodeStats({
    required this.totalSolved,
    required this.easy,
    required this.medium,
    required this.hard,
    required this.avatar,
    required this.ranking,
    required this.rating,
    required this.submissionCalendar,
    this.streak = 0,
    this.longestStreak = 0,
    this.activeDays = 0,
    this.contestRating,
    this.highestRating,
    this.globalRanking,
    this.topPercentage,
    this.totalContests,
    this.contestHistory,
    this.recentSubmissions,
    this.badges,
    this.tagStats,
  });

  // ─── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'totalSolved': totalSolved,
      'easy': easy,
      'medium': medium,
      'hard': hard,
      'avatar': avatar,
      'ranking': ranking,
      'rating': rating,
      // Store calendar as { "millisecondsSinceEpoch": count }
      'submissionCalendar': submissionCalendar.map(
        (date, count) => MapEntry(
          date.millisecondsSinceEpoch.toString(),
          count,
        ),
      ),
      'streak': streak,
      'longestStreak': longestStreak,
      'activeDays': activeDays,
      'contestRating': contestRating,
      'highestRating': highestRating,
      'globalRanking': globalRanking,
      'topPercentage': topPercentage,
      'totalContests': totalContests,
      'contestHistory': contestHistory?.map((e) => e.toJson()).toList(),
      'recentSubmissions': recentSubmissions?.map((e) => e.toJson()).toList(),
      'badges': badges?.map((e) => e.toJson()).toList(),
      'tagStats': tagStats,
    };
  }

  factory LeetcodeStats.fromJson(Map<String, dynamic> json) {
    // Restore calendar from { "millisecondsSinceEpoch": count }
    final Map<DateTime, int> calendar = {};
    final rawCal = json['submissionCalendar'] as Map<String, dynamic>?;
    if (rawCal != null) {
      rawCal.forEach((key, value) {
        final ms = int.tryParse(key);
        if (ms != null) {
          final d = DateTime.fromMillisecondsSinceEpoch(ms);
          calendar[DateTime(d.year, d.month, d.day)] = value as int;
        }
      });
    }

    return LeetcodeStats(
      totalSolved: (json['totalSolved'] as num? ?? 0).toInt(),
      easy: (json['easy'] as num? ?? 0).toInt(),
      medium: (json['medium'] as num? ?? 0).toInt(),
      hard: (json['hard'] as num? ?? 0).toInt(),
      avatar: json['avatar']?.toString() ?? '',
      ranking: (json['ranking'] as num? ?? 0).toInt(),
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      submissionCalendar: calendar,
      streak: (json['streak'] as num? ?? 0).toInt(),
      longestStreak: (json['longestStreak'] as num? ?? 0).toInt(),
      activeDays: (json['activeDays'] as num? ?? 0).toInt(),
      contestRating: (json['contestRating'] as num?)?.toDouble(),
      highestRating: (json['highestRating'] as num?)?.toDouble(),
      globalRanking: (json['globalRanking'] as num?)?.toInt(),
      topPercentage: (json['topPercentage'] as num?)?.toDouble(),
      totalContests: (json['totalContests'] as num?)?.toInt(),
      contestHistory: (json['contestHistory'] as List<dynamic>?)
          ?.map((e) => LeetCodeContestHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSubmissions: (json['recentSubmissions'] as List<dynamic>?)
          ?.map((e) => Submission.fromJson(e as Map<String, dynamic>))
          .toList(),
      badges: (json['badges'] as List<dynamic>?)
          ?.map((e) => LeetCodeBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      tagStats: (json['tagStats'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num? ?? 0).toInt())),
    );
  }
}

// ─── LeetCodeContestHistory ──────────────────────────────────────────────────

class LeetCodeContestHistory {
  final String contestTitle;
  final double rating;
  final int rank;
  final int? solved;
  final int? totalProblems;
  final DateTime date;

  LeetCodeContestHistory({
    required this.contestTitle,
    required this.rating,
    required this.rank,
    this.solved,
    this.totalProblems,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'contestTitle': contestTitle,
        'rating': rating,
        'rank': rank,
        'solved': solved,
        'totalProblems': totalProblems,
        'date': date.millisecondsSinceEpoch,
      };

  factory LeetCodeContestHistory.fromJson(Map<String, dynamic> json) =>
      LeetCodeContestHistory(
        contestTitle: json['contestTitle']?.toString() ?? '',
        rating: (json['rating'] as num? ?? 0.0).toDouble(),
        rank: (json['rank'] as num? ?? 0).toInt(),
        solved: (json['solved'] as num?)?.toInt(),
        totalProblems: (json['totalProblems'] as num?)?.toInt(),
        date: DateTime.fromMillisecondsSinceEpoch(
            (json['date'] as num? ?? 0).toInt()),
      );
}



// ─── LeetCodeBadge ───────────────────────────────────────────────────────────

class LeetCodeBadge {
  final String name;
  final String icon;
  final String? description;
  final String? earnedDate;

  LeetCodeBadge({
    required this.name,
    required this.icon,
    this.description,
    this.earnedDate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'description': description,
        'earnedDate': earnedDate,
      };

  factory LeetCodeBadge.fromJson(Map<String, dynamic> json) => LeetCodeBadge(
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        description: json['description']?.toString(),
        earnedDate: json['earnedDate']?.toString(),
      );
}