import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationPermissionService {
  static const String _kPermissionRequestedKey = 'notification_permission_requested';

  static Future<void> checkAndRequestPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_kPermissionRequestedKey) ?? false;

    if (!alreadyRequested) {
      // Show friendly explanation dialog first
      if (context.mounted) {
        await _showExplanationDialog(context);
        await prefs.setBool(_kPermissionRequestedKey, true);
      }
    }
  }

  static Future<void> _showExplanationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Stay Updated! 🔔",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Get notified about:"),
            SizedBox(height: 12),
            Text("✓ Upcoming contests (1 day, 1 hour, 30 min before)"),
            Text("✓ Streak break warnings"),
            Text("✓ Achievement milestones"),
            SizedBox(height: 16),
            Text("You can change this anytime in settings."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _requestSystemPermission();
            },
            child: const Text("Enable Notifications"),
          ),
        ],
      ),
    );
  }

  static Future<void> _requestSystemPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) requires runtime permission
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await Permission.notification.request();
    }
  }

  static Future<bool> isPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}


