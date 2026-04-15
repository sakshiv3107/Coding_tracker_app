import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class MilestoneDetector {
  static const String _kLastKnownPrefix = 'last_known_';

  static Future<void> checkMilestones({
    required String platform,
    required int currentValue,
    required String type, // 'problems', 'rating', 'contributions'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kLastKnownPrefix${platform.toLowerCase()}_$type';
    final lastKnown = prefs.getInt(key) ?? 0;

    if (currentValue <= lastKnown) return;

    final lastDateKey = '$_kLastKnownPrefix${platform.toLowerCase()}_last_date';
    final lastDateStr = prefs.getString(lastDateKey) ?? '';
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastDateStr != today && currentValue > lastKnown) {
      await NotificationService.instance.showMilestoneNotification(
        platform: platform,
        milestone: 'solved your first problem of the day',
        value: currentValue,
      );
      await prefs.setString(lastDateKey, today);
    }

    final milestones = _getMilestonesFor(platform, type);
    
    for (int milestone in milestones) {
      if (currentValue >= milestone && lastKnown < milestone) {
        await NotificationService.instance.showMilestoneNotification(
          platform: platform,
          milestone: _getMilestoneLabel(platform, type, milestone),
          value: currentValue,
        );
        break; // Show one milestone at a time
      }
    }

    await prefs.setInt(key, currentValue);
  }

  static List<int> _getMilestonesFor(String platform, String type) {
    switch (platform.toLowerCase()) {
      case 'leetcode':
        return [50, 100, 250, 500, 1000];
      case 'codechef':
        return [1400, 1600, 1800, 2000];
      case 'codeforces':
        return [1200, 1400, 1600];
      case 'github':
        return [100, 500, 1000];
      default:
        return [10, 50, 100];
    }
  }

  static String _getMilestoneLabel(String platform, String type, int milestone) {
    if (type == 'rating') {
      if (platform.toLowerCase() == 'codechef') {
        if (milestone == 1400) return 'reached 2★ rating';
        if (milestone == 1600) return 'reached 3★ rating';
        if (milestone == 1800) return 'reached 4★ rating';
        if (milestone == 2000) return 'reached 5★ rating';
      }
      if (platform.toLowerCase() == 'codeforces') {
        if (milestone == 1200) return 'become a Pupil';
        if (milestone == 1400) return 'become a Specialist';
        if (milestone == 1600) return 'become an Expert';
      }
      return 'reached $milestone rating';
    }
    
    final unit = type == 'contributions' ? 'contributions' : 'problems';
    return 'solved $milestone $unit';
  }
}


