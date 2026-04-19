import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Channels IDs
  static const String channelContests = 'contest_reminders';
  static const String channelStreaks = 'streak_warnings';
  static const String channelMilestones = 'milestones';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final dynamic timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      debugPrint("Timezone initialization failed: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: handleNotificationTap,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        channelContests,
        'Contest Reminders',
        description: 'Upcoming contest alerts',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        channelStreaks,
        'Streak Warnings',
        description: 'Maintain your streak',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        channelMilestones,
        'Achievements',
        description: 'Milestone celebrations',
        importance: Importance.high,
      ),
    ];

    for (var channel in channels) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Contest Notifications
  Future<void> scheduleContestReminders({
    required String contestId,
    required String platform,
    required String contestName,
    required DateTime startTime,
    required String contestUrl,
  }) async {
    final now = DateTime.now();
    final payload = jsonEncode({
      "type": "contest",
      "platform": platform,
      "url": contestUrl,
      "contestId": contestId
    });

    final offsets = {
      1440: "Tomorrow", // 1 day
      60: "Starting in 1 hour!",
      30: "Starting soon! Get ready 🚀",
    };

    // Load quiet hours
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString('quiet_hours_start') ?? "22:00";
    final endStr = prefs.getString('quiet_hours_end') ?? "08:00";
    
    final quietStart = int.parse(startStr.split(':')[0]) * 60 + int.parse(startStr.split(':')[1]);
    final quietEnd = int.parse(endStr.split(':')[0]) * 60 + int.parse(endStr.split(':')[1]);

    for (var entry in offsets.entries) {
      final minutesBefore = entry.key;
      final label = entry.value;
      
      final scheduledTime = startTime.subtract(Duration(minutes: minutesBefore));
      
      if (scheduledTime.isAfter(now)) {
        // Respect Quiet Hours roughly (if scheduled time falls in quiet hours, maybe skip or adjust?)
        // For now, let's just skip if it's strictly within quiet hours and not the "immediate" one.
        final scheduledMinutes = scheduledTime.hour * 60 + scheduledTime.minute;
        bool isQuiet = false;
        if (quietStart < quietEnd) {
          isQuiet = scheduledMinutes >= quietStart && scheduledMinutes <= quietEnd;
        } else {
          // Crosses midnight
          isQuiet = scheduledMinutes >= quietStart || scheduledMinutes <= quietEnd;
        }

        if (isQuiet && minutesBefore > 30) {
           debugPrint("[Notification] Skipping $label due to quiet hours ($startStr - $endStr)");
           continue;
        }

        // Robust ID: combine hash of contest and the offset
        // Using enough spacing to avoid overlaps with other notification types
        int baseId = contestId.hashCode.abs() % 10000;
        int notificationId = 100000 + (minutesBefore * 10000) + baseId;
        
        try {
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            'Contest Alert: $platform',
            minutesBefore == 1440 ? '$contestName starts tomorrow!' : label,
            tz.TZDateTime.from(scheduledTime, tz.local),
            NotificationDetails(
              android: AndroidNotificationDetails(
                channelContests,
                'Contest Reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
          debugPrint("[Notification] Scheduled: $label for $contestName at $scheduledTime (ID: $notificationId)");
        } catch (e) {
          debugPrint("[Notification] Failed to schedule exact alarm: $e");
          // Fallback to inexact if exact fails
          try {
            await _notificationsPlugin.zonedSchedule(
              notificationId,
              'Contest Alert: $platform',
              minutesBefore == 1440 ? '$contestName starts tomorrow!' : label,
              tz.TZDateTime.from(scheduledTime, tz.local),
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channelContests,
                  'Contest Reminders',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: const DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: payload,
            );
          } catch (e2) {
             debugPrint("[Notification] Inexact fallback also failed: $e2");
          }
        }
      }
    }
  }

  // Streak Warnings
  Future<void> scheduleStreakWarning({
    required String platform,
    required DateTime lastSolvedTime,
  }) async {
    final scheduledTime = lastSolvedTime.add(const Duration(hours: 24));
    if (scheduledTime.isBefore(DateTime.now())) return;

    final payload = jsonEncode({
      "type": "streak",
      "platform": platform,
    });

    int notificationId = 4000 + (platform.hashCode.abs() % 1000);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Streak Warning! 🔥',
      'Your $platform streak is at risk. Solve a problem now!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelStreaks,
          'Streak Warnings',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Milestone Celebrations
  Future<void> showMilestoneNotification({
    required String platform,
    required String milestone,
    required int value,
  }) async {
    final payload = jsonEncode({
      "type": "milestone",
      "platform": platform,
    });

    int notificationId = 5000 + (platform.hashCode.abs() % 1000);

    await _notificationsPlugin.show(
      notificationId,
      '🎉 Milestone Unlocked!',
      'You\'ve $milestone on $platform! Keep up the amazing work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelMilestones,
          'Achievements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // Cancel specific notifications
  Future<void> cancelContestNotifications(String contestId) async {
    int baseId = contestId.hashCode.abs() % 10000;
    final offsets = [1440, 60, 30];
    for (var offset in offsets) {
      await _notificationsPlugin.cancel(100000 + (offset * 10000) + baseId);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Deep linking handler
  void handleNotificationTap(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        if (data['url'] != null) {
          final uri = Uri.parse(data['url']);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    }
  }
}


