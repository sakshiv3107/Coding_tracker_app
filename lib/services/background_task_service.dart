import 'package:workmanager/workmanager.dart';
import '../services/notification_service.dart';
import '../services/contest_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BackgroundTaskService {
  static const String taskContestReminder = "contestReminderTask";
  static const String taskGoalReminder = "goalReminderTask";

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        switch (task) {
          case taskContestReminder:
            await _checkAndScheduleContests();
            break;
          case taskGoalReminder:
            await _checkGoalProgress();
            break;
        }
      } catch (e) {
        debugPrint("Workmanager Task Error: $e");
      }
      return Future.value(true);
    });
  }

  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> schedulePeriodicTasks() async {
    await Workmanager().registerPeriodicTask(
      "1",
      taskContestReminder,
      frequency: const Duration(hours: 4),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      "2",
      taskGoalReminder,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> _checkAndScheduleContests() async {
    try {
      final contestService = ContestService();
      final contests = await contestService.fetchUpcomingContests();
      
      for (var contest in contests) {
        // Schedule 1 hour before
        await NotificationService.scheduleContestNotification(
          id: contest.id.hashCode,
          title: contest.title,
          platform: contest.platform,
          startTime: contest.startTime,
          minutesBefore: 60,
        );
        
        // Schedule 10 minutes before
        await NotificationService.scheduleContestNotification(
          id: contest.id.hashCode + 1,
          title: contest.title,
          platform: contest.platform,
          startTime: contest.startTime,
          minutesBefore: 10,
        );
      }
    } catch (e) {
      debugPrint("Background Contest Task Error: $e");
    }
  }

  static Future<void> _checkGoalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsStr = prefs.getString('user_dynamic_goals');
      if (goalsStr == null) return;

      // final List rawGoals = jsonDecode(goalsStr);
      // We can't use GoalProvider/ProgressService here easily without full provider tree.
      // For background tasks, we'll just send a general reminder instead of per-goal check
      // unless we store progress in SharedPreferences (which we don't yet).
      
      final now = DateTime.now();
      if (now.hour >= 18) {
        await NotificationService.showInstantNotification(
          title: "Don't forget your goals!",
          body: "Don't break your streak! Finish your coding goals before the day ends. 💪",
        );
      }
    } catch (e) {
      debugPrint("Background Goal Task Error: $e");
    }
  }
}
