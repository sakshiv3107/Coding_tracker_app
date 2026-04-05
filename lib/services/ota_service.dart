import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class OTAService {
  static const String versionUrl =
      "https://raw.githubusercontent.com/sakshiv3107/CodeSphere-Coding-Analytics-App/refs/heads/main/version.json";

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final PackageInfo info = await PackageInfo.fromPlatform();

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
    final r = remote.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false; // equal
  }

  /// Returns a stream of [OtaEvent] for progress tracking.
  static Stream<OtaEvent> startUpdate(String apkUrl) {
    return OtaUpdate().execute(apkUrl, destinationFilename: 'CodeSphere.apk');
  }
}
