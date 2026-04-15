import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/leetcode_stats.dart';
import '../services/gamification_service.dart';

class AchievementProvider with ChangeNotifier {
  List<Achievement> _achievements = [];
  int _currentStreak = 0;

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isEarned).toList();
  int get currentStreak => _currentStreak;

  Future<void> init() async {
    await GamificationService.init();
    _achievements = GamificationService.getAchievements();
    _currentStreak = await GamificationService.getStreak();
    notifyListeners();
  }

  void checkAchievements(LeetcodeStats? lc, int totalSolved, int githubStars) {
    if (lc == null) return;
    
    bool changed = false;

    // 1. Solving first problem
    if (totalSolved >= 1 && !_isEarned('1')) {
      _unlock('1');
      changed = true;
    }

    // 2. 7-Day Streak
    if (lc.streak >= 7 && !_isEarned('streak_7')) {
      _unlock('streak_7');
      changed = true;
    }

    // 3. 100 Problems
    if (totalSolved >= 100 && !_isEarned('solved_100')) {
      _unlock('solved_100');
      changed = true;
    }

    // 4. Github Stars
    if (githubStars >= 50 && !_isEarned('3')) {
      _unlock('3');
      changed = true;
    }

    // 5. Hard Problems
    if (lc.hard >= 10 && !_isEarned('4')) {
      _unlock('4');
      changed = true;
    }

    if (changed) {
      _achievements = GamificationService.getAchievements();
      notifyListeners();
    }

    if (lc.streak != _currentStreak) {
      _currentStreak = lc.streak;
      GamificationService.updateStreak(lc.streak);
      notifyListeners();
    }
  }

  bool _isEarned(String id) {
    return _achievements.any((a) => a.id == id && a.isEarned);
  }

  Future<void> _unlock(String id) async {
    await GamificationService.saveAchievement(id);
  }
}


