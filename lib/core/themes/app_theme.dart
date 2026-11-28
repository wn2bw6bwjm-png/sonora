import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF3700B3);
  static const Color primaryDark = Color(0xFF3700B3);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color onBackground = Color(0xFFE0E0E0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onPrimaryVariant = Color(0xFFB39DDB);
  static const Color onSecondaryVariant = Color(0xFF8C7AA9);
  static const Color onSurfaceVariant = Color(0xFFC5C6C7);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC5C6C7);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}