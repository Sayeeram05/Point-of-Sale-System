import 'package:flutter/material.dart';
import '../providers/waffle_provider.dart';
import '../services/waffle_order_service.dart';
import '../themes/waffle_theme.dart';
import '../widgets/waffle_summary_card.dart';
import '../widgets/waffle_order_card.dart';
import 'waffle_order_screen.dart';
import 'waffle_order_details_screen.dart';

class WaffleDashboardScreen extends StatefulWidget {
  const WaffleDashboardScreen({super.key});

  @override
  State<WaffleDashboardScreen> createState() => _WaffleDashboardScreenState();
}

class _WaffleDashboardScreenState extends State<WaffleDashboardScreen> {
  final WaffleProvider _provider = WaffleProvider();
  final WaffleOrderService _orderService = WaffleOrderService();

  @override
  void initState() {
    super.initState();
    _provider.loadDashboard();
  }

  Future<void> refresh() async {
    await _provider.loadDashboard(forceRefresh: true);
  }

  Future<void> createOrder() async {
    await _createOrder();
  }

  Future<void> _createOrder() async {
    try {
      final order = await _orderService.createOrder();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WaffleOrderScreen(orderId: order.id)),
      );
      await _provider.loadDashboard(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to create new order. $e')));
    }
  }

  Widget _buildSummaryCards() {
    final summary = _provider.summary;
    if (summary == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WaffleSummaryCard(
                title: 'Orders',
                value: summary.totalOrders.toString(),
                icon: Icons.list_alt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WaffleSummaryCard(
                title: 'Sales',
                value: '₹${summary.totalAmount.toStringAsFixed(2)}',
                icon: Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: WaffleSummaryCard(
                title: 'UPI',
                value: '₹${summary.totalUpi.toStringAsFixed(2)}',
                icon: Icons.qr_code,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WaffleSummaryCard(
                title: 'Cash',
                value: '₹${summary.totalCash.toStringAsFixed(2)}',
                icon: Icons.currency_rupee,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final labels = ['All', 'Pending', 'Completed'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = _provider.selectedTabIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => _provider.setTab(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              margin: EdgeInsets.only(right: index < labels.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: selected
                    ? WaffleTheme.primaryColor
                    : WaffleTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? WaffleTheme.primaryColor
                      : WaffleTheme.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? Colors.white : WaffleTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrderList() {
    final orders = _provider.visibleOrders;
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No waffle orders yet. Tap + to start a new order.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: orders
          .map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: WaffleOrderCard(
                order: order,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WaffleOrderDetailsScreen(orderId: order.id),
                    ),
                  );
                  await _provider.loadDashboard(forceRefresh: true);
                },
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, child) {
        return RefreshIndicator(
          onRefresh: () => _provider.loadDashboard(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildSummaryCards(),
                const SizedBox(height: 20),
                _buildTabs(),
                const SizedBox(height: 16),
                if (_provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 36),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_provider.error.isNotEmpty)
                  Center(child: Text(_provider.error))
                else
                  _buildOrderList(),
                const SizedBox(height: 90),
              ],
            ),
          ),
        );
      },
    );
  }
}
