import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ───────────────────────────────────────────────────────────
  // A more vibrant, modern "Cyber-Indigo" and "Neon-Cyan" palette
  static const Color primary = Color(0xFF7C3AED); // Vibrant Violet
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF06B6D4); // Modern Cyan
  static const Color accent = Color(0xFFF43F5E); // Rose/Crimson accent

  // Platform specific (kept consistent but slightly more vibrant)

  // Platform specific (kept consistent but slightly more vibrant)
  static const Color leetCodeYellow = Color(0xFFF97316); // Orange-600
  static const Color githubGrey = Color(0xFF4B5563);
  static const Color githubBlack = Color(0xFF0F172A);

  // ── Light Theme Palette ────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Dark Theme Palette ─────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF020617); // Ultimate Dark
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceDarkLighter = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF1E293B);

  // ── Shared Design Tokens ───────────────────────────────────────────────────
  static const double borderRadius = 24.0;
  static const double inputBorderRadius = 16.0;

  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF06B6D4), // Modern Cyan
        tertiary: const Color(0xFFF43F5E), // Rose/Crimson accent
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        outline: borderLight,
      ),
      scaffoldBackgroundColor: bgLight,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: textPrimaryLight,
          letterSpacing: -2,
        ),
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
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
          ),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(
          color: textSecondaryLight.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF06B6D4), // Modern Cyan
        tertiary: const Color(0xFFF43F5E), // Rose/Crimson accent
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        outline: borderDark,
      ),
      scaffoldBackgroundColor: bgDark,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: textPrimaryDark,
              letterSpacing: -2,
            ),
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
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 1,
            ),
          ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryDark),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputBorderRadius),
          ),
          elevation: 0,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDarkLighter,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(
          color: textSecondaryDark.withValues(alpha: 0.4),
          fontSize: 14,
        ),
      ),
    );
  }
}
