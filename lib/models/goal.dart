// import 'dart:convert';

enum GoalType {
  questions,
  commits,
}

enum GoalTimeframe {
  daily,
  weekly,
}

class Goal {
  final String id;
  final String title;
  final GoalType type;
  final int targetValue;
  final GoalTimeframe timeframe;
  final String? platform;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.timeframe,
    this.platform,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'targetValue': targetValue,
      'timeframe': timeframe.toString().split('.').last,
      'platform': platform,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    var rawType = json['type'];
    if (rawType == 'questionsPerDay') rawType = 'questions'; // Migration
    if (rawType == 'commitsPerWeek') rawType = 'commits';    // Migration

    return Goal(
      id: json['id'],
      title: json['title'],
      type: GoalType.values.byName(rawType),
      targetValue: json['targetValue'],
      timeframe: GoalTimeframe.values.byName(json['timeframe']),
      platform: json['platform'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}


