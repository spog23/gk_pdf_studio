import 'package:flutter/material.dart';

final class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF4FC3F7),
      secondary: Color(0xFFFFB74D),
      surface: Color(0xFF111418),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B0D10),
      dividerColor: const Color(0xFF1D232B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0D10),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111418),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1D232B)),
        ),
      ),
    );
  }
}
