// lib/providers/profile_provider.dart
//
// KEY FIXES:
//  1. `isProfileCompleted` is now backed by SharedPreferences so it survives
//     app restarts without a Firestore round-trip.
//  2. `initializeProfile()` reads the local flag first (instant) then fetches
//     the full profile from Firestore in background.
//  3. `saveProfile()` persists the flag locally AND to Firestore, guaranteeing
//     the next cold start goes straight to HomeScreen.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  // ── Persisted flag key ────────────────────────────────────────────────────
  static const String _kProfileCompletedKey = 'profile_completed';

  Map<String, String>? profile;
  bool isLoading = false;
  String? error;

  // ── Profile-completed flag ────────────────────────────────────────────────
  // Backed by SharedPreferences so on cold start the AuthWrapper can route
  // to HomeScreen immediately, even before Firestore responds.
  bool _profileCompleted = false;

  bool get isProfileCompleted => _profileCompleted || profile != null;

  // ── Initialize profile from Firestore ─────────────────────────────────────
  // Step 1: Read the local SharedPreferences flag (instant, no network).
  // Step 2: Fetch full profile data from Firestore for the dashboard.
  // If the Firestore call fails, isProfileCompleted still returns true
  // from the local flag — so the user won't be bounced to ProfileSetup.
  Future<void> initializeProfile() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      // ── 1. Instant local check ──────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      _profileCompleted = prefs.getBool(_kProfileCompletedKey) ?? false;

      // If the local flag is already set, notify immediately so AuthWrapper
      // can show HomeScreen while we fetch the full profile in background.
      if (_profileCompleted) {
        isLoading = false;
        notifyListeners();
      }

      // ── 2. Firestore fetch for full profile data ───────────────────────
      final codingProfile = await _profileService.getCodingProfile()
          .timeout(const Duration(seconds: 10));

      if (codingProfile != null) {
        profile = codingProfile;
        // Ensure the local flag is in sync with Firestore state.
        if (!_profileCompleted) {
          _profileCompleted = true;
          await prefs.setBool(_kProfileCompletedKey, true);
        }
      } else {
        // Firestore returned null (no profile document or no 'profile' field).
        // Check the explicit `profileCompleted` flag in Firestore as fallback.
        try {
          final isComplete = await _profileService.isProfileCompleted()
              .timeout(const Duration(seconds: 5));
          if (isComplete && !_profileCompleted) {
            _profileCompleted = true;
            await prefs.setBool(_kProfileCompletedKey, true);
          }
        } catch (_) {
          // If this also fails, we rely on the local flag.
        }
      }
    } catch (e) {
      debugPrint("Profile init error: $e");
      error = e.toString();
      // IMPORTANT: Even on error, if the local flag was set from a previous
      // successful session, isProfileCompleted remains true. The user is NOT
      // bounced back to ProfileSetup just because Firestore is unreachable.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Save profile to Firestore AND persist the flag locally ────────────────
  Future<void> saveProfile({
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
    String? hackerrank,
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
      );

      profile = {
        "leetcode": leetcode,
        "codechef": codechef,
        "codeforces": codeforces,
        "github": github,
        "hackerrank": hackerrank ?? "",
      };

      // ── Persist the completed flag locally ────────────────────────────
      _profileCompleted = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kProfileCompletedKey, true);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // ── Update profile in Firestore and local state ───────────────────────────
  Future<void> updateFullProfile({
    String? name,
    String? profilePic,
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
    String? hackerrank,
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
      );

      profile = {
        "leetcode": leetcode,
        "codechef": codechef,
        "codeforces": codeforces,
        "github": github,
        "hackerrank": hackerrank ?? "",
        "profilePic": profilePic ?? profile?["profilePic"] ?? "",
      };

      // Ensure the flag stays set after an update.
      if (!_profileCompleted) {
        _profileCompleted = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kProfileCompletedKey, true);
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // ── Clear profile (on logout) ─────────────────────────────────────────────
  Future<void> clearProfile() async {
    profile = null;
    _profileCompleted = false;
    error = null;

    // Clear the persisted flag so the next login goes through the full flow.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfileCompletedKey);
    } catch (_) {}

    notifyListeners();
  }
}
