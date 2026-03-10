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
  
  // Contest Info
  final double? contestRating;
  final double? highestRating;
  final int? globalRanking;
  final double? topPercentage;
  final int? totalContests;
  final List<LeetCodeContestHistory>? contestHistory;
  
  // Recent Submissions
  final List<RecentSubmission>? recentSubmissions;

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
  });
}

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
}

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
}
