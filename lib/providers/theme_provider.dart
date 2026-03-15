import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_themeKey);
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    String mode;
    if (_themeMode == ThemeMode.dark) {
      mode = 'dark';
    } else if (_themeMode == ThemeMode.light) {
      mode = 'light';
    } else {
      mode = 'system';
    }
    await prefs.setString(_themeKey, mode);
  }
}
