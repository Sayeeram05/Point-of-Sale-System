import 'package:flutter/material.dart';
import '../providers/WOFL_order_provider.dart';
import '../services/WOFL_order_service.dart';
import '../themes/WOFL_theme.dart';
import '../widgets/WOFL_payment_widget.dart';
import 'WOFL_products_screen.dart';

class WOFLOrderScreen extends StatefulWidget {
  final int orderId;

  const WOFLOrderScreen({super.key, required this.orderId});

  @override
  State<WOFLOrderScreen> createState() => _WOFLOrderScreenState();
}

class _WOFLOrderScreenState extends State<WOFLOrderScreen> {
  final WOFLOrderProvider _provider = WOFLOrderProvider();
  final WOFLOrderService _orderService = WOFLOrderService();

  @override
  void initState() {
    super.initState();
    _provider.initialize(widget.orderId);
  }

  Future<void> _showSummaryDialog() async {
    if (_provider.orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item before completing the order.'),
        ),
      );
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AnimatedBuilder(
          animation: _provider,
          builder: (context, child) {
            return AlertDialog(
              backgroundColor: WOFLTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('Order Summary'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._provider.orderItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} x${item.quantity}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.black26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '₹${_provider.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    WOFLPaymentWidget(provider: _provider),
                    const SizedBox(height: 10),
                    if (_provider.error.isNotEmpty)
                      Text(
                        _provider.error,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WOFLTheme.primaryColor,
                  ),
                  onPressed: _provider.isSaving
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          await _provider.saveOrder();
                          final success = await _provider.completeOrder();
                          if (success && mounted) {
                            navigator.pop(true);
                          }
                        },
                  child: _provider.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Mark Complete'),
                ),
              ],
            );
          },
        );
      },
    );
    if (mounted) {
      final order = await _orderService.getOrder(widget.orderId);
      setState(() {
        _provider.order = order;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: WOFLTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('WOFL Order'),
            backgroundColor: WOFLTheme.primaryColor,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: _showSummaryDialog,
                    ),
                    if (_provider.totalItemCount > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_provider.totalItemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: _provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _provider.error.isNotEmpty
              ? Center(child: Text(_provider.error))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order header ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${widget.orderId}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_provider.totalItemCount} items • ₹${_provider.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    // ── Products (scrollable) ────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: WOFLProductsScreen(provider: _provider),
                      ),
                    ),

                    // ── Review & Complete button ──────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      decoration: BoxDecoration(
                        color: WOFLTheme.backgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _showSummaryDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WOFLTheme.accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Review & Complete',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
