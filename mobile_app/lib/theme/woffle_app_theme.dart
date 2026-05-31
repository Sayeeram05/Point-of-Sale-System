import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFFC46016); // Deep Waffle Orange
  static const Color primaryDark = Color(0xFF9B4714);
  static const Color primaryLight = Color(0xFFE69450); // Caramel Orange
  static const Color accent = Color(0xFFE28A46); // Golden Waffle

  // Background Colors
  static const Color backgroundColor = Color(0xFFFBFAEE); // Warm Cream
  static const Color surfaceColor = Color(0xFFE7DECD); // Soft Beige
  static const Color cardColor = Color(0xFFE7DECD);

  // Text Colors
  static const Color textPrimary = Color(0xFF60392F); // Dark Chocolate
  static const Color textSecondary = Color(0xFF93725E); // Coffee Brown
  static const Color textTertiary = Color(0xFFB79A82);

  // Status Colors
  static const Color success = Color(0xFFD89B3D); // Honey Gold
  static const Color warning = Color(0xFFE28A46);
  static const Color error = Color(0xFFC85A54); // Soft Red
  static const Color info = Color(0xFF8B6F52);

  // Border Colors
  static const Color borderLight = Color(0xFFD1BEA6); // Latte Beige
  static const Color borderMedium = Color(0xFFBCA88E);
  static const Color borderDark = Color(0xFF9E846A);
  static const Color borderColor = Color(0xFFD1BEA6); // Alias for borderLight

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowColorDark = Color(0x33000000);

  // Box Shadows - Aliased for easier access
  static const List<BoxShadow> elevationSmall = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFFB7752F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundColor, surfaceColor],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Typography - Enhanced for tablets with system fonts
  static TextStyle headingLarge(BuildContext context) => isMobileOnly(context)
      ? const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        )
      : const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          height: 1.2,
          letterSpacing: -0.5,
        );

  static TextStyle headingMedium(BuildContext context) => isMobileOnly(context)
      ? const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.3,
          letterSpacing: -0.3,
        )
      : const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.3,
          letterSpacing: -0.3,
        );

  static TextStyle headingSmall(BuildContext context) => isMobileOnly(context)
      ? const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
          letterSpacing: -0.2,
        )
      : const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.3,
          letterSpacing: -0.2,
        );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // Elevation Shadows
  static List<BoxShadow> get elevationLow => [
    const BoxShadow(color: shadowColor, blurRadius: 4, offset: Offset(0, 2)),
  ];

  static List<BoxShadow> get elevationMedium => [
    const BoxShadow(color: shadowColor, blurRadius: 8, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> get elevationHigh => [
    const BoxShadow(
      color: shadowColorDark,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
  );

  static ButtonStyle get successButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: success,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    filled: true,
    fillColor: surfaceColor,
  );

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: elevationLow,
    border: Border.all(color: borderLight),
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: elevationMedium,
  );

  // Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.blue,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    dividerColor: borderLight,
    textTheme: const TextTheme(
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelSmall: caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderLight),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: surfaceColor,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accent,
      surface: surfaceColor,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
  );

  // Responsive Breakpoints - Enhanced for better Android support
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  static const double largeDesktopBreakpoint = 1920;

  // Strict mobile detection - optimized for Android devices
  static const double strictMobileBreakpoint =
      600; // Phones up to max width of 600
  static const double smallTabletBreakpoint = 768; // Small tablets (7-8 inch)
  static const double largeTabletBreakpoint = 1024; // Large tablets (10+ inch)

  static bool isMobile(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide < mobileBreakpoint;
  }

  static bool isMobileOnly(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    // Tablets typically have shortest side >= 600
    return shortestSide >= 600 && shortestSide < 1024;
  }

  static bool isSmallTablet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    return shortestSide >= 600 && shortestSide < 768;
  }

  static bool isLargeTablet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    return shortestSide >= 768 && shortestSide < 1024;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < largeDesktopBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  static DeviceType getDeviceType(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    final longestSide = mediaQuery.size.longestSide;

    if (shortestSide < mobileBreakpoint) return DeviceType.mobile;
    if (shortestSide < largeTabletBreakpoint) return DeviceType.tablet;
    if (longestSide < largeDesktopBreakpoint) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  // Enhanced responsive Values with better Android optimization
  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? largeDesktop,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    if (shortestSide < mobileBreakpoint) return mobile;
    if (shortestSide < largeTabletBreakpoint) return tablet;
    if (mediaQuery.size.width < largeDesktopBreakpoint) return desktop;
    return largeDesktop ?? desktop;
  }

  // Enhanced responsive values with orientation support
  static double responsiveValueWithOrientation(
    BuildContext context, {
    required double mobilePortrait,
    required double mobileLandscape,
    required double tabletPortrait,
    required double tabletLandscape,
    required double desktop,
    double? largeDesktop,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    if (shortestSide < mobileBreakpoint) {
      return isLandscape ? mobileLandscape : mobilePortrait;
    }
    if (shortestSide < largeTabletBreakpoint) {
      return isLandscape ? tabletLandscape : tabletPortrait;
    }
    if (mediaQuery.size.width < largeDesktopBreakpoint) return desktop;
    return largeDesktop ?? desktop;
  }

  // Optimized text scaling for Android devices
  static double responsiveFontSize(
    BuildContext context,
    double baseFontSize, {
    double? mobileScale,
    double? tabletScale,
    double? desktopScale,
  }) {
    final deviceType = getDeviceType(context);
    final mediaQuery = MediaQuery.of(context);

    // Consider device pixel ratio for sharper text rendering
    final pixelRatio = mediaQuery.devicePixelRatio;
    double scaleAdjustment = 1.0;

    // Adjust for high-density displays (common on Android)
    if (pixelRatio > 2.5) {
      scaleAdjustment = 0.95; // Slightly smaller for very high DPI
    } else if (pixelRatio < 2.0) {
      scaleAdjustment = 1.05; // Slightly larger for lower DPI
    }

    switch (deviceType) {
      case DeviceType.mobile:
        return baseFontSize * (mobileScale ?? 1.0) * scaleAdjustment;
      case DeviceType.tablet:
        return baseFontSize * (tabletScale ?? 1.1) * scaleAdjustment;
      case DeviceType.desktop:
        return baseFontSize * (desktopScale ?? 1.2) * scaleAdjustment;
      case DeviceType.largeDesktop:
        return baseFontSize * (desktopScale ?? 1.3) * scaleAdjustment;
    }
  }

  // Padding/Margin helpers
  static EdgeInsets responsivePadding(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final value = responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return EdgeInsets.all(value);
  }

  static EdgeInsets responsiveSymmetricPadding(
    BuildContext context, {
    required double horizontalMobile,
    required double horizontalTablet,
    required double horizontalDesktop,
    required double verticalMobile,
    required double verticalTablet,
    required double verticalDesktop,
  }) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: horizontalMobile,
        tablet: horizontalTablet,
        desktop: horizontalDesktop,
      ),
      vertical: responsiveValue(
        context,
        mobile: verticalMobile,
        tablet: verticalTablet,
        desktop: verticalDesktop,
      ),
    );
  }

  // Enhanced grid helpers with orientation support
  static int responsiveGridCount(
    BuildContext context, {
    required int mobile,
    required int tablet,
    required int desktop,
    int? largeDesktop,
    // Optional landscape variants
    int? mobileLandscape,
    int? tabletLandscape,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        if (isLandscape && mobileLandscape != null) return mobileLandscape;
        return mobile;
      case DeviceType.tablet:
        if (isLandscape && tabletLandscape != null) return tabletLandscape;
        return tablet;
      case DeviceType.desktop:
        return desktop;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop;
    }
  }

  // Safe area helpers for Android devices
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Performance optimized spacing
  static double getOptimalSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return spacingSmall;
      case DeviceType.tablet:
        return spacingMedium;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return spacingLarge;
    }
  }

  // Touch target optimization for different devices
  static double getOptimalTouchTarget(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 44.0; // Material Design minimum
      case DeviceType.tablet:
        return 48.0; // Larger for tablet usage
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return 40.0; // Mouse interaction, can be smaller
    }
  }
}

// Enhanced device type enum for better Android support
enum DeviceType {
  mobile, // Phones < 600dp shortest side
  tablet, // Tablets 600-1024dp shortest side
  desktop, // Desktop/laptop screens
  largeDesktop, // Large desktop screens
}
