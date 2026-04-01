// lib/providers/profile_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import 'dart:convert';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final StorageService _storageService = StorageService();

  // ─── SharedPrefs Keys (isolated per user) ───────────────────────────────
  String _getProfileKey(String uid) => 'profile_data_$uid';
  String _getCompletedKey(String uid) => 'profile_completed_$uid';

  Map<String, String>? profile;
  bool isLoading = false;
  String? error;

  // ── Profile-completed flag ────────────────────────────────────────────────
  bool _profileCompleted = false;

  bool get isProfileCompleted => _profileCompleted || profile != null;

  // ── Initialize profile ────────────────────────────────────────────────────
  Future<void> initializeProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      
      // ── 1. Load from User-Specific Disk Cache (instant) ───────────────────
      _profileCompleted = prefs.getBool(_getCompletedKey(uid)) ?? false;
      final cachedProfileJson = prefs.getString(_getProfileKey(uid));
      if (cachedProfileJson != null) {
        try {
          profile = Map<String, String>.from(json.decode(cachedProfileJson));
        } catch (e) {
          debugPrint("Failed to decode cached profile: $e");
        }
      }

      // Notify immediately if we have ANY data (cached or flag)
      if (_profileCompleted || profile != null) {
        isLoading = false;
        notifyListeners();
      }

      // ── 2. Sync from Firestore (Truth) ────────────────────────────────────
      final codingProfile = await _profileService.getCodingProfile()
          .timeout(const Duration(seconds: 10));

      if (codingProfile != null) {
        profile = codingProfile;
        // Update user-specific cache
        await prefs.setString(_getProfileKey(uid), json.encode(profile));
        
        if (!_profileCompleted) {
          _profileCompleted = true;
          await prefs.setBool(_getCompletedKey(uid), true);
        }
      } else {
        // Doc might exist but 'profile' object missing
        try {
          final isComplete = await _profileService.isProfileCompleted();
          if (isComplete && !_profileCompleted) {
            _profileCompleted = true;
            await prefs.setBool(_getCompletedKey(uid), true);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Profile Provider Init error: $e");
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Save profile ──────────────────────────────────────────────────────────
  Future<void> saveProfile({
    String? name,
    String? profilePic,
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
    String? hackerrank,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

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
        "profilePic": profilePic ?? "",
      };

      // ── Persist to User-Specific Cache ───────────────────────────────────
      _profileCompleted = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_getCompletedKey(uid), true);
      await prefs.setString(_getProfileKey(uid), json.encode(profile));
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<void> updateFullProfile({
    String? name,
    String? profilePic,
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
    String? hackerrank,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

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

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getProfileKey(uid), json.encode(profile));
      if (!_profileCompleted) {
        _profileCompleted = true;
        await prefs.setBool(_getCompletedKey(uid), true);
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Upload Profile Picture ──────────────────────────────────────────────
  Future<String?> pickAndUploadImage(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final File? image = await _storageService.pickImage(source);
      if (image == null) return null;

      final String downloadUrl = await _storageService.uploadProfilePicture(image);

      // We DON'T update Firestore yet, just UI feedback or immediate update
      // Logic inside provider could update local profile object too
      if (profile != null) {
        final updatedProfile = Map<String, String>.from(profile!);
        updatedProfile["profilePic"] = downloadUrl;
        profile = updatedProfile;
        
        // Cache immediately
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_getProfileKey(uid), json.encode(profile));
      }
      
      return downloadUrl;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearProfile() async {
    // We only clear memory state. 
    // Disk keys are UID-isolated, so they can stay as "cache" for this user.
    // When next user logs in, initializeProfile() will load their own UID-specific keys.
    profile = null;
    _profileCompleted = false;
    error = null;
    notifyListeners();
  }
}
