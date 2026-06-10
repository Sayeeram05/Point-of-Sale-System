import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';

/// A reusable badge widget with waffle-themed styling
/// Perfect for displaying prices, counts, and status indicators
class WaffleBadge extends StatelessWidget {
  final String text;
  final WaffleBadgeType type;
  final IconData? icon;
  final bool isSmall;

  const WaffleBadge({
    super.key,
    required this.text,
    this.type = WaffleBadgeType.price,
    this.icon,
    this.isSmall = false,
  });

  /// Factory constructor for price badges
  factory WaffleBadge.price(double price, {bool isSmall = false}) {
    return WaffleBadge(
      text: '₹${price.toStringAsFixed(0)}',
      type: WaffleBadgeType.price,
      isSmall: isSmall,
    );
  }

  /// Factory constructor for count badges
  factory WaffleBadge.count(int count, {bool isSmall = false}) {
    return WaffleBadge(
      text: count.toString(),
      type: WaffleBadgeType.count,
      isSmall: isSmall,
    );
  }

  /// Factory constructor for status badges
  factory WaffleBadge.status(String status, {IconData? icon, bool isSmall = false}) {
    return WaffleBadge(
      text: status,
      type: WaffleBadgeType.status,
      icon: icon,
      isSmall: isSmall,
    );
  }

  Color get _backgroundColor {
    switch (type) {
      case WaffleBadgeType.price:
        return WaffleTheme.secondary;
      case WaffleBadgeType.count:
        return WaffleTheme.primary;
      case WaffleBadgeType.status:
        return WaffleTheme.accent;
      case WaffleBadgeType.success:
        return WaffleTheme.success;
      case WaffleBadgeType.error:
        return WaffleTheme.error;
      case WaffleBadgeType.warning:
        return WaffleTheme.warning;
    }
  }

  Color get _textColor {
    switch (type) {
      case WaffleBadgeType.price:
      case WaffleBadgeType.count:
      case WaffleBadgeType.status:
        return Colors.white;
      case WaffleBadgeType.success:
      case WaffleBadgeType.error:
        return Colors.white;
      case WaffleBadgeType.warning:
        return WaffleTheme.textDark;
    }
  }

  double get _fontSize => isSmall ? 10 : 12;
  double get _padding => isSmall ? WaffleTheme.spacingS : WaffleTheme.spacingM;
  double get _iconSize => isSmall ? 12 : 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _padding,
        vertical: isSmall ? WaffleTheme.spacingXS : WaffleTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(WaffleTheme.badgeRadius),
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

enum WaffleBadgeType {
  price,
  count,
  status,
  success,
  error,
  warning,
}