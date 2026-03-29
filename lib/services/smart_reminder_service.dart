import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class SmartReminderService {
  static const String _kSmartRemindersEnabled = 'smart_reminders_enabled';
  static const String _kInactivityAlertsEnabled = 'inactivity_alerts_enabled';
  static const String _kGoalAlertsEnabled = 'goal_alerts_enabled';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialization for UI and background
  static Future<void> init() async {
    // Register Workmanager if not web and not test
    if (!kIsWeb) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Schedule daily task at 8:00 PM
      // Exact timing is handled by OS, but WorkManager schedules a periodic task
      await Workmanager().registerPeriodicTask(
        "smart_behavior_reminder_task",
        "smartReminderTask",
        frequency: const Duration(hours: 24),
        initialDelay: _calculateDelayUntilEvening(),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    }
  }

  // Calculate delay until 8:00 PM tonight, or tomorrow 8:00 PM if it's past
  static Duration _calculateDelayUntilEvening() {
    final now = DateTime.now();
    var evening = DateTime(now.year, now.month, now.day, 20, 0); // 8:00 PM

    if (now.isAfter(evening)) {
      evening = evening.add(const Duration(days: 1));
    }

    return evening.difference(now);
  }

  // ... (preferences move up to stay in class)
  static Future<bool> isSmartRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSmartRemindersEnabled) ?? true;
  }

  static Future<void> setSmartRemindersEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSmartRemindersEnabled, val);
  }

  static Future<bool> isInactivityAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kInactivityAlertsEnabled) ?? true;
  }

  static Future<void> setInactivityAlertsEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kInactivityAlertsEnabled, val);
  }

  static Future<bool> isGoalAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kGoalAlertsEnabled) ?? true;
  }

  static Future<void> setGoalAlertsEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGoalAlertsEnabled, val);
  }
}

// ── Background Task Handler (Top-Level) ───────────────────────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final smartEnabled = prefs.getBool('smart_reminders_enabled') ?? true;
      
      if (!smartEnabled) return Future.value(true);

      final inactivityEnabled = prefs.getBool('inactivity_alerts_enabled') ?? true;
      final goalEnabled = prefs.getBool('goal_alerts_enabled') ?? true;

      // --- INACTIVITY CHECK ---
      if (inactivityEnabled) {
        bool hasActivityToday = await _checkIfUserHadActivityToday();
        if (!hasActivityToday) {
          await _showNotification(
            id: 100,
            title: "You didn't code today 😐",
            body: "Keep your streak alive 🔥! 1 problem makes a difference.",
          );
        }
      }

      // --- GOAL CHECK ---
      if (goalEnabled) {
        final goalsJsonStr = prefs.getString('user_dynamic_goals');
        if (goalsJsonStr != null) {
          final List list = jsonDecode(goalsJsonStr);
          bool hasIncompleteDailyGoal = false;
          for (var g in list) {
            if (g['timeframe'] == 'daily') {
              hasIncompleteDailyGoal = true;
              break;
            }
          }
          if (hasIncompleteDailyGoal) {
            await _showNotification(
              id: 101,
              title: "Complete your goal today! 🎯",
              body: "You're almost there. Finish your remaining problems to meet your daily goal.",
            );
          }
        }
      }

      return Future.value(true);
    } catch (err) {
      debugPrint("Background task failed: $err");
      return Future.value(false);
    }
  });
}

// Helper method simulating activity check for the day
Future<bool> _checkIfUserHadActivityToday() async {
  // final prefs = await SharedPreferences.getInstance();
  return false; 
}

Future<void> _showNotification({required int id, required String title, required String body}) async {
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidDetails = AndroidNotificationDetails(
    'smart_reminders_channel',
    'Smart Reminders',
    channelDescription: 'Behavior-based AI notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  
  // Use named arguments as required by the package version
  await localNotifications.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
  );
}
