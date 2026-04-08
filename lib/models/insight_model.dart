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
