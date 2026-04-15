import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "streakMonitorTask") {
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // check user preferences
        final streakEnabled = prefs.getBool('streak_warnings_enabled') ?? true;
        if (!streakEnabled) return Future.value(true);

        // Check LeetCode Streak (Mocking logic for multiple platforms)
        // In a real app, we'd iterate through all platforms
        final allKeys = prefs.getKeys();
        final lcKeys = allKeys.where((k) => k.contains('_lc_') && !k.endsWith('_ts'));
        
        for (var key in lcKeys) {
          final dataString = prefs.getString(key);
          if (dataString != null) {
            final data = jsonDecode(dataString);
            final calendar = data['submissionCalendar'] as Map<String, dynamic>?;
            
            if (calendar != null && calendar.isNotEmpty) {
              DateTime? lastSolved;
              calendar.forEach((dateStr, count) {
                try {
                  final date = DateTime.parse(dateStr);
                  if (lastSolved == null || date.isAfter(lastSolved!)) {
                    lastSolved = date;
                  }
                } catch (_) {}
              });

              if (lastSolved != null) {
                final diff = DateTime.now().difference(lastSolved!);
                if (diff.inHours >= 20 && diff.inHours < 48) {
                  await NotificationService.instance.scheduleStreakWarning(
                    platform: 'LeetCode',
                    lastSolvedTime: lastSolved!,
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Streak monitor task error: $e');
      }
    }
    return Future.value(true);
  });
}

class StreakMonitorService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static Future<void> scheduleTask() async {
    await Workmanager().registerPeriodicTask(
      "streakMonitor",
      "streakMonitorTask",
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}


