import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/app_colors.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback onEmojiColorTap;
  final VoidCallback? onOrderDeleted;

  const OrderCard({
    super.key,
    required this.order,
    required this.index,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    required this.onEmojiColorTap,
    this.onOrderDeleted,
  });

  @override
  Widget build(BuildContext context) {
    // Clean, minimal values for perfect UI
    const cardMargin = 2.0;
    const cardPadding = 6.0;

    // Different styling for completed vs pending orders
    final Color baseColor;
    final Color cardColor;
    final Color borderColor;

    if (order.completed) {
      // Completed orders: white/grey styling
      baseColor = Colors.grey[600]!;
      cardColor = Colors.grey[50]!;
      borderColor = Colors.grey[300]!;
    } else {
      // Pending orders: owner-selected color styling
      final ownerColor = AppColors.fromHex(order.color);
      baseColor = ownerColor;
      cardColor = ownerColor.withValues(alpha: 0.13);
      borderColor = ownerColor.withValues(alpha: 0.22);
    }

    return Container(
      margin: const EdgeInsets.all(cardMargin),
      child: Material(
        elevation: order.completed
            ? 0.2
            : 0.5, // Less elevation for completed orders
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          onDoubleTap: onDoubleTap != null ? () => onDoubleTap!() : null,
          onLongPress: onLongPress != null ? () => onLongPress!() : null,
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: order.completed
                ? 0.7
                : 1.0, // Make completed orders more transparent
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cardColor,
                border: Border.all(
                  color: borderColor,
                  width: order.completed
                      ? 1.5
                      : 0.8, // Thicker border for completed orders
                  style: BorderStyle.solid,
                ),
                boxShadow: [
                  BoxShadow(
                    color: order.completed
                        ? Colors.grey.withValues(alpha: 0.15)
                        : baseColor.withValues(alpha: 0.08),
                    spreadRadius: 0,
                    blurRadius: order.completed ? 1 : 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completed order banner
                  if (order.completed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ORDER COMPLETED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Clean, single header row for all orientations
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Emoji and color indicator
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: order.completed ? null : onEmojiColorTap,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.completed
                                    ? Colors.grey[200]
                                    : baseColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: order.completed
                                      ? Colors.grey[300]!
                                      : baseColor.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    order.completed
                                        ? '✅'
                                        : (order.emoji.isNotEmpty
                                              ? order.emoji
                                              : '🍦'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: order.completed
                                          ? Colors.grey[600]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: order.completed
                                          ? Colors.grey[400]
                                          : baseColor,
                                      shape: BoxShape.circle,
                                      boxShadow: order.completed
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: baseColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 3,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Order number and status - more flexible layout
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  '#$index',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: order.completed
                                        ? Colors.grey[600]
                                        : baseColor,
                                    decoration: order.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Payment Method Badge
                              _buildPaymentMethodBadge(order, baseColor),
                            ],
                          ),
                        ),

                        // Items count with icon + number (supports 3-digit)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 10,
                                  color: order.completed
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${order.items.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: order.completed
                                        ? Colors.grey[500]
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: order.completed
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                order.completed ? 'DONE' : 'PENDING',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                  color: order.completed
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 3),

                        // Delete button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Text('Delete Order'),
                                  content: Text(
                                    'Are you sure you want to delete Order #$index?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ApiService.deleteOrder(order.orderId);
                                  if (context.mounted) {
                                    if (onOrderDeleted != null) {
                                      onOrderDeleted!();
                                    }
                                  }
                                } catch (e) {
                                  // Error notification removed per user request
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: order.completed
                                    ? Colors.grey[200]
                                    : Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: order.completed
                                      ? Colors.grey[400]!
                                      : Colors.red.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: order.completed
                                    ? Colors.grey[500]
                                    : Colors.red.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Clean items section with better spacing
                  if (order.items.isNotEmpty) ...[
                    // Items list
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: order.completed
                            ? Colors.grey[100]
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1.5,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: order.completed
                                            ? Colors.grey[600]
                                            : Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                        decoration: order.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      'x${item.pieces}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: order.completed
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                        decoration: order.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: order.completed
                                            ? Colors.grey[600]
                                            : Colors.grey[800],
                                        decoration: order.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total section
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: order.completed
                                  ? Colors.grey[600]
                                  : Colors.grey[700],
                              decoration: order.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: order.completed
                                  ? Colors.grey[200]
                                  : baseColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₹${order.totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: order.completed
                                    ? Colors.grey[700]
                                    : baseColor,
                                decoration: order.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a highlighted payment method badge based on order payment details
  Widget _buildPaymentMethodBadge(Order order, Color baseColor) {
    // Determine payment method based on upi and cash amounts
    String paymentMethod;
    Color badgeColor;
    IconData? icon;

    final upiAmount = double.tryParse(order.upiAmount) ?? 0.0;
    final cashAmount = double.tryParse(order.cashAmount) ?? 0.0;

    if (upiAmount > 0 && cashAmount > 0) {
      paymentMethod = 'MIXED';
      badgeColor = AppTheme.primaryColor;
      icon = Icons.sync_alt_rounded;
    } else if (upiAmount > 0) {
      paymentMethod = 'UPI';
      badgeColor = Colors.purple[600]!;
      icon = Icons.payment_rounded;
    } else if (cashAmount > 0) {
      paymentMethod = 'CASH';
      badgeColor = Colors.green[600]!;
      icon = Icons.money_rounded;
    } else {
      // Default for pending orders without payment info
      paymentMethod = 'PENDING';
      badgeColor = Colors.orange[600]!;
      icon = Icons.schedule_rounded;
    }

    // For completed orders, use muted colors
    if (order.completed) {
      badgeColor = Colors.grey[500]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: order.completed
            ? Colors.grey[200]
            : badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: order.completed
              ? Colors.grey[400]!
              : badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: order.completed ? Colors.grey[500] : badgeColor,
          ),
          const SizedBox(width: 3),
          Text(
            paymentMethod,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: order.completed ? Colors.grey[500] : badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
