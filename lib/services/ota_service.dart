import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';

class OTAService {
  static const String versionUrl =
      "https://raw.githubusercontent.com/sakshiv3107/CodeSphere-Coding-Analytics-App/refs/heads/main/version.json";

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final PackageInfo info = await PackageInfo.fromPlatform();

      debugPrint("Current version: ${info.version}");
      debugPrint("Remote version: ${data['version']}");

      if (_isNewer(data['version'], info.version)) {
        return data;
      }
    } catch (e) {
      debugPrint("OTA check error: $e");
    }
    return null;
  }

  /// Returns true if [remote] is strictly newer than [current].
  static bool _isNewer(String remote, String current) {
    try {
      // Remove possible version suffixes like +3
      final cleanRemote = remote.split('+')[0];
      final cleanCurrent = current.split('+')[0];

      final r = cleanRemote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final c = cleanCurrent.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final rv = i < r.length ? r[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (rv > cv) return true;
        if (rv < cv) return false;
      }
    } catch (e) {
      debugPrint("Version comparison error: $e");
    }
    return false;
  }

  /// Check and request install permission for Android 8.0+
  static Future<bool> requestInstallPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      
      if (status.isDenied || status.isPermanentlyDenied) {
        final result = await Permission.requestInstallPackages.request();
        debugPrint("Install permission result: $result");
        return result.isGranted;
      }
      
      return status.isGranted;
    }
    return true;
  }

  /// Returns a stream of [OtaEvent] for progress tracking.
  static Stream<OtaEvent> startUpdate(String apkUrl) async* {
    try {
      debugPrint("Starting OTA update from: $apkUrl");
      
      // Request install permission first
      final hasPermission = await requestInstallPermission();
      
      if (!hasPermission) {
        debugPrint("Install permission not granted");
        yield OtaEvent(
          OtaStatus.PERMISSION_NOT_GRANTED_ERROR,
          'Install permission denied. Please enable "Install from unknown sources" in settings.',
        );
        return;
      }

      debugPrint("Install permission granted, starting download...");

      // Execute the OTA update with proper configuration
      await for (final event in OtaUpdate().execute(
        apkUrl,
        destinationFilename: 'CodeSphere_update.apk',
        sha256checksum: null, // Optional: add checksum for security
      )) {
        debugPrint("OTA Event - Status: ${event.status}, Value: ${event.value}");
        yield event;
        
        // Handle completion
        if (event.status == OtaStatus.INSTALLING) {
          debugPrint("Installation started!");
        } else if (event.status == OtaStatus.ALREADY_RUNNING_ERROR) {
          debugPrint("Update already running");
        } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
          debugPrint("Permission error during update");
        }
      }
    } catch (e) {
      debugPrint("OTA update error: $e");
      yield OtaEvent(
        OtaStatus.DOWNLOAD_ERROR,
        e.toString(),
      );
    }
  }
}