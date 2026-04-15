import '../models/leetcode_stats.dart';

class AnalyticsEngine {
  /// Detects weak areas based on problem counts in tags.
  /// Topics with < 5 solved are labeled "Weak", < 15 "Intermediate", > 15 "Strong".
  static Map<String, List<String>> analyzeTopicStrengths(Map<String, int>? tagStats) {
    if (tagStats == null || tagStats.isEmpty) return {'Weak': [], 'Intermediate': [], 'Strong': []};

    final List<String> weak = [];
    final List<String> intermediate = [];
    final List<String> strong = [];

    tagStats.forEach((topic, count) {
      if (count < 5) {
        weak.add(topic);
      } else if (count < 15) {
        intermediate.add(topic);
      } else {
        strong.add(topic);
      }
    });

    return {
      'Weak': weak..sort((a, b) => (tagStats[a] ?? 0).compareTo(tagStats[b] ?? 0)),
      'Intermediate': intermediate..sort((a, b) => (tagStats[b] ?? 0).compareTo(tagStats[a] ?? 0)),
      'Strong': strong..sort((a, b) => (tagStats[b] ?? 0).compareTo(tagStats[a] ?? 0)),
    };
  }

  /// Generates a rule-based AI suggestion for the day.
  static String getDailyRecommendation(LeetcodeStats? lc) {
    if (lc == null) return "Connect your LeetCode profile to get personalized AI suggestions.";

    final analysis = analyzeTopicStrengths(lc.tagStats);
    final weakList = analysis['Weak'];
    
    if (weakList != null && weakList.isNotEmpty) {
      final topic = weakList.first;
      return "Focus on your weak area: **$topic**. Try solving a couple of Medium problems today to build confidence.";
    }

    if (lc.hard < (lc.totalSolved * 0.1)) {
      return "Try a Hard problem today! Your difficulty distribution is dominated by Easy/Medium questions.";
    }

    return "Keep it up! Your problem-solving balance is looking great. Target 3 problems today to maintain your streak.";
  }

  /// Calculates XP points based on total achievements.
  static int calculateXP({
    required int totalSolved,
    required int streak,
    required double rating,
    int? contestsAttended,
  }) {
    int xp = 0;
    xp += totalSolved * 10; // 10 XP per problem
    xp += (rating > 0 ? (rating / 10).toInt() : 0); // 1 XP per 10 rating pts
    xp += streak * 50; // 50 XP per streak day
    xp += (contestsAttended ?? 0) * 100; // 100 XP per contest
    return xp;
  }

  /// Aggregates submission calendar into weekly/monthly buckets for line charts.
  static Map<DateTime, int> aggregateProgress(Map<DateTime, int> calendar, {bool monthly = false}) {
    final Map<DateTime, int> data = {};
    if (calendar.isEmpty) return data;

    final sortedDates = calendar.keys.toList()..sort();
    int runningSum = 0;

    for (var date in sortedDates) {
      runningSum += calendar[date] ?? 0;
      final key = monthly 
          ? DateTime(date.year, date.month, 1) 
          : DateTime(date.year, date.month, date.day - (date.weekday - 1));
      
      data[key] = runningSum; // Cumulative total
    }
    return data;
  }
}


