import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  Map<String, String>? user;
  bool isLoading = false;
  String? error;

  // Check if user is authenticated
  bool get isAuthenticated => user != null;

  // Sign up
  Future<void> signUp(String email, String password, String name) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      user = await _service.signUp(email, password, name);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Login with email and password
  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      user = await _service.login(email, password);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      user = await _service.signInWithGoogle();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try {
      isLoading = true;
      notifyListeners();

      await _service.logout();
      user = null;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await _service.resetPassword(email);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  // Get current user from Firebase
  void loadCurrentUser() {
    try {
      user = _service.currentUser;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
