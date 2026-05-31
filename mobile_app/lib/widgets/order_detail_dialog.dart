import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/bill_pdf_service.dart';
import '../theme/app_theme.dart';

class OrderDetailDialog extends StatefulWidget {
  final Order order;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onMarkIncomplete;
  final VoidCallback? onDelete;

  const OrderDetailDialog({
    super.key,
    required this.order,
    required this.onMarkComplete,
    required this.onMarkIncomplete,
    required this.onDelete,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  final ScrollController _itemsScrollController = ScrollController();

  // Payment state
  late ValueNotifier<String> paymentMode;
  late TextEditingController upiController;
  late TextEditingController cashController;
  late FocusNode cashFocus;
  late FocusNode upiFocus;
  late ValueNotifier<String?> errorText;
  bool isEditingUPI = false;
  bool isEditingCash = false;

  // Bill state
  bool _isSavingBill = false;
  String? _billSavedPath;

  @override
  void initState() {
    super.initState();
    paymentMode = ValueNotifier<String>('Cash');
    upiController = TextEditingController();
    cashController = TextEditingController(
      text: widget.order.totalPrice.toStringAsFixed(2),
    );
    cashFocus = FocusNode();
    upiFocus = FocusNode();
    errorText = ValueNotifier<String?>(null);
    paymentMode.addListener(_handlePaymentModeChange);
    upiController.addListener(_handleUPIChange);
    cashController.addListener(_handleCashChange);
  }

  @override
  void dispose() {
    _itemsScrollController.dispose();
    paymentMode.removeListener(_handlePaymentModeChange);
    upiController.removeListener(_handleUPIChange);
    cashController.removeListener(_handleCashChange);
    paymentMode.dispose();
    upiController.dispose();
    cashController.dispose();
    cashFocus.dispose();
    upiFocus.dispose();
    errorText.dispose();
    super.dispose();
  }

  void _handlePaymentModeChange() {
    if (paymentMode.value == 'UPI') {
      upiController.text = widget.order.totalPrice.toStringAsFixed(2);
      cashController.text = '';
    } else if (paymentMode.value == 'Cash') {
      cashController.text = widget.order.totalPrice.toStringAsFixed(2);
      upiController.text = '';
    } else if (paymentMode.value == 'Both') {
      upiController.text = '';
      cashController.text = '';
    }
  }

  void _handleUPIChange() {
    if (paymentMode.value == 'Both' && !isEditingCash) {
      isEditingUPI = true;
      final upi = double.tryParse(upiController.text) ?? 0.0;
      final cash = (widget.order.totalPrice - upi).clamp(
        0,
        widget.order.totalPrice,
      );
      if (upiController.text.isNotEmpty) {
        cashController.text = cash.toStringAsFixed(2);
      }
      isEditingUPI = false;
    }
  }

  void _handleCashChange() {
    if (paymentMode.value == 'Both' && !isEditingUPI) {
      isEditingCash = true;
      final cash = double.tryParse(cashController.text) ?? 0.0;
      final upi = (widget.order.totalPrice - cash).clamp(
        0,
        widget.order.totalPrice,
      );
      if (cashController.text.isNotEmpty) {
        upiController.text = upi.toStringAsFixed(2);
      }
      isEditingCash = false;
    }
  }

  Future<void> handleMarkComplete() async {
    double upi = 0.0;
    double cash = 0.0;
    if (paymentMode.value == 'Cash') {
      cash = double.tryParse(cashController.text) ?? 0.0;
    } else if (paymentMode.value == 'UPI') {
      upi = double.tryParse(upiController.text) ?? 0.0;
    } else {
      cash = double.tryParse(cashController.text) ?? 0.0;
      upi = double.tryParse(upiController.text) ?? 0.0;
    }
    final total = upi + cash;
    if ((total - widget.order.totalPrice).abs() > 0.01) {
      errorText.value =
          'Total payment must match order total (\u20B9${widget.order.totalPrice.toStringAsFixed(2)})';
      return;
    }
    errorText.value = null;
    try {
      final orderItems = widget.order.items
          .where((item) => item.itemId > 0)
          .map((item) {
        return {
          'ProductID': item.itemId,
          'Quantity': item.pieces,
          'PriceAtPurchase': item.price,
        };
      }).toList();

      await ApiService.updateOrderWithItems(
        widget.order.orderId,
        totalQuantity: widget.order.totalItems,
        upiAmount: upi,
        cashAmount: cash,
        completed: true,
        orderItems: orderItems,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {}
  }

  Future<void> _saveBill() async {
    setState(() {
      _isSavingBill = true;
      _billSavedPath = null;
    });
    try {
      final pdfBytes = await BillPdfService.generateBillPdf(widget.order);
      final path = await BillPdfService.savePdf(pdfBytes, widget.order);
      if (mounted) {
        setState(() {
          _isSavingBill = false;
          _billSavedPath = path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill saved to $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingBill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareBill() async {
    setState(() => _isSavingBill = true);
    try {
      final pdfBytes = await BillPdfService.generateBillPdf(widget.order);
      await BillPdfService.shareOrPrint(pdfBytes, widget.order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBill = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final order = widget.order;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: isTablet ? 850 : 420,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * (isTablet ? 0.92 : 0.95),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              _buildDialogHeader(order, isTablet),
              // ── Body ──
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 28 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.items.isNotEmpty)
                        _buildItemsSection(order, isTablet),
                      SizedBox(height: isTablet ? 20 : 14),
                      _buildPaymentCard(order, isTablet),
                      if (!order.completed) ...[
                        const SizedBox(height: 16),
                        _buildPaymentMethodSection(isTablet),
                      ],
                      if (order.completed) ...[
                        const SizedBox(height: 16),
                        _buildBillActions(isTablet),
                      ],
                      const SizedBox(height: 16),
                      _buildActionButtons(order, isTablet),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dialog Header ────────────────────────────────────────────────────────
  Widget _buildDialogHeader(Order order, bool isTablet) {
    final orderDate = order.parsedOrderDate;
    final dateStr = orderDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(orderDate)
        : '';

    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 20,
        isTablet ? 20 : 16,
        isTablet ? 20 : 12,
        isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        gradient: order.completed
            ? const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              order.emoji.isEmpty ? '🍦' : order.emoji,
              style: TextStyle(fontSize: isTablet ? 28 : 22),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderLabel,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.completed ? 'COMPLETED' : 'PENDING',
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            iconSize: isTablet ? 24 : 20,
          ),
        ],
      ),
    );
  }

  // ─── Items Section ────────────────────────────────────────────────────────
  Widget _buildItemsSection(Order order, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long,
              size: isTablet ? 22 : 18,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Items (${order.items.length})',
              style: TextStyle(
                fontSize: isTablet ? 18 : 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${order.totalItems} pcs',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        // Table header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 10,
            vertical: isTablet ? 10 : 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF546E7A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: isTablet ? 36 : 28,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: isTablet ? 50 : 36,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: isTablet ? 80 : 65,
                child: Text(
                  'Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: isTablet ? 90 : 75,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Items list
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: isTablet ? 400 : 220),
          child: Scrollbar(
            thumbVisibility: true,
            controller: _itemsScrollController,
            child: ListView.builder(
              controller: _itemsScrollController,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, idx) {
                final item = order.items[idx];
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14 : 10,
                    vertical: isTablet ? 10 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: idx.isEven ? Colors.white : const Color(0xFFF5F7FA),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: isTablet ? 36 : 28,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.product,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: isTablet ? 50 : 36,
                        child: Text(
                          '${item.pieces}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isTablet ? 80 : 65,
                        child: Text(
                          '\u20B9${item.priceDouble.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isTablet ? 90 : 75,
                        child: Text(
                          '\u20B9${item.totalPrice.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Payment Card ─────────────────────────────────────────────────────────
  Widget _buildPaymentCard(Order order, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\u20B9${order.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 26 : 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          if (order.completed) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.blue.shade200, height: 1),
            const SizedBox(height: 10),
            if (order.cashAmountDouble > 0)
              _paymentRow(
                Icons.payments_outlined,
                'Cash',
                '\u20B9${order.cashAmountDouble.toStringAsFixed(2)}',
                const Color(0xFF2E7D32),
                isTablet,
              ),
            if (order.upiAmountDouble > 0) ...[
              if (order.cashAmountDouble > 0) const SizedBox(height: 6),
              _paymentRow(
                Icons.qr_code_2,
                'UPI',
                '\u20B9${order.upiAmountDouble.toStringAsFixed(2)}',
                const Color(0xFF1565C0),
                isTablet,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _paymentRow(
    IconData icon,
    String label,
    String amount,
    Color color,
    bool isTablet,
  ) {
    return Row(
      children: [
        Icon(icon, size: isTablet ? 20 : 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 15 : 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Bill Actions (for completed orders) ──────────────────────────────────
  Widget _buildBillActions(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFEB3B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt,
                size: isTablet ? 20 : 17,
                color: const Color(0xFFF57F17),
              ),
              const SizedBox(width: 8),
              Text(
                'Bill',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSavingBill ? null : _saveBill,
                  icon: _isSavingBill
                      ? SizedBox(
                          width: isTablet ? 18 : 15,
                          height: isTablet ? 18 : 15,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.save_alt, size: isTablet ? 20 : 17),
                  label: Text(
                    _billSavedPath != null ? 'Saved!' : 'Save Bill',
                    style: TextStyle(fontSize: isTablet ? 14 : 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _billSavedPath != null
                        ? Colors.green
                        : const Color(0xFF1565C0),
                    side: BorderSide(
                      color: _billSavedPath != null
                          ? Colors.green
                          : const Color(0xFF1565C0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSavingBill ? null : _shareBill,
                  icon: Icon(Icons.share_outlined, size: isTablet ? 20 : 17),
                  label: Text(
                    'Share / Print',
                    style: TextStyle(fontSize: isTablet ? 14 : 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10),
                  ),
                ),
              ),
            ],
          ),
          if (_billSavedPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _billSavedPath!,
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Payment Method Section (pending orders) ──────────────────────────────
  Widget _buildPaymentMethodSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 18 : 15,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: isTablet ? 10 : 6),
        ValueListenableBuilder<String>(
          valueListenable: paymentMode,
          builder: (context, value, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ChoiceChip(
                avatar: Icon(
                  Icons.payments,
                  color: value == 'Cash' ? Colors.white : Colors.grey,
                  size: isTablet ? 24 : 18,
                ),
                label: Text(
                  'Cash',
                  style: TextStyle(fontSize: isTablet ? 18 : 14),
                ),
                selected: value == 'Cash',
                selectedColor: Colors.green,
                onSelected: (selected) {
                  if (selected) paymentMode.value = 'Cash';
                },
              ),
              ChoiceChip(
                avatar: Icon(
                  Icons.qr_code,
                  color: value == 'UPI' ? Colors.white : Colors.grey,
                  size: isTablet ? 24 : 18,
                ),
                label: Text(
                  'UPI',
                  style: TextStyle(fontSize: isTablet ? 18 : 14),
                ),
                selected: value == 'UPI',
                selectedColor: Colors.blue,
                onSelected: (selected) {
                  if (selected) paymentMode.value = 'UPI';
                },
              ),
              ChoiceChip(
                avatar: Icon(
                  Icons.swap_horiz,
                  color: value == 'Both' ? Colors.white : Colors.grey,
                  size: isTablet ? 24 : 18,
                ),
                label: Text(
                  'Both',
                  style: TextStyle(fontSize: isTablet ? 18 : 14),
                ),
                selected: value == 'Both',
                selectedColor: Colors.deepPurple,
                onSelected: (selected) {
                  if (selected) paymentMode.value = 'Both';
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: const Color(0xFFF5F7FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 22 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: paymentMode,
              builder: (context, value, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (value == 'Cash') ...[
                      TextField(
                        controller: cashController,
                        focusNode: cashFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onEditingComplete: handleMarkComplete,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'Cash Amount',
                          prefixText: '\u20B9',
                          helperText: 'Enter the cash received from customer',
                        ),
                      ),
                    ],
                    if (value == 'UPI') ...[
                      TextField(
                        controller: upiController,
                        focusNode: upiFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onEditingComplete: handleMarkComplete,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'UPI Amount',
                          prefixText: '\u20B9',
                          helperText: 'Enter the UPI payment amount',
                        ),
                      ),
                    ],
                    if (value == 'Both') ...[
                      TextField(
                        controller: cashController,
                        focusNode: cashFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(upiFocus),
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'Cash Amount',
                          prefixText: '\u20B9',
                          helperText: 'Enter the cash part of payment',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: upiController,
                        focusNode: upiFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onEditingComplete: handleMarkComplete,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          labelText: 'UPI Amount',
                          prefixText: '\u20B9',
                          helperText: 'Enter the UPI part of payment',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String?>(
          valueListenable: errorText,
          builder: (context, value, _) => value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────────────
  Widget _buildActionButtons(Order order, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: order.completed
                ? widget.onMarkIncomplete
                : handleMarkComplete,
            icon: Icon(
              order.completed ? Icons.undo : Icons.check_circle,
              size: isTablet ? 22 : 18,
            ),
            label: Text(
              order.completed ? 'Mark Incomplete' : 'Mark Complete',
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: order.completed ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
