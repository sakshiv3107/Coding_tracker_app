import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class OTAService {
  static const String versionUrl =
  "https://raw.githubusercontent.com/sakshiv3107/CodeSphere-Coding-Analytics-App/refs/heads/main/version.json";

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(versionUrl));
      final data = jsonDecode(response.body);

      PackageInfo info = await PackageInfo.fromPlatform();
      String currentVersion = info.version;

      if (data['version'] != currentVersion) {
        return data; // update available
      }
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }

  static void startUpdate(String apkUrl) {
    try {
      OtaUpdate().execute(
        apkUrl,
        destinationFilename: 'app.apk',
      );
    } catch (e) {
      print("Update failed: $e");
    }
  }
}