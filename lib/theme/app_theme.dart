import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2A9D8F);
  static const Color accent = Color(0xFFE9C46A);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF264653);
  static const Color lightGrey = Color(0xFFF4F4F4);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
    ),
  );
}
