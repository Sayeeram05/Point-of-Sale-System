import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';
import '../widgets/widgets.dart';

/// Home screen with welcome content and placeholder for future features
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaffleTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WaffleTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: WaffleTheme.spacingXL),
            _buildPlaceholderSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [WaffleTheme.primary, WaffleTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: WaffleTheme.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Waffle Shop Admin',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: WaffleTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: WaffleTheme.spacingS),
                    Text(
                      'Manage your waffle shop operations with ease',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: WaffleTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(WaffleTheme.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WaffleTheme.secondary.withOpacity(0.1),
                  WaffleTheme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: WaffleTheme.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: WaffleTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: WaffleTheme.spacingM),
                Expanded(
                  child: Text(
                    'Navigate to Products to manage your waffle categories and menu items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WaffleTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: WaffleTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: WaffleTheme.spacingL),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: WaffleTheme.spacingL,
          mainAxisSpacing: WaffleTheme.spacingL,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Categories',
              '4',
              Icons.category_outlined,
              WaffleTheme.primary,
            ),
            _buildStatCard(
              'Total Products',
              '8',
              Icons.restaurant_menu_outlined,
              WaffleTheme.secondary,
            ),
            _buildStatCard(
              'Orders Today',
              'Coming Soon',
              Icons.receipt_long_outlined,
              WaffleTheme.accent,
            ),
            _buildStatCard(
              'Revenue',
              'Coming Soon',
              Icons.attach_money_outlined,
              WaffleTheme.success,
            ),
          ],
        ),
        const SizedBox(height: WaffleTheme.spacingXL),
        _buildWaffleIllustration(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return WaffleCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          Text(
            value,
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            title,
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWaffleIllustration() {
    return WaffleCard(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WaffleTheme.secondary.withOpacity(0.2),
                  WaffleTheme.primary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.restaurant,
              size: 60,
              color: WaffleTheme.primary,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          Text(
            'Waffle Shop Management',
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Your one-stop solution for managing waffle shop operations.\nMore features coming soon!',
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}