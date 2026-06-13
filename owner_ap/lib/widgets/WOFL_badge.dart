import 'package:flutter/material.dart';
import '../theme/WOFL_theme.dart';

/// A reusable badge widget with WOFL-themed styling
/// Perfect for displaying prices, counts, and status indicators
class WOFLBadge extends StatelessWidget {
  final String text;
  final WOFLBadgeType type;
  final IconData? icon;
  final bool isSmall;

  const WOFLBadge({
    super.key,
    required this.text,
    this.type = WOFLBadgeType.price,
    this.icon,
    this.isSmall = false,
  });

  /// Factory constructor for price badges
  factory WOFLBadge.price(double price, {bool isSmall = false}) {
    return WOFLBadge(
      text: '₹${price.toStringAsFixed(0)}',
      type: WOFLBadgeType.price,
      isSmall: isSmall,
    );
  }

  /// Factory constructor for count badges
  factory WOFLBadge.count(int count, {bool isSmall = false}) {
    return WOFLBadge(
      text: count.toString(),
      type: WOFLBadgeType.count,
      isSmall: isSmall,
    );
  }

  /// Factory constructor for status badges
  factory WOFLBadge.status(String status, {IconData? icon, bool isSmall = false}) {
    return WOFLBadge(
      text: status,
      type: WOFLBadgeType.status,
      icon: icon,
      isSmall: isSmall,
    );
  }

  Color get _backgroundColor {
    switch (type) {
      case WOFLBadgeType.price:
        return WOFLTheme.secondary;
      case WOFLBadgeType.count:
        return WOFLTheme.primary;
      case WOFLBadgeType.status:
        return WOFLTheme.accent;
      case WOFLBadgeType.success:
        return WOFLTheme.success;
      case WOFLBadgeType.error:
        return WOFLTheme.error;
      case WOFLBadgeType.warning:
        return WOFLTheme.warning;
    }
  }

  Color get _textColor {
    switch (type) {
      case WOFLBadgeType.price:
      case WOFLBadgeType.count:
      case WOFLBadgeType.status:
        return Colors.white;
      case WOFLBadgeType.success:
      case WOFLBadgeType.error:
        return Colors.white;
      case WOFLBadgeType.warning:
        return WOFLTheme.textDark;
    }
  }

  double get _fontSize => isSmall ? 10 : 12;
  double get _padding => isSmall ? WOFLTheme.spacingS : WOFLTheme.spacingM;
  double get _iconSize => isSmall ? 12 : 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _padding,
        vertical: isSmall ? WOFLTheme.spacingXS : WOFLTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(WOFLTheme.badgeRadius),
        boxShadow: [
          BoxShadow(
            color: _backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: _textColor,
              size: _iconSize,
            ),
            SizedBox(width: isSmall ? 2 : 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum WOFLBadgeType {
  price,
  count,
  status,
  success,
  error,
  warning,
}