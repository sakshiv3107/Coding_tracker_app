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

      final codingProfile = await _profileService.getCodingProfile();
      if (codingProfile != null) {
        profile = codingProfile;
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Save profile to Firestore
  Future<void> saveProfile({
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
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
      );

      profile = {
        "leetcode": leetcode,
        "codechef": codechef,
        "codeforces": codeforces,
        "github": github,
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
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await _profileService.updateFullProfile(
        name: name,
        leetcode: leetcode,
        codechef: codechef,
        codeforces: codeforces,
        github: github,
      );

      profile = {
        "leetcode": leetcode,
        "codechef": codechef,
        "codeforces": codeforces,
        "github": github,
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
