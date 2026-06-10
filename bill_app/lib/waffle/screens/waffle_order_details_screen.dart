import 'package:flutter/material.dart';
import '../models/waffle_order_model.dart';
import '../providers/waffle_order_provider.dart';
import '../services/waffle_order_service.dart';
import '../themes/waffle_theme.dart';
import 'waffle_products_screen.dart';

class WaffleOrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const WaffleOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<WaffleOrderDetailsScreen> createState() =>
      _WaffleOrderDetailsScreenState();
}

class _WaffleOrderDetailsScreenState extends State<WaffleOrderDetailsScreen> {
  final WaffleOrderService _orderService = WaffleOrderService();
  final WaffleOrderProvider _pickerProvider = WaffleOrderProvider();
  WaffleOrder? _order;
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';
  String _paymentMode = 'Cash';
  double _cashAmount = 0.0;
  double _upiAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final order = await _orderService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _cashAmount = order.totalPrice;
        _upiAmount = 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showProductPicker() async {
    try {
      await _pickerProvider.initialize(widget.orderId);
      if (!mounted) return;
      final changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: WaffleTheme.backgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 64,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Waffle Items',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: WaffleProductsScreen(
                            provider: _pickerProvider,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WaffleTheme.primaryColor,
                          minimumSize: const Size.fromHeight(54),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (changed == true) {
        await _pickerProvider.saveOrder();
        await _loadOrder();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load waffle products. $e')),
      );
    }
  }

  Future<void> _markComplete() async {
    if (_order == null) return;
    if (_cashAmount + _upiAmount != _order!.totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment must match ₹${_order!.totalPrice.toStringAsFixed(2)}',
          ),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final completed = await _orderService.completeOrder(
        widget.orderId,
        cash: _cashAmount,
        upi: _upiAmount,
      );
      if (!mounted) return;
      setState(() {
        _order = completed;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked complete'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaffleTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: WaffleTheme.primaryColor,
        title: const Text('Waffle Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add waffle items',
            onPressed: _showProductPicker,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : _order == null
          ? const Center(child: Text('Order not found'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${_order!.id}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_order!.items.length} items • ₹${_order!.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _order!.items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.black12),
                      itemBuilder: (context, index) {
                        final item = _order!.items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 6,
                          ),
                          title: Text(
                            item.productName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'Qty ${item.quantity} • ₹${item.price.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: WaffleTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WaffleTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Payment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMethodChip('Cash'),
                            const SizedBox(width: 10),
                            _buildMethodChip('UPI'),
                            const SizedBox(width: 10),
                            _buildMethodChip('Both'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_paymentMode != 'UPI')
                          _buildAmountField(
                            label: 'Cash Amount',
                            value: _cashAmount.toStringAsFixed(2),
                            onChanged: (value) {
                              final amount = double.tryParse(value) ?? 0.0;
                              setState(() {
                                _cashAmount = amount;
                                if (_paymentMode == 'Both') {
                                  _upiAmount =
                                      (_order!.totalPrice - _cashAmount).clamp(
                                        0,
                                        _order!.totalPrice,
                                      );
                                }
                              });
                            },
                          ),
                        if (_paymentMode != 'Cash')
                          _buildAmountField(
                            label: 'UPI Amount',
                            value: _upiAmount.toStringAsFixed(2),
                            onChanged: (value) {
                              final amount = double.tryParse(value) ?? 0.0;
                              setState(() {
                                _upiAmount = amount;
                                if (_paymentMode == 'Both') {
                                  _cashAmount =
                                      (_order!.totalPrice - _upiAmount).clamp(
                                        0,
                                        _order!.totalPrice,
                                      );
                                }
                              });
                            },
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Total: ₹${_order!.totalPrice.toStringAsFixed(2)} • Method: ${_order!.paymentMethod}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WaffleTheme.primaryColor,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _order!.completed || _isSaving
                        ? null
                        : _markComplete,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _order!.completed
                                ? 'Already Completed'
                                : 'Mark Complete',
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMethodChip(String method) {
    final isSelected = _paymentMode == method;
    return GestureDetector(
      onTap: () => setState(() {
        _paymentMode = method;
        if (method == 'Cash') {
          _cashAmount = _order?.totalPrice ?? 0.0;
          _upiAmount = 0.0;
        } else if (method == 'UPI') {
          _upiAmount = _order?.totalPrice ?? 0.0;
          _cashAmount = 0.0;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? WaffleTheme.primaryColor : WaffleTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? WaffleTheme.primaryColor
                : WaffleTheme.borderColor,
          ),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: isSelected ? Colors.white : WaffleTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
