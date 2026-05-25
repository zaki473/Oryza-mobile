import 'package:flutter/material.dart';

class AppTheme {
  static const Color brand900 = Color(0xFF14532D);
  static const Color brand500 = Color(0xFF22C55E);
  static const Color bgGray = Color(0xFFF8FAFC);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgGray,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand500,
        primary: brand900,
        surface: Colors.white,
      ),
    );
  }
}
