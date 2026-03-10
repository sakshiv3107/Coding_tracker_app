import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementProvider with ChangeNotifier {
  final List<Achievement> _achievements = [
    Achievement(
      id: '1',
      title: 'First Step',
      description: 'Solved your first LeetCode problem.',
      icon: Icons.auto_awesome_rounded,
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Achievement(
      id: '2',
      title: 'Streak Starter',
      description: 'Maintain a 3-day coding streak.',
      icon: Icons.local_fire_department_rounded,
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Achievement(
      id: '3',
      title: 'GitHub Guru',
      description: 'Reach 50 total GitHub stars.',
      icon: Icons.star_rounded,
    ),
    Achievement(
      id: '4',
      title: 'Hardcore Coder',
      description: 'Solve 10 hard LeetCode problems.',
      icon: Icons.psychology_rounded,
    ),
  ];

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();

  void checkAndUnlock(String title) {
    final index = _achievements.indexWhere((a) => a.title == title);
    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index] = Achievement(
        id: _achievements[index].id,
        title: _achievements[index].title,
        description: _achievements[index].description,
        icon: _achievements[index].icon,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
