import 'package:flutter/material.dart';
import '../models/goal.dart';

class GoalProvider with ChangeNotifier {
  final List<Goal> _goals = [
    Goal(
      id: '1',
      title: 'Weekly LeetCode Solved',
      targetValue: 15,
      currentValue: 7,
      type: 'leetcode',
      deadline: DateTime.now().add(const Duration(days: 3)),
    ),
    Goal(
      id: '2',
      title: 'Daily Commits',
      targetValue: 5,
      currentValue: 2,
      type: 'github',
      deadline: DateTime.now().add(const Duration(hours: 12)),
    ),
  ];

  List<Goal> get goals => _goals;

  void addGoal(Goal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  void updateGoalProgress(String id, int newValue) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final goal = _goals[index];
      _goals[index] = Goal(
        id: goal.id,
        title: goal.title,
        targetValue: goal.targetValue,
        currentValue: newValue,
        type: goal.type,
        deadline: goal.deadline,
      );
      notifyListeners();
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
