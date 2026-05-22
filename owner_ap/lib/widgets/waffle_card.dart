import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';

/// A reusable card widget with organic waffle-themed styling
/// Features gradient backgrounds, soft shadows, and smooth animations
class WaffleCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableHover;
  final double? width;
  final double? height;
  final bool useGradient;
  final Color? customColor;

  const WaffleCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.enableHover = true,
    this.width,
    this.height,
    this.useGradient = false,
    this.customColor,
  });

  @override
  State<WaffleCard> createState() => _WaffleCardState();
}

class _WaffleCardState extends State<WaffleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: WaffleTheme.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (!widget.enableHover) return;
    
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: widget.useGradient 
                    ? WaffleTheme.cardGradient
                    : null,
                  color: widget.useGradient 
                    ? null 
                    : (widget.customColor ?? WaffleTheme.cardBackground),
                  borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
                  border: Border.all(
                    color: _isHovered 
                      ? WaffleTheme.primary.withValues(alpha: 0.3)
                      : WaffleTheme.border,
                    width: _isHovered ? 2 : 1.5,
                  ),
                  boxShadow: [
                    // Base shadow
                    BoxShadow(
                      color: WaffleTheme.accent.withValues(alpha: 0.08),
                      blurRadius: 8 + (_elevationAnimation.value * 8),
                      offset: Offset(0, 2 + (_elevationAnimation.value * 4)),
                      spreadRadius: 1 + (_elevationAnimation.value * 2),
                    ),
                    // Elevated shadow when hovered
                    if (_isHovered)
                      BoxShadow(
                        color: WaffleTheme.primary.withValues(alpha: 0.12),
                        blurRadius: 20 + (_elevationAnimation.value * 12),
                        offset: Offset(0, 8 + (_elevationAnimation.value * 8)),
                        spreadRadius: 3 + (_elevationAnimation.value * 3),
                      ),
                    // Inner glow effect
                    if (_isHovered)
                      BoxShadow(
                        color: WaffleTheme.softOrange.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                        spreadRadius: -2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(WaffleTheme.cardRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      // Subtle inner gradient for depth
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: widget.padding ?? 
                          const EdgeInsets.all(WaffleTheme.spacingL),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}