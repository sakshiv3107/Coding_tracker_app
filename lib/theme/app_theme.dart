//  import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  // Dark Theme Colors
  static const darkPrimaryBg = Color(0xFF0D0F1A);
  static const darkSecondaryBg = Color(0xFF13162A);
  static const darkTertiaryBg = Color(0xFF1C2433);
  static const darkAccent = Color(0xFF0EA5E9);
  static const darkAccentSecondary = Color(0xFF00D9FF);
  static const darkTextPrimary = Color(0xFFE5E7EB);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF1F2937);

  // Light Theme Colors
  static const lightPrimaryBg = Color(0xFFFFFFFF);
  static const lightSecondaryBg = Color(0xFFF8FAFC);
  static const lightTertiaryBg = Color(0xFFF1F5F9);
  static const lightAccent = Color(0xFF0EA5E9);
  static const lightAccentSecondary = Color(0xFF8B5CF6);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightBorder = Color(0xFFE2E8F0);

  // Common Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const primary = Color(0xFF0EA5E9);

  // Platform Colors
  static const leetCodeYellow = Color(0xFFEF9F27);
  static const githubColor = Color(0xFF4078c0);
  static const codeforcesColor = Color(0xFFE24B4A);
  static const codechefColor = Color(0xFF7B68EE);
  static const hackerRankColor = Color(0xFF2EC866);

  // Additional Compatibility Tokens
  static const githubGrey = Color(0xFF24292E);
  static const githubBlack = Color(0xFF0D1117);
  static const primaryLight = Color(0xFF0EA5E9); 
  static const secondary = Color(0xFF00D9FF); 

  // Glass Effect Decoration
  static BoxDecoration glassCardDark({
    BorderRadius? borderRadius,
    double borderOpacity = 0.1,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkTertiaryBg.withOpacity(0.7),
          darkSecondaryBg.withOpacity(0.5),
        ],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: darkAccent.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glassCardLight({
    BorderRadius? borderRadius,
    double borderOpacity = 0.15,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.8),
          lightSecondaryBg.withOpacity(0.6),
        ],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: lightAccent.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: lightAccent.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ThemeData Objects
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkPrimaryBg,
    primaryColor: darkAccent,
    colorScheme: const ColorScheme.dark(
      primary: darkAccent,
      secondary: darkAccentSecondary,
      surface: darkSecondaryBg,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: darkSecondaryBg,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimaryBg,
      
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: darkTextPrimary),
      bodyMedium: TextStyle(color: darkTextSecondary),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightPrimaryBg,
    primaryColor: lightAccent,
    colorScheme: const ColorScheme.light(
      primary: lightAccent,
      secondary: lightAccentSecondary,
      surface: lightTertiaryBg,
      error: error,
    ),
    cardTheme: CardThemeData(
      color: lightTertiaryBg,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightPrimaryBg,
      
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: lightTextPrimary),
      bodyMedium: TextStyle(color: lightTextSecondary),
    ),
  );
}


