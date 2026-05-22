import 'package:flutter/material.dart';
import '../theme/waffle_theme.dart';
import '../widgets/widgets.dart';

/// Orders screen with coming soon placeholder content
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaffleTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WaffleTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: WaffleTheme.spacingXL * 2),
            _buildComingSoonSection(),
            const SizedBox(height: WaffleTheme.spacingXL),
            _buildFeaturePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonSection() {
    return WaffleCard(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WaffleTheme.primary.withOpacity(0.2),
                  WaffleTheme.secondary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 50,
              color: WaffleTheme.primary,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          Text(
            'Orders Management Coming Soon',
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          Text(
            'We\'re working hard to bring you a comprehensive order management system.\nStay tuned for updates!',
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(WaffleTheme.spacingM),
            decoration: BoxDecoration(
              color: WaffleTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: WaffleTheme.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: WaffleTheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: WaffleTheme.spacingS),
                Text(
                  'Expected Release: Coming Soon',
                  style: TextStyle(
                    color: WaffleTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planned Features',
          style: TextStyle(
            color: WaffleTheme.textDark,
            fontSize: 22,
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
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              'Order Tracking',
              'Real-time order status updates',
              Icons.track_changes_outlined,
              WaffleTheme.primary,
            ),
            _buildFeatureCard(
              'Payment Processing',
              'Multiple payment methods support',
              Icons.payment_outlined,
              WaffleTheme.secondary,
            ),
            _buildFeatureCard(
              'Order History',
              'Complete order records and analytics',
              Icons.history_outlined,
              WaffleTheme.accent,
            ),
            _buildFeatureCard(
              'Customer Management',
              'Customer profiles and preferences',
              Icons.people_outline,
              WaffleTheme.success,
            ),
          ],
        ),
        const SizedBox(height: WaffleTheme.spacingXL),
        _buildNotificationCard(),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return WaffleCard(
      enableHover: false,
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
            title,
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            description,
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return WaffleCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WaffleTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: WaffleTheme.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: WaffleTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Notified',
                  style: TextStyle(
                    color: WaffleTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: WaffleTheme.spacingS),
                Text(
                  'We\'ll notify you when the orders management feature is ready to use.',
                  style: TextStyle(
                    color: WaffleTheme.textLight,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}