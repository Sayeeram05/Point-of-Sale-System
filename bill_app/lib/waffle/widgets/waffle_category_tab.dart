import 'package:flutter/material.dart';
import '../themes/waffle_theme.dart';

class WaffleCategoryTab extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const WaffleCategoryTab({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? WaffleTheme.primaryColor : WaffleTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? WaffleTheme.primaryColor
                : WaffleTheme.borderColor,
          ),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: selected ? Colors.white : WaffleTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
