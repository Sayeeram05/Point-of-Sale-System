import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/pos_widgets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  OrdersPageState createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  bool isLoading = true;
  String? errorMessage;
  List<OrderModel> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      orders = await ApiService.fetchOrders(date: 'today');
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> refreshOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await _loadOrders();
  }

  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = dateTime.hour == 0
          ? 12
          : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • $hour:$minute $suffix';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE67E22)),
        ),
      );
    }

    if (errorMessage != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFFD23E3E)),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2B1A00),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your recent waffle orders',
            style: TextStyle(fontSize: 14, color: Color(0xFF8B4513)),
          ),
          const SizedBox(height: 24),
          if (orders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No orders available yet.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8B4513)),
                ),
              ),
            )
          else
            ...orders.map((order) {
              final statusColor = order.status.toLowerCase() == 'cancelled'
                  ? const Color(0xFFD23E3E)
                  : const Color(0xFF37A66B);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: OrderSummaryCard(
                  orderId: order.id,
                  date: _formatDate(order.date),
                  items: order.items,
                  total: '₹${order.totalAmount.toStringAsFixed(0)}',
                  status: order.status,
                  statusColor: statusColor,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
