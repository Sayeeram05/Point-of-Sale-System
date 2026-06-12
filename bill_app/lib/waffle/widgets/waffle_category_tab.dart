import 'package:flutter/material.dart';
import '../themes/WOFL_theme.dart';

class WOFLCategoryTab extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const WOFLCategoryTab({
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
          color: selected ? WOFLTheme.primaryColor : WOFLTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? WOFLTheme.primaryColor
                : WOFLTheme.borderColor,
          ),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: selected ? Colors.white : WOFLTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
