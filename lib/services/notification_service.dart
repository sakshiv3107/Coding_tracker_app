import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _kEnabledKey = 'notifications_enabled';
  static const String _kPlatformPrefix = 'notify_';

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final dynamic timeZoneResult = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneResult is String
          ? timeZoneResult
          : timeZoneResult.toString();

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint(
          'NotificationService: Could not set local location for $timeZoneName. Falling back to UTC.',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Handle notification click
        },
      );

      // Handle permissions
      await requestPermissions();

      if (Platform.isIOS) {
        await _fcm.requestPermission();
      }

      // FCM Listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle background notification click
      });

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kEnabledKey) ?? true)) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'alerts',
          'Alerts',
          channelDescription: 'Goal and performance alerts',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> scheduleContestNotification({
    required int id,
    required String title,
    required String platform,
    required DateTime startTime,
    required int minutesBefore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kEnabledKey) ?? true;
    final isPlatformEnabled =
        prefs.getBool('$_kPlatformPrefix${platform.toLowerCase()}') ?? true;

    if (!isEnabled || !isPlatformEnabled) return;

    final scheduledTime = startTime.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'contest_alerts',
          'Contest Alerts',
          channelDescription: 'Reminder for upcoming coding contests',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    final notificationId = id + minutesBefore;

    await _localNotifications.zonedSchedule(
      id: notificationId,
      title: 'Contest Alert: $platform',
      body: '$title starts in $minutesBefore minutes!',
      scheduledDate: tzScheduledTime,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: platform,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
  }

  static Future<void> setPlatformEnabled(String platform, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kPlatformPrefix${platform.toLowerCase()}', enabled);
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? true;
  }

  static Future<bool> isPlatformEnabled(String platform) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kPlatformPrefix${platform.toLowerCase()}') ?? true;
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
