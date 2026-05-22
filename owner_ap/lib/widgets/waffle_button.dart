import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';

/// A reusable button widget with waffle-themed styling
/// Features hover animations and consistent waffle shop aesthetics
class WaffleButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WaffleButtonType type;
  final bool isLoading;
  final double? width;

  const WaffleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = WaffleButtonType.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  State<WaffleButton> createState() => _WaffleButtonState();
}

class _WaffleButtonState extends State<WaffleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: WaffleTheme.fastAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
      case WaffleButtonType.primary:
        return _isHovered ? WaffleTheme.accent : WaffleTheme.primary;
      case WaffleButtonType.secondary:
        return _isHovered ? WaffleTheme.primary : WaffleTheme.secondary;
      case WaffleButtonType.outline:
        return _isHovered ? WaffleTheme.primary : Colors.transparent;
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case WaffleButtonType.primary:
      case WaffleButtonType.secondary:
        return Colors.white;
      case WaffleButtonType.outline:
        return _isHovered ? Colors.white : WaffleTheme.primary;
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
              duration: WaffleTheme.fastAnimation,
              width: widget.width,
              height: 48,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                border: widget.type == WaffleButtonType.outline
                    ? Border.all(color: WaffleTheme.primary, width: 2)
                    : null,
                boxShadow: _isHovered && widget.type != WaffleButtonType.outline
                    ? [
                        BoxShadow(
                          color: WaffleTheme.accent.withOpacity(0.3),
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
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WaffleTheme.spacingL,
                      vertical: WaffleTheme.spacingM,
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
                              valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: _textColor,
                            size: 18,
                          ),
                          const SizedBox(width: WaffleTheme.spacingS),
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

enum WaffleButtonType {
  primary,
  secondary,
  outline,
}