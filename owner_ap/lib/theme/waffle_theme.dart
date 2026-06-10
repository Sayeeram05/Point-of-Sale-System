import 'package:flutter/material.dart';

/// Waffle Shop themed color palette and styling constants
/// Inspired by organic waffle day design with warm, artistic aesthetic
class WaffleTheme {
  // Color Palette - Organic waffle-inspired colors from the design
  static const Color background = Color(0xFFFDF8F0); // Soft cream background
  static const Color primary = Color(0xFFE67E22); // Warm orange from design
  static const Color secondary = Color(0xFFF39C12); // Golden orange accent
  static const Color accent = Color(0xFFD35400); // Deeper orange
  static const Color cardBackground = Color(0xFFFEFBF6); // Very light cream
  static const Color border = Color(0xFFE8DCC6); // Soft beige border
  static const Color textDark = Color(0xFF8B4513); // Warm brown text
  
  // Additional colors for better contrast and accessibility
  static const Color textLight = Color(0xFFB8860B); // Golden brown
  static const Color textMuted = Color(0xFFD2B48C); // Light tan
  static const Color success = Color(0xFF27AE60); // Natural green
  static const Color error = Color(0xFFE74C3C); // Warm red
  static const Color warning = Color(0xFFF39C12); // Orange warning
  
  // Organic design elements
  static const Color waffleGold = Color(0xFFDAA520); // Waffle color
  static const Color creamWhite = Color(0xFFFFFAF0); // Cream white
  static const Color softOrange = Color(0xFFFFE4B5); // Moccasin
  
  // Styling Constants - More organic and rounded
  static const double cardRadius = 24.0; // More rounded
  static const double buttonRadius = 20.0; // Softer buttons
  static const double badgeRadius = 16.0; // Rounded badges
  
  // Animation Durations - Smoother animations
  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Duration fastAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 600);
  
  // Spacing
  static const double spacingXS = 6.0;
  static const double spacingS = 12.0;
  static const double spacingM = 20.0;
  static const double spacingL = 28.0;
  static const double spacingXL = 36.0;
  
  // Organic shadows - softer and more natural
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 4,
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 3,
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: 6,
    ),
  ];
  
  // Gradient definitions for organic feel
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get cardGradient => LinearGradient(
    colors: [cardBackground, creamWhite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get backgroundGradient => LinearGradient(
    colors: [background, softOrange.withValues(alpha: 0.3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Material 3 Theme Configuration with organic waffle design
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: cardBackground,
        error: error,
        onPrimary: creamWhite,
        onSecondary: textDark,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border, width: 1.5),
        ),
        shadowColor: accent.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: creamWhite,
          elevation: 4,
          shadowColor: accent.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: creamWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: creamWhite,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textDark,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: textDark,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          color: textDark,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          color: textDark,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textLight,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: textLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}