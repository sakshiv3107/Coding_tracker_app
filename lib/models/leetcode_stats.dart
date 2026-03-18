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
  final List<RecentSubmission>? recentSubmissions;

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
      totalSolved: json['totalSolved'] as int,
      easy: json['easy'] as int,
      medium: json['medium'] as int,
      hard: json['hard'] as int,
      avatar: json['avatar'] as String,
      ranking: json['ranking'] as int,
      rating: (json['rating'] as num).toDouble(),
      submissionCalendar: calendar,
      streak: json['streak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      activeDays: json['activeDays'] as int? ?? 0,
      contestRating: (json['contestRating'] as num?)?.toDouble(),
      highestRating: (json['highestRating'] as num?)?.toDouble(),
      globalRanking: json['globalRanking'] as int?,
      topPercentage: (json['topPercentage'] as num?)?.toDouble(),
      totalContests: json['totalContests'] as int?,
      contestHistory: (json['contestHistory'] as List<dynamic>?)
          ?.map((e) => LeetCodeContestHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentSubmissions: (json['recentSubmissions'] as List<dynamic>?)
          ?.map((e) => RecentSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      badges: (json['badges'] as List<dynamic>?)
          ?.map((e) => LeetCodeBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      tagStats: (json['tagStats'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
    );
  }
}

// ─── LeetCodeContestHistory ──────────────────────────────────────────────────

class LeetCodeContestHistory {
  final String contestTitle;
  final double rating;
  final int rank;
  final DateTime date;

  LeetCodeContestHistory({
    required this.contestTitle,
    required this.rating,
    required this.rank,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'contestTitle': contestTitle,
        'rating': rating,
        'rank': rank,
        'date': date.millisecondsSinceEpoch,
      };

  factory LeetCodeContestHistory.fromJson(Map<String, dynamic> json) =>
      LeetCodeContestHistory(
        contestTitle: json['contestTitle'] as String,
        rating: (json['rating'] as num).toDouble(),
        rank: json['rank'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      );
}

// ─── RecentSubmission ────────────────────────────────────────────────────────

class RecentSubmission {
  final String title;
  final String titleSlug;
  final String difficulty;
  final String status;
  final DateTime timestamp;

  RecentSubmission({
    required this.title,
    required this.titleSlug,
    required this.difficulty,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'titleSlug': titleSlug,
        'difficulty': difficulty,
        'status': status,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory RecentSubmission.fromJson(Map<String, dynamic> json) =>
      RecentSubmission(
        title: json['title'] as String,
        titleSlug: json['titleSlug'] as String,
        difficulty: json['difficulty'] as String? ?? '',
        status: json['status'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
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
        name: json['name'] as String,
        icon: json['icon'] as String,
        description: json['description'] as String?,
        earnedDate: json['earnedDate'] as String?,
      );
}