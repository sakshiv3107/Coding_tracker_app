import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'stats_provider.dart';
import 'profile_provider.dart';
// import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription<User?>? _authSubscription;

  AuthProvider() {
    // Listen for real-time authentication state changes (e.g., token expiration, revocation)
    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((User? firebaseUser) {
      if (firebaseUser == null && user != null) {
        // User's token expired or session was revoked remotely
        user = null;
        isNewUser = false;
        _service.clearAuthData();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Map<String, String>? user;
  bool isLoading = false;
  String? error;

  /// True when the user just registered (email or Google new user).
  /// Used by AuthWrapper / screens to decide whether to show Profile Setup.
  bool isNewUser = false;

  // Check if user is authenticated
  bool get isAuthenticated => user != null;

  void clearError() {
    error = null;
    notifyListeners();
  }

  // Check if session exists on app startup
  Future<void> checkLoginStatus() async {
    isLoading = true;
    notifyListeners();
    
    try {
      // 1. Check secure storage first
      final persistedUser = await _service.getPersistedUser();
      if (persistedUser != null) {
        user = persistedUser;
        // Optionally, check if it's still locally valid with Firebase
        if (_service.currentFirebaseUser != null) {
           isNewUser = false;
        }
      } else {
        // Fallback to Firebase current user
        final fUser = _service.currentUser;
        if (fUser != null) {
           user = fUser;
           isNewUser = false;
        }
      }
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }

  // Sign up
  Future<bool> signUp(String email, String password, String name) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _service.signUp(email, password, name);
      user = {
        "uid": result["uid"] as String,
        "email": result["email"] as String,
        "name": result["name"] as String,
      };
      isNewUser = true;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _service.login(email, password);
      user = {
        "uid": result["uid"] as String,
        "email": result["email"] as String,
        "name": result["name"] as String,
      };
      isNewUser = false;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Google Sign In — with improved error handling
  Future<bool> signInWithGoogle() async {
    // Double-click guard: if already loading, ignore
    if (isLoading) return false;

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _service.signInWithGoogle();
      user = {
        "uid": result["uid"] as String,
        "email": result["email"] as String,
        "name": result["name"] as String,
      };
      isNewUser = result["isNewUser"] as bool? ?? false;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');

      // Don't show error if user just cancelled the sign-in dialog
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        error = null;
      } else {
        error = msg;
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout({
    required StatsProvider statsProvider,
    required ProfileProvider profileProvider,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. Clear local session flag immediately to trigger instant redirect in AuthWrapper
      user = null;
      isNewUser = false;
      notifyListeners(); 

      // 2. Perform background cleanup
      // Clear memory AND disk caches so no data leakage between logins.
      await Future.wait([
        statsProvider.clearDiskCache(),
        profileProvider.clearProfile(),
        _service.logout(),
      ]);

      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      debugPrint("Logout cleanup error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await _service.resetPassword(email);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get current user from Firebase
  void loadCurrentUser() {
    try {
      user = _service.currentUser;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Update name in local state
  void updateName(String newName) {
    if (user != null) {
      user!['name'] = newName;
      notifyListeners();
    }
  }
}


