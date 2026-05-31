import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AppPerformance {
  static const bool enableDebugLogging = false;
  static const bool enablePerformanceLogging = false;

  // Animation durations optimized for performance
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 350);

  // List/Grid performance settings
  static const double cacheExtent = 100.0;
  static const int maxCacheObjects = 200;
  static const Duration stalePeriod = Duration(days: 7);

  // Image optimization settings
  static const int maxImageCacheWidth = 1024;
  static const int maxImageCacheHeight = 1024;
  static const FilterQuality imageFilterQuality = FilterQuality.medium;

  // Text scaling factors for different devices
  static const double mobileTextScale = 0.95;
  static const double tabletTextScale = 1.15;
  static const double desktopTextScale = 1.1;

  // Initialize performance optimizations
  static void initialize() {
    if (kReleaseMode) {
      // Disable debug overlays in release mode
      debugPaintSizeEnabled = false;
      debugRepaintRainbowEnabled = false;
      debugRepaintTextRainbowEnabled = false;

      // Optimize rendering performance
      debugProfileBuildsEnabled = false;
      debugProfilePaintsEnabled = false;
    }
  }

  // Get optimized scroll physics based on platform
  static ScrollPhysics getOptimizedScrollPhysics() {
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  // Get optimized list view settings
  static Map<String, dynamic> getOptimizedListSettings() {
    return {
      'cacheExtent': cacheExtent,
      'addAutomaticKeepAlives': false,
      'addRepaintBoundaries': true,
      'addSemanticIndexes': false,
    };
  }

  // Get optimized grid view settings
  static Map<String, dynamic> getOptimizedGridSettings() {
    return {
      'cacheExtent': cacheExtent,
      'addAutomaticKeepAlives': false,
      'addRepaintBoundaries': true,
      'addSemanticIndexes': false,
    };
  }

  // Wrap widget with performance optimizations
  static Widget withPerformanceOptimizations(
    Widget child, {
    bool repaintBoundary = true,
  }) {
    if (repaintBoundary) {
      return RepaintBoundary(child: child);
    }
    return child;
  }

  // Get text scale factor based on device size
  static double getTextScaleFactor(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide < 600) return mobileTextScale;
    if (shortestSide < 1024) return tabletTextScale;
    return desktopTextScale;
  }

  // Memory-efficient spacer widgets
  static const SizedBox vSpace4 = SizedBox(height: 4);
  static const SizedBox vSpace8 = SizedBox(height: 8);
  static const SizedBox vSpace12 = SizedBox(height: 12);
  static const SizedBox vSpace16 = SizedBox(height: 16);
  static const SizedBox vSpace20 = SizedBox(height: 20);
  static const SizedBox vSpace24 = SizedBox(height: 24);

  static const SizedBox hSpace4 = SizedBox(width: 4);
  static const SizedBox hSpace8 = SizedBox(width: 8);
  static const SizedBox hSpace12 = SizedBox(width: 12);
  static const SizedBox hSpace16 = SizedBox(width: 16);
  static const SizedBox hSpace20 = SizedBox(width: 20);
  static const SizedBox hSpace24 = SizedBox(width: 24);
}
