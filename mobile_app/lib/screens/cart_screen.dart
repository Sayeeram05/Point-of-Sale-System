import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/pos_widgets.dart';

class CartPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final void Function(int) onIncrease;
  final void Function(int) onDecrease;
  final void Function(int) onRemove;
  final VoidCallback onOrderCompleted;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onOrderCompleted,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = true;
  String? errorMessage;
  List<ProductModel> products = [];
  bool _isSubmitting = false;
  String? _orderErrorMessage;
  String _selectedPaymentMethod = 'UPI';
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Widget _buildPaymentChip(String method) {
    final bool selected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0E0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFE67E22) : const Color(0xFFF2DFD0),
          ),
        ),
        child: Text(
          method,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFFE67E22) : const Color(0xFF8B4513),
          ),
        ),
      ),
    );
  }

  Future<void> _loadProducts() async {
    try {
      products = await ApiService.fetchProducts();
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

  Future<void> _completeOrder() async {
    final cartItems = widget.cartItems;
    if (cartItems.isEmpty) {
      setState(() {
        _orderErrorMessage = 'Add items to cart before completing the order.';
      });
      return;
    }

    final upiAmount = double.tryParse(_upiController.text) ?? 0;
    final cashAmount = double.tryParse(_cashController.text) ?? 0;

    if (_selectedPaymentMethod == 'UPI' && upiAmount <= 0) {
      setState(() {
        _orderErrorMessage = 'Enter the UPI amount.';
      });
      return;
    }
    if (_selectedPaymentMethod == 'Cash' && cashAmount <= 0) {
      setState(() {
        _orderErrorMessage = 'Enter the cash amount.';
      });
      return;
    }
    if (_selectedPaymentMethod == 'Both' &&
        (upiAmount <= 0 || cashAmount <= 0)) {
      setState(() {
        _orderErrorMessage = 'Enter both UPI and cash amounts.';
      });
      return;
    }

    final totalQuantity = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    setState(() {
      _orderErrorMessage = null;
      _isSubmitting = true;
    });

    try {
      await ApiService.createOrder(
        totalQuantity: totalQuantity,
        upiAmount: upiAmount,
        cashAmount: cashAmount,
        completed: true,
      );
      _upiController.clear();
      _cashController.clear();
      setState(() {
        _isSubmitting = false;
      });
      widget.onOrderCompleted();
    } catch (error) {
      setState(() {
        _orderErrorMessage = error.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cartItems;
    final itemCount = cartItems.length;
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final deliveryFee = itemCount > 0 ? 30.0 : 0.0;
    final tax = subtotal * 0.05;
    final total = subtotal + deliveryFee + tax;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Cart',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B1A00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$itemCount items in your cart',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8B4513)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No items available to display.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        return CartItemCardWidget(
                          name: cartItem.name,
                          price: cartItem.priceLabel,
                          quantity: cartItem.quantity,
                          subtitle: 'Added to cart',
                          onIncrease: () => widget.onIncrease(cartItem.id),
                          onDecrease: () => widget.onDecrease(cartItem.id),
                          onRemove: () => widget.onRemove(cartItem.id),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F3B18),
                        ),
                      ),
                      Text(
                        '₹${subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Fee',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F3B18),
                        ),
                      ),
                      Text(
                        '₹${deliveryFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tax (5%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F3B18),
                        ),
                      ),
                      Text(
                        '₹${tax.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1.1,
                    color: Color(0xFFF2E2D2),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B1A00),
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B1A00),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaymentChip('UPI'),
                      _buildPaymentChip('Cash'),
                      _buildPaymentChip('Both'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_selectedPaymentMethod == 'UPI' ||
                      _selectedPaymentMethod == 'Both')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _upiController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'UPI amount',
                          prefixText: '₹',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  if (_selectedPaymentMethod == 'Cash' ||
                      _selectedPaymentMethod == 'Both')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cash amount',
                          prefixText: '₹',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  if (_orderErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _orderErrorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFD23E3E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSubmitting ? null : _completeOrder,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Complete Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
