import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Premium Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color accent = Color(0xFFF59E0B); // Amber
  
  static const Color leetCodeYellow = Color(0xFFFFA116);
  static const Color githubBlack = Color(0xFF24292E);
  static const Color githubGrey = Color(0xFF6E7681);
  static const Color githubBlue = Color(0xFF0366D6);
  
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF020617); // Deeper dark
  
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF0F172A); // Slower dark
  static const Color surfaceDarkLighter = Color(0xFF1E293B);
  
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimaryLight,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimaryLight,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textPrimaryLight,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textSecondaryLight,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
      ),
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimaryDark,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondaryDark,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textPrimaryDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textSecondaryDark,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryLight,
          letterSpacing: 1,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 12,
          shadowColor: primary.withOpacity(0.3),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDarkLighter,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(
          color: textSecondaryDark.withOpacity(0.5),
          fontSize: 14,
        ),
      ),
    );
  }
}
