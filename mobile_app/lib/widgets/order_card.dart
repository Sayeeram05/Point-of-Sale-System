import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/app_colors.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// OrderCard - A refined order card widget with fixed layout, alignment, and styling.
///
/// Features:
/// - Proper sequential order numbering based on creation time
/// - Vertically centered header row with compact emoji/color indicators
/// - Modern pill-style payment badges with theme-matched colors
/// - Overflow-resistant layout using Expanded/Flexible widgets
class OrderCard extends StatelessWidget {
  final Order order;
  final int displayNumber;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback onEmojiColorTap;
  final VoidCallback? onOrderDeleted;

  const OrderCard({
    super.key,
    required this.order,
    required this.displayNumber,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    required this.onEmojiColorTap,
    this.onOrderDeleted,
  });

  @override
  Widget build(BuildContext context) {
    const cardMargin = 2.0;
    const cardPadding = 6.0;

    // Determine colors based on order completion status
    final Color baseColor;
    final Color cardColor;
    final Color borderColor;

    if (order.completed) {
      baseColor = Colors.grey[600]!;
      cardColor = Colors.grey[50]!;
      borderColor = Colors.grey[300]!;
    } else {
      final ownerColor = AppColors.fromHex(order.color);
      baseColor = ownerColor;
      cardColor = ownerColor.withValues(alpha: 0.13);
      borderColor = ownerColor.withValues(alpha: 0.22);
    }

    return Container(
      margin: const EdgeInsets.all(cardMargin),
      child: Material(
        elevation: order.completed ? 0.2 : 0.5,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          onDoubleTap: onDoubleTap != null ? () => onDoubleTap!() : null,
          onLongPress: onLongPress != null ? () => onLongPress!() : null,
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: order.completed ? 0.7 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cardColor,
                border: Border.all(
                  color: borderColor,
                  width: order.completed ? 1.5 : 0.8,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Completed order banner
                  if (order.completed) _buildCompletedBanner(),

                  // Fixed header row with proper alignment and overflow prevention
                  _buildHeaderRow(context, baseColor),

                  // Order items list
                  if (order.items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildItemsList(),
                    _buildTotalRow(baseColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER COMPONENTS
  // ===========================================================================

  /// Builds the green "ORDER COMPLETED" banner at the top of completed orders
  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 14),
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
    );
  }

  /// Builds the header row with fixed alignment and overflow handling
  ///
  /// Layout: [Emoji+Dot] [Order# + PaymentBadge] [ItemCount] [DeleteBtn]
  /// All elements are vertically centered and flex properly to prevent overflow
  Widget _buildHeaderRow(BuildContext context, Color baseColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emoji and color indicator - compact, fixed size
        _buildEmojiColorIndicator(baseColor),

        const SizedBox(width: 6),

        // Order number and payment badge - flexible width
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Order number with constrained height for vertical centering
              Container(
                height: 24,
                alignment: Alignment.centerLeft,
                child: Text(
                  '#$displayNumber',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: order.completed ? Colors.grey[600] : baseColor,
                    height: 1.0,
                    decoration: order.completed ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.grey[400],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              // Modern pill-style payment badge
              _buildPaymentMethodBadge(baseColor),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Items count indicator - compact vertical layout
        _buildItemsCountIndicator(),

        const SizedBox(width: 4),

        // Delete button - constrained size
        _buildDeleteButton(context),
      ],
    );
  }

  /// Builds the emoji and color dot indicator
  /// Uses explicit dimensions to ensure proper vertical alignment
  Widget _buildEmojiColorIndicator(Color baseColor) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: order.completed ? null : onEmojiColorTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                order.completed
                    ? '✅'
                    : (order.emoji.isNotEmpty ? order.emoji : '🍦'),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.0,
                  color: order.completed ? Colors.grey[600] : null,
                ),
              ),
              const SizedBox(width: 4),
              // Compact color dot - 8x8 for tighter layout
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: order.completed ? Colors.grey[400] : baseColor,
                  shape: BoxShape.circle,
                  boxShadow: order.completed
                      ? null
                      : [
                          BoxShadow(
                            color: baseColor.withValues(alpha: 0.4),
                            blurRadius: 2,
                            spreadRadius: 0.5,
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the items count indicator with icon
  /// Compact vertical stack matching the emoji container height
  Widget _buildItemsCountIndicator() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item count row with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 10,
                color: order.completed ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 2),
              Text(
                '${order.items.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: order.completed ? Colors.grey[500] : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Status pill (DONE/PENDING)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: order.completed
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: order.completed
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              order.completed ? 'DONE' : 'PENDING',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: order.completed ? Colors.green.shade700 : Colors.orange.shade700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the delete button with constrained size
  Widget _buildDeleteButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showDeleteConfirmation(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: order.completed
                ? Colors.grey[200]
                : Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: order.completed ? Colors.grey[400]! : Colors.red.shade300,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.delete_outline,
            color: order.completed ? Colors.grey[500] : Colors.red.shade600,
            size: 18,
          ),
        ),
      ),
    );
  }

  /// Shows delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete Order #$displayNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteOrder(order.orderId);
        if (context.mounted && onOrderDeleted != null) {
          onOrderDeleted!();
        }
      } catch (e) {
        // Error notification removed per user request
      }
    }
  }

  /// Builds a modern, elegant pill-style payment method badge
  /// Features subtle desaturated colors, thin borders, and tiny icons
  Widget _buildPaymentMethodBadge(Color baseColor) {
    // Determine payment method and colors based on payment amounts
    final String paymentMethod;
    final Color badgeColor;
    final IconData icon;

    final upiAmount = double.tryParse(order.upiAmount) ?? 0.0;
    final cashAmount = double.tryParse(order.cashAmount) ?? 0.0;

    if (upiAmount > 0 && cashAmount > 0) {
      paymentMethod = 'MIXED';
      badgeColor = AppTheme.primaryColor;
      icon = Icons.sync_alt_rounded;
    } else if (upiAmount > 0) {
      paymentMethod = 'UPI';
      badgeColor = Colors.purple[500]!;
      icon = Icons.payment_rounded;
    } else if (cashAmount > 0) {
      paymentMethod = 'CASH';
      badgeColor = Colors.teal[600]!;
      icon = Icons.money_rounded;
    } else {
      paymentMethod = 'PENDING';
      badgeColor = Colors.orange[500]!;
      icon = Icons.schedule_rounded;
    }

    // Muted colors for completed orders
    final effectiveColor = order.completed ? Colors.grey[500]! : badgeColor;
    final bgColor = order.completed
        ? Colors.grey[200]!
        : badgeColor.withValues(alpha: 0.08);
    final borderColor = order.completed
        ? Colors.grey[350]!
        : badgeColor.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: effectiveColor),
          const SizedBox(width: 3),
          Text(
            paymentMethod,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ITEMS & TOTAL COMPONENTS
  // ===========================================================================

  /// Builds the scrollable items list section
  Widget _buildItemsList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: order.completed ? Colors.grey[100] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: order.items.map((item) => _buildItemRow(item)).toList(),
      ),
    );
  }

  /// Builds a single item row with product name, quantity, and price
  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          // Product name - takes available space
          Expanded(
            child: Text(
              item.product,
              style: TextStyle(
                fontSize: 10,
                color: order.completed ? Colors.grey[600] : Colors.grey[800],
                fontWeight: FontWeight.w500,
                decoration: order.completed ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Quantity
          SizedBox(
            width: 26,
            child: Text(
              'x${item.pieces}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                color: order.completed ? Colors.grey[500] : Colors.grey[600],
                decoration: order.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 3),
          // Price
          SizedBox(
            width: 40,
            child: Text(
              '₹${item.totalPrice.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: order.completed ? Colors.grey[600] : Colors.grey[800],
                decoration: order.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the total amount row at the bottom of the card
  Widget _buildTotalRow(Color baseColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: order.completed ? Colors.grey[600] : Colors.grey[700],
              decoration: order.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                color: order.completed ? Colors.grey[700] : baseColor,
                decoration: order.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
