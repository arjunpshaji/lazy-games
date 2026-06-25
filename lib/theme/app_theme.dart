import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette Tokens
  static const Color darkBackground = Color(0xFF121414); // surface-dim / background
  static const Color cardBackground = Color(0xFF1A1C1C); // surface-container-low
  
  // Neon accents
  static const Color neonCyan = Color(0xFF00EEFC); // Vibrant Cyan (Secondary)
  static const Color neonViolet = Color(0xFF7000FF); // Electric Purple (Primary)
  static const Color neonGreen = Color(0xFF00EEFC); // Success feedback uses Cyan
  static const Color neonOrange = Color(0xFFFF9500); // Vibrant orange
  static const Color neonPink = Color(0xFFFF006B); // saturated Magenta (Feedback Error)
  
  static const Color textPrimary = Color(0xFFE2E2E2); // on-surface
  static const Color textSecondary = Color(0xFF958DA3); // outline / secondary text

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

  // Typography Token Helpers (Plus Jakarta Sans)
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.96,
    color: textPrimary,
  );

  static TextStyle get displayLgMobile => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.72,
    color: textPrimary,
  );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get labelCaps => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: textPrimary,
  );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonViolet,
        secondary: neonCyan,
        surface: cardBackground,
        error: neonPink,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
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

  static BoxDecoration glassBorderDecoration({
    required Color color,
    double borderRadius = 16.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withOpacity(0.4), width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.12),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
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
}
