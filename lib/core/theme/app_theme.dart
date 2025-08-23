import 'package:flutter/material.dart';

class AppTheme {
  // Sophisticated dark color palette
  static const Color primaryBlack = Color(0xFF0D0D0D);
  static const Color secondaryBlack = Color(0xFF1C1C1E);
  static const Color accentGray = Color(0xFF2C2C2E);
  static const Color lightGray = Color(0xFF3A3A3C);

  // Refined accent colors - more muted and elegant
  static const Color accentOrange = Color(0xFFFF6B35); // Warm orange
  static const Color accentBlue = Color(0xFF4A90E2); // Muted blue
  static const Color accentGreen = Color(0xFF7ED321); // Fresh green
  static const Color accentPurple = Color(0xFF9013FE); // Deep purple
  static const Color accentRed = Color(0xFFE74C3C); // Classic red

  // Text colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFAAAAAA);
  static const Color mutedText = Color(0xFF666666);

  // Gradients - more subtle
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFFF8A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPurple, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [primaryBlack, secondaryBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      primaryColor: accentOrange,
      colorScheme: const ColorScheme.dark(
        primary: accentOrange,
        secondary: accentBlue,
        surface: secondaryBlack,
        background: primaryBlack,
        onPrimary: primaryText,
        onSecondary: primaryText,
        onSurface: primaryText,
        onBackground: primaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryText,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: primaryText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: mutedText,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      useMaterial3: true,
    );
  }
}
