import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/achievement.dart';

class GamificationService {
  static const String _boxName = 'gamification_box';
  static late Box _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
       // Register adapters if needed, but since we use simple maps, not really needed.
    }
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // Define achievement templates
  static final List<Achievement> _templates = [
    Achievement(
      id: '1',
      title: 'First Step',
      description: 'Solved your first LeetCode problem.',
      icon: Icons.auto_awesome_rounded,
      category: 'Progres',
    ),
    Achievement(
      id: 'streak_7',
      title: '🔥 7-Day Hot Streak',
      description: 'Solved at least one problem for 7 consecutive days!',
      icon: Icons.local_fire_department_rounded,
      category: 'Streaks',
    ),
    Achievement(
      id: 'solved_100',
      title: '🧠 Centurion Solver',
      description: 'Solved over 100 problems across all platforms!',
      icon: Icons.psychology_rounded,
      category: 'Problems',
    ),
    Achievement(
      id: '3',
      title: 'GitHub Guru',
      description: 'Reach 50 total GitHub stars.',
      icon: Icons.star_rounded,
      category: 'GitHub',
    ),
    Achievement(
      id: '4',
      title: 'Hardcore Coder',
      description: 'Solve 10 hard LeetCode problems.',
      icon: Icons.diamond_rounded,
      category: 'Difficulty',
    ),
    Achievement(
      id: 'first_contest',
      title: '🚀 Contest Pioneer',
      description: 'Participated in your first coding contest!',
      icon: Icons.rocket_launch_rounded,
      category: 'Contests',
    ),
  ];

  static List<Achievement> getAchievements() {
    final List<Achievement> results = [];
    final savedData = _box.get('achievements', defaultValue: <dynamic, dynamic>{});
    
    for (final template in _templates) {
      if (savedData.containsKey(template.id)) {
        results.add(Achievement.fromJson(Map<String, dynamic>.from(savedData[template.id]), template));
      } else {
        results.add(template);
      }
    }
    return results;
  }

  static Future<void> saveAchievement(String id) async {
    final achievements = Map<dynamic, dynamic>.from(_box.get('achievements', defaultValue: <dynamic, dynamic>{}));
    achievements[id] = {
      'id': id,
      'isEarned': true,
      'earnedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _box.put('achievements', achievements);
  }

  static Future<int> getStreak() async {
    return _box.get('current_streak', defaultValue: 0);
  }

  static Future<void> updateStreak(int newStreak) async {
    await _box.put('current_streak', newStreak);
    await _box.put('last_streak_update', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastStreakUpdate() async {
    final ts = _box.get('last_streak_update');
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }
}


