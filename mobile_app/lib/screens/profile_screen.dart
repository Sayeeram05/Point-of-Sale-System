import 'package:flutter/material.dart';
import '../widgets/pos_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFE67E22),
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Aarohi Sharma',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2B1A00),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '+91 98765 43210',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFFE67E22),
                    size: 18,
                  ),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Color(0xFFE67E22),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ProfileOptionTile(
              icon: Icons.person_rounded,
              title: 'Personal Information',
            ),
            const SizedBox(height: 12),
            const ProfileOptionTile(
              icon: Icons.location_on_rounded,
              title: 'Address Management',
            ),
            const SizedBox(height: 12),
            const ProfileOptionTile(
              icon: Icons.credit_card_rounded,
              title: 'Payment Methods',
            ),
            const SizedBox(height: 12),
            const ProfileOptionTile(
              icon: Icons.receipt_long_rounded,
              title: 'Order History',
            ),
            const SizedBox(height: 12),
            const ProfileOptionTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
            ),
            const SizedBox(height: 12),
            const ProfileOptionTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
            ),
            const SizedBox(height: 12),
            const ProfileOptionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              trailingColor: Color(0xFFD23E3E),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'App Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Color(0xFF9A6324)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
