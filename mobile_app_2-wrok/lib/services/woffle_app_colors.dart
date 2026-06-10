import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3); // Material Blue
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);

  // Default colors for orders - Blue as the first/default
  static const Color defaultBlue = Color(0xFF2196F3); // Material Blue

  // Order card colors
  static final List<Color> orderColors = [
    defaultBlue, // Default blue as first color
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFF96CEB4),
    const Color(0xFFFECF3E),
    const Color(0xFFFF9FF3),
    const Color(0xFF54A0FF),
    const Color(0xFF5F27CD),
  ];

  // Get color from hex string
  static Color fromHex(String hexString) {
    // Remove # if present
    final hex = hexString.replaceFirst('#', '');

    // Ensure we have a valid hex string
    if (hex.length == 6) {
      // Convert 6-digit hex to Color
      final int value = int.parse('FF$hex', radix: 16);
      return Color(value);
    } else if (hex.length == 8) {
      // Convert 8-digit hex to Color (with alpha)
      final int value = int.parse(hex, radix: 16);
      return Color(value);
    } else {
      // Return a default blue color if invalid
      return const Color(0xFF2196F3);
    }
  }

  // Convert color to hex string
  static String toHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
