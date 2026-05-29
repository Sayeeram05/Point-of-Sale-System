import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';

/// Main navigation shell with organic waffle-inspired design
/// Provides consistent navigation across all pages with artistic flair
class NavigationShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const NavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  bool _isMobile = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _isMobile = constraints.maxWidth < 768;
        
        return Scaffold(
          backgroundColor: WaffleTheme.background,
          body: Container(
            decoration: BoxDecoration(
              gradient: WaffleTheme.backgroundGradient,
            ),
            child: Column(
              children: [
                _buildNavBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 80, // Slightly taller for more organic feel
      decoration: BoxDecoration(
        gradient: WaffleTheme.primaryGradient,
        boxShadow: WaffleTheme.elevatedShadow,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: WaffleTheme.spacingL),
        child: Row(
          children: [
            _buildLogo(),
            const SizedBox(width: WaffleTheme.spacingXL),
            if (!_isMobile) ...[
              Expanded(child: _buildNavigationItems()),
              _buildProfileSection(),
            ] else ...[
              const Spacer(),
              _buildMobileMenuButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [WaffleTheme.creamWhite, WaffleTheme.softOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: WaffleTheme.accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant,
            color: WaffleTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: WaffleTheme.spacingM),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WAFFLE DAY',
              style: TextStyle(
                color: WaffleTheme.creamWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '@admin.dashboard',
              style: TextStyle(
                color: WaffleTheme.creamWhite.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationItems() {
    final items = [
      NavigationItem(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        index: 0,
      ),
      NavigationItem(
        label: 'Products',
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu_rounded,
        index: 1,
      ),
      NavigationItem(
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        index: 2,
      ),
    ];

    return Row(
      children: items.map((item) => _buildNavItem(item)).toList(),
    );
  }

  Widget _buildNavItem(NavigationItem item) {
    final isActive = widget.currentIndex == item.index;
    
    return Padding(
      padding: const EdgeInsets.only(right: WaffleTheme.spacingL),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigationChanged(item.index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: WaffleTheme.animationDuration,
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: WaffleTheme.spacingM,
              vertical: WaffleTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: isActive 
                ? WaffleTheme.creamWhite.withValues(alpha: 0.25) 
                : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isActive 
                ? Border.all(color: WaffleTheme.creamWhite.withValues(alpha: 0.3), width: 1)
                : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: WaffleTheme.creamWhite,
                  size: 22,
                ),
                const SizedBox(width: WaffleTheme.spacingS),
                Text(
                  item.label,
                  style: TextStyle(
                    color: WaffleTheme.creamWhite,
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: WaffleTheme.creamWhite.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WaffleTheme.creamWhite.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [WaffleTheme.waffleGold, WaffleTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_rounded,
              color: WaffleTheme.creamWhite,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Admin',
            style: TextStyle(
              color: WaffleTheme.creamWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenuButton() {
    return Container(
      decoration: BoxDecoration(
        color: WaffleTheme.creamWhite.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            _isMenuOpen = !_isMenuOpen;
          });
          _showMobileMenu();
        },
        icon: Icon(
          Icons.menu_rounded,
          color: WaffleTheme.creamWhite,
          size: 24,
        ),
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: WaffleTheme.cardGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: WaffleTheme.elevatedShadow,
        ),
        padding: const EdgeInsets.all(WaffleTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: WaffleTheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: WaffleTheme.spacingL),
            _buildMobileNavItem('Home', Icons.home_rounded, 0),
            _buildMobileNavItem('Products', Icons.restaurant_menu_rounded, 1),
            _buildMobileNavItem('Orders', Icons.receipt_long_rounded, 2),
            const SizedBox(height: WaffleTheme.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(String label, IconData icon, int index) {
    final isActive = widget.currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: WaffleTheme.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            widget.onNavigationChanged(index);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(WaffleTheme.spacingM),
            decoration: BoxDecoration(
              gradient: isActive 
                ? LinearGradient(
                    colors: [
                      WaffleTheme.primary.withValues(alpha: 0.1),
                      WaffleTheme.secondary.withValues(alpha: 0.05),
                    ],
                  )
                : null,
              borderRadius: BorderRadius.circular(20),
              border: isActive 
                ? Border.all(color: WaffleTheme.primary.withValues(alpha: 0.2))
                : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive 
                      ? WaffleTheme.primary 
                      : WaffleTheme.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? WaffleTheme.creamWhite : WaffleTheme.textDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: WaffleTheme.spacingM),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? WaffleTheme.primary : WaffleTheme.textDark,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.index,
  });
}