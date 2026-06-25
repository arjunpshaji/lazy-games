import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0D0E15);
  static const Color cardBackground = Color(0xFF161825);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonViolet = Color(0xFFC000FF);
  static const Color neonGreen = Color(0xFF00FF66);
  static const Color neonOrange = Color(0xFFFF5E00);
  static const Color neonPink = Color(0xFFFF007F);

  // Redesigned Modal Green Palette (091413 / 285A48 / 408A71 / B0E4CC)
  static const Color forestDark = Color(0xFF091413);
  static const Color forestDeep = Color(0xFF285A48);
  static const Color forestAccent = Color(0xFF408A71);
  static const Color forestMint = Color(0xFFB0E4CC);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9095A9);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonViolet, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonPink, neonOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [neonGreen, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Fredoka',
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonViolet,
        surface: cardBackground,
        error: neonPink,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static BoxDecoration neonBorderDecoration({
    required Color color,
    double borderRadius = 16.0,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withOpacity(0.8), width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static BoxDecoration glassDecoration({
    required double borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }
}
