class Goal {
  final String id;
  final String title;
  final int targetValue;
  final int currentValue;
  final String type; // 'leetcode' or 'github'
  final DateTime deadline;

  Goal({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.type,
    required this.deadline,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}
