import 'package:flutter/material.dart';
import '../theme/WOFL_theme.dart';

/// A reusable button widget with WOFL-themed styling
/// Features hover animations and consistent WOFL shop aesthetics
class WOFLButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WOFLButtonType type;
  final bool isLoading;
  final double? width;

  const WOFLButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = WOFLButtonType.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  State<WOFLButton> createState() => _WOFLButtonState();
}

class _WOFLButtonState extends State<WOFLButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: WOFLTheme.fastAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case WOFLButtonType.primary:
        return _isHovered ? WOFLTheme.accent : WOFLTheme.primary;
      case WOFLButtonType.secondary:
        return _isHovered ? WOFLTheme.primary : WOFLTheme.secondary;
      case WOFLButtonType.outline:
        return _isHovered ? WOFLTheme.primary : Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case WOFLButtonType.primary:
      case WOFLButtonType.secondary:
        return Colors.white;
      case WOFLButtonType.outline:
        return _isHovered ? Colors.white : WOFLTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: WOFLTheme.fastAnimation,
              width: widget.width,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(WOFLTheme.buttonRadius),
                border: widget.type == WOFLButtonType.outline
                    ? Border.all(color: WOFLTheme.primary, width: 2)
                    : null,
                boxShadow: _isHovered && widget.type != WOFLButtonType.outline
                    ? [
                        BoxShadow(
                          color: WOFLTheme.accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(WOFLTheme.buttonRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WOFLTheme.spacingL,
                      vertical: WOFLTheme.spacingS,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _textColor,
                              ),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(widget.icon, color: _textColor, size: 18),
                          const SizedBox(width: WOFLTheme.spacingS),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum WOFLButtonType { primary, secondary, outline }
