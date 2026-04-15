
// ── AI INSIGHT COACH MODELS ──────────────────────────────────────────────────

class StatsSnapshot {
  final int streak;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final List<String> topWeakTopics;
  final int recentSubmissionCount;
  final List<String> platforms;

  StatsSnapshot({
    required this.streak,
    required this.totalSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.topWeakTopics,
    required this.recentSubmissionCount,
    required this.platforms,
  });

  Map<String, dynamic> toJson() => {
        'streak': streak,
        'totalSolved': totalSolved,
        'easySolved': easySolved,
        'mediumSolved': mediumSolved,
        'hardSolved': hardSolved,
        'topWeakTopics': topWeakTopics,
        'recentSubmissionCount': recentSubmissionCount,
        'platforms': platforms,
      };
}

class WeeklySnapshot {
  final int weekNumber;
  final int solvedThisWeek;
  final int easyThisWeek;
  final int mediumThisWeek;
  final int hardThisWeek;
  final int totalSubmissions;
  final int streakDelta;
  final String bestPlatform;
  final List<String> topicsCovered;
  final DateTime weekStart;
  final DateTime weekEnd;

  WeeklySnapshot({
    required this.weekNumber,
    required this.solvedThisWeek,
    required this.easyThisWeek,
    required this.mediumThisWeek,
    required this.hardThisWeek,
    this.totalSubmissions = 0,
    required this.streakDelta,
    required this.bestPlatform,
    this.topicsCovered = const [],
    DateTime? weekStart,
    DateTime? weekEnd,
  })  : weekStart = weekStart ?? _lastSunday(),
        weekEnd = weekEnd ?? _nextSaturday();

  static DateTime _lastSunday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday % 7));
  }

  static DateTime _nextSaturday() {
    final sun = _lastSunday();
    return sun.add(const Duration(days: 6));
  }

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'solvedThisWeek': solvedThisWeek,
        'easyThisWeek': easyThisWeek,
        'mediumThisWeek': mediumThisWeek,
        'hardThisWeek': hardThisWeek,
        'totalSubmissions': totalSubmissions,
        'streakDelta': streakDelta,
        'bestPlatform': bestPlatform,
        'topicsCovered': topicsCovered,
      };
}

class CoachInsightData {
  final String bannerInsight;
  final String nudge;
  final List<FocusProblem> focusProblems;
  final List<MistakePattern> mistakePatterns;
  final int readinessScore;
  final DateTime generatedAt;

  CoachInsightData({
    required this.bannerInsight,
    required this.nudge,
    required this.focusProblems,
    required this.mistakePatterns,
    required this.readinessScore,
    required this.generatedAt,
  });
}

class FocusProblem {
  final String problemName;
  final String platform;
  final String difficulty;
  final String topicTag;
  final String aiReason;
  final String url;

  FocusProblem({
    required this.problemName,
    required this.platform,
    required this.difficulty,
    required this.topicTag,
    required this.aiReason,
    required this.url,
  });

  factory FocusProblem.fromJson(Map<String, dynamic> json) {
    return FocusProblem(
      problemName: json['problemName'] ?? 'Unknown Problem',
      platform: json['platform'] ?? 'LeetCode',
      difficulty: json['difficulty'] ?? 'Medium',
      topicTag: json['topicTag'] ?? 'General',
      aiReason: json['aiReason'] ?? 'Highly relevant to your current focus.',
      url: json['url'] ?? 'https://leetcode.com/problemset/',
    );
  }
}

class MistakePattern {
  final String patternName;
  final int count;
  final String severity; // "red" | "amber" | "blue"
  final String detail;   // Specific problem titles or patterns detected
  String? aiTip;

  MistakePattern({
    required this.patternName,
    required this.count,
    required this.severity,
    this.detail = '',
    this.aiTip,
  });
}

class CoachGoal {
  final String id;
  final String title;
  final int target;
  final String type; // "problems" | "rating" | "streak" | "custom"
  final DateTime createdAt;
  final DateTime? targetDate;

  CoachGoal({
    required this.id,
    required this.title,
    required this.target,
    required this.type,
    DateTime? createdAt,
    this.targetDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'type': type,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'targetDate': targetDate?.millisecondsSinceEpoch,
  };

  factory CoachGoal.fromJson(Map<String, dynamic> json) => CoachGoal(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    target: json['target'] ?? 0,
    type: json['type'] ?? 'problems',
    createdAt: json['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
        : DateTime.now(),
    targetDate: json['targetDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['targetDate'])
        : null,
  );
}


