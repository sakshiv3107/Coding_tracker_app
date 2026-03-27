import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'stats_provider.dart';
import 'profile_provider.dart';
import 'package:provider/provider.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

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

  // Google Sign In
  Future<bool> signInWithGoogle() async {
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
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      // Clear memory caches in other providers first
      Provider.of<StatsProvider>(context, listen: false).clearAllCache();
      Provider.of<ProfileProvider>(context, listen: false).clearProfile();

      await _service.logout();
      user = null;
      error = null;
      isNewUser = false;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
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
