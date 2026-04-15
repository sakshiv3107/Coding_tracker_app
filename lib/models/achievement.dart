
class Achievement {
  final String id;
  final String title;
  final String description;
  final dynamic icon; // Can be IconData, String (URL/Asset), or Widget
  final DateTime? earnedAt;
  final bool isEarned;
  final String category;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.earnedAt,
    this.isEarned = false,
    this.category = 'General',
  });

  bool get isUnlocked => isEarned;
  DateTime? get unlockedAt => earnedAt;

  Achievement copyWith({
    bool? isEarned,
    DateTime? earnedAt,
    dynamic icon,
    bool? isUnlocked, // For reverse compatibility
    String? title,
    String? description,
    String? category,
  }) {
    return Achievement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      earnedAt: earnedAt ?? this.earnedAt,
      isEarned: isEarned ?? isUnlocked ?? this.isEarned,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'earnedAt': earnedAt?.millisecondsSinceEpoch,
    'isEarned': isEarned,
  };

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return template.copyWith(
      isEarned: json['isEarned'] ?? json['isUnlocked'] ?? false,
      earnedAt: json['earnedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['earnedAt']) 
          : (json['unlockedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt']) : null),
    );
  }
}


