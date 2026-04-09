// lib/models/insight_model.dart

class InsightModel {
  final String id;
  final String title;
  final String reason;
  final String impact;
  final String confidence; // High, Medium, Low
  final bool actionable;
  final String topic;
  final InsightType type;
  final String emoji;

  const InsightModel({
    required this.id,
    required this.title,
    required this.reason,
    required this.impact,
    required this.confidence,
    this.actionable = true,
    required this.topic,
    required this.type,
    this.emoji = '🧠',
  });

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Coding Insight',
      reason: json['reason']?.toString() ?? json['explanation']?.toString() ?? '',
      impact: json['impact']?.toString() ?? 'This affects your problem solving speed.',
      confidence: json['confidence']?.toString() ?? 'Medium',
      actionable: json['actionable'] as bool? ?? true,
      topic: json['topic']?.toString() ?? 'General',
      type: _parseType(json['type']?.toString()),
      emoji: json['emoji']?.toString() ?? '🧠',
    );
  }

  static InsightType _parseType(String? t) {
    if (t == null) return InsightType.weakness;
    t = t.toLowerCase();
    if (t.contains('weakness')) return InsightType.weakness;
    if (t.contains('slowness')) return InsightType.slowness;
    if (t.contains('error')) return InsightType.errorRate;
    if (t.contains('strength')) return InsightType.strength;
    return InsightType.weakness;
  }
}

enum InsightType { weakness, slowness, errorRate, strength }

// ─────────────────────────────────────────────────
// Action Plan
// ─────────────────────────────────────────────────

class ProblemSuggestion {
  final String title;
  final String difficulty;
  final String platform;
  final String? url;

  const ProblemSuggestion({
    required this.title,
    required this.difficulty,
    required this.platform,
    this.url,
  });

  factory ProblemSuggestion.fromJson(Map<String, dynamic> json) {
    return ProblemSuggestion(
      title: json['title']?.toString() ?? 'Practice Problem',
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      platform: json['platform']?.toString() ?? 'LeetCode',
      url: json['url']?.toString(),
    );
  }
}

class ActionPlanModel {
  final List<ProblemSuggestion> problems;
  final String revisionTopic;
  final String estimatedTime;
  final String insightId;

  const ActionPlanModel({
    required this.problems,
    required this.revisionTopic,
    required this.estimatedTime,
    required this.insightId,
  });

  factory ActionPlanModel.fromJson(Map<String, dynamic> json, String insightId) {
    final probs = (json['problems'] as List<dynamic>? ?? [])
        .map((p) => ProblemSuggestion.fromJson(p as Map<String, dynamic>))
        .toList();

    return ActionPlanModel(
      problems: probs,
      revisionTopic: json['revision_topic']?.toString() ?? '',
      estimatedTime: json['estimated_time']?.toString() ?? '45 mins',
      insightId: insightId,
    );
  }
}

// ─────────────────────────────────────────────────
// Recommendation
// ─────────────────────────────────────────────────

class RecommendationModel {
  final String title;
  final String description;
  final String icon;
  final RecommendationPriority priority;
  final String type; // focus / improve / challenge / balance
  final String? actionLabel;

  const RecommendationModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
    required this.type,
    this.actionLabel,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '💡',
      priority: _parsePriority(json['priority']?.toString()),
      type: json['type']?.toString() ?? 'focus',
      actionLabel: json['action_label']?.toString(),
    );
  }

  static RecommendationPriority _parsePriority(String? p) {
    switch (p) {
      case 'high':
        return RecommendationPriority.high;
      case 'medium':
        return RecommendationPriority.medium;
      default:
        return RecommendationPriority.low;
    }
  }
}

enum RecommendationPriority { high, medium, low }

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

  CoachGoal({
    required this.id,
    required this.title,
    required this.target,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'type': type,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory CoachGoal.fromJson(Map<String, dynamic> json) => CoachGoal(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    target: json['target'] ?? 0,
    type: json['type'] ?? 'problems',
    createdAt: json['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
        : DateTime.now(),
  );
}
