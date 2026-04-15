import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'primary_color_index';
  
  ThemeMode _themeMode = ThemeMode.system;
  int _colorIndex = 0;

  ThemeMode get themeMode => _themeMode;
  
  static const List<Color> availableColors = [
    Color(0xFF7C3AED), // Vibrant Violet (Default)
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
  ];

  Color get primaryColor => availableColors[_colorIndex];
  int get colorIndex => _colorIndex;

  ThemeProvider() {
    _loadPreferences();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void setPrimaryColor(int index) {
    if (index >= 0 && index < availableColors.length) {
      _colorIndex = index;
      _savePreferences();
      notifyListeners();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final mode = prefs.getString(_themeKey);
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load color
    _colorIndex = prefs.getInt(_colorKey) ?? 0;
    
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save theme
    String mode;
    if (_themeMode == ThemeMode.dark) {
      mode = 'dark';
    } else if (_themeMode == ThemeMode.light) {
      mode = 'light';
    } else {
      mode = 'system';
    }
    await prefs.setString(_themeKey, mode);
    
    // Save color
    await prefs.setInt(_colorKey, _colorIndex);
  }
}


