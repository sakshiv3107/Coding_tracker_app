import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  Map<String, String>? profile;
  bool isLoading = false;
  String? error;

  bool get isProfileCompleted => profile != null;

  // Initialize profile from Firestore
  Future<void> initializeProfile() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      // Basic timeout to prevent black screen hang if firestore is offline/DNS fail
      final codingProfile = await _profileService.getCodingProfile()
          .timeout(const Duration(seconds: 10));
      
      if (codingProfile != null) {
        profile = codingProfile;
      }
    } catch (e) {
      debugPrint("Profile init error: $e");
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Save profile to Firestore
  Future<void> saveProfile({
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
    String? hackerrank,
    String? gfg,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await _profileService.saveCodingProfile(
        leetcode: leetcode,
        codechef: codechef,
        codeforces: codeforces,
        github: github,
        hackerrank: hackerrank,
        gfg: gfg,
      );

      profile = {
        "leetcode": leetcode,
        "codechef": codechef,
        "codeforces": codeforces,
        "github": github,
        "hackerrank": hackerrank ?? "",
        "gfg": gfg ?? "",
      };
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Update profile in Firestore and local state
  Future<void> updateFullProfile({
    String? name,
    String? profilePic,
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
    String? hackerrank,
    String? gfg,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await _profileService.updateFullProfile(
        name: name,
        profilePic: profilePic,
        leetcode: leetcode,
        codechef: codechef,
        codeforces: codeforces,
        github: github,
        hackerrank: hackerrank,
        gfg: gfg,
      );

      profile = {
        "leetcode": leetcode,
        "codechef": codechef,
        "codeforces": codeforces,
        "github": github,
        "hackerrank": hackerrank ?? "",
        "gfg": gfg ?? "",
        "profilePic": profilePic ?? profile?["profilePic"] ?? "",
      };
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void clearProfile() {
    profile = null;
    error = null;
    notifyListeners();
  }
}
