import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  Map<String, String>? user;
  bool isLoading = false;
  String? error;

  Future login(String password, String email) async {
    try {
      isLoading = true;
      notifyListeners();

      user = await _service.login(password, email);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future logout() async {
    await _service.logout();
    user = null;
    notifyListeners();
  }
}
