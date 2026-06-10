import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/b2b_invoice.dart';
import '../../models/b2b_product_override.dart';
import '../../models/b2b_settings.dart';
import '../../services/api_service.dart';
import '../../services/b2b_storage_service.dart';
import '../../theme/app_theme.dart';

class B2BInvoiceFormPage extends StatefulWidget {
  final B2BInvoice invoice;
  final B2BSettings settings;
  final bool isEditing;

  const B2BInvoiceFormPage({
    super.key,
    required this.invoice,
    required this.settings,
    this.isEditing = false,
  });

  @override
  State<B2BInvoiceFormPage> createState() => _B2BInvoiceFormPageState();
}

class _B2BInvoiceFormPageState extends State<B2BInvoiceFormPage> {
  late B2BInvoice _invoice;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _receiverNameCtrl;
  late TextEditingController _receiverAddrCtrl;
  late TextEditingController _receiverStateCtrl;
  late TextEditingController _defaultDiscPercentCtrl;
  late TextEditingController _globalDiscPercentCtrl;
  bool _isSaving = false;
  String? _inlineErrorMessage;

  // B2B product catalog
  List<B2BProductOverride> _catalog = [];

  @override
  void initState() {
    super.initState();
    _invoice = B2BInvoice(
      id: widget.invoice.id,
      invoiceNumber: widget.invoice.invoiceNumber,
      date: widget.invoice.date,
      receiverName: widget.invoice.receiverName,
      receiverAddress: widget.invoice.receiverAddress,
      receiverState: widget.invoice.receiverState,
      globalDiscountPercent: widget.invoice.globalDiscountPercent,
      status: widget.invoice.status,
      items: List<B2BInvoiceItem>.from(
        widget.invoice.items.map((e) => e.copyWith()),
      ),
      createdAt: widget.invoice.createdAt,
    );
    _receiverNameCtrl = TextEditingController(text: _invoice.receiverName);
    _receiverAddrCtrl = TextEditingController(text: _invoice.receiverAddress);
    _receiverStateCtrl = TextEditingController(text: _invoice.receiverState);

    final defaultDiscountPercent = _invoice.items.isNotEmpty
        ? _invoice.items.first.discountPercent
        : 0.0;
    _defaultDiscPercentCtrl = TextEditingController(
      text: defaultDiscountPercent > 0
          ? (defaultDiscountPercent == defaultDiscountPercent.truncateToDouble()
                ? defaultDiscountPercent.toInt().toString()
                : defaultDiscountPercent.toStringAsFixed(2))
          : '',
    );

    _globalDiscPercentCtrl = TextEditingController(
      text: _invoice.globalDiscountPercent > 0
          ? (_invoice.globalDiscountPercent ==
                    _invoice.globalDiscountPercent.truncateToDouble()
                ? _invoice.globalDiscountPercent.toInt().toString()
                : _invoice.globalDiscountPercent.toStringAsFixed(2))
          : '',
    );

    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await B2BStorageService.loadCatalog();
      if (mounted) {
        setState(() {
          _catalog = catalog.where((p) => p.enabled).toList();
        });
      }
    } catch (e) {
      // Ignore catalog fetch errors and allow manual entry.
      debugPrint('[B2B] catalog load failed: $e');
    }
  }

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _receiverAddrCtrl.dispose();
    _receiverStateCtrl.dispose();
    _defaultDiscPercentCtrl.dispose();
    _globalDiscPercentCtrl.dispose();
    super.dispose();
  }

  // ─── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    _clearInlineError();
    if (!_formKey.currentState!.validate()) return;
    if (_invoice.items.isEmpty) {
      _setInlineError('Add at least one product row.');
      return;
    }

    final invalidStickRows = <String>[];
    for (final entry in _invoice.items.asMap().entries) {
      final rowNumber = entry.key + 1;
      final item = entry.value;
      final missingStkPerBox = item.boxPieces == null || item.boxPieces! <= 0;
      if (item.isStickProduct &&
          item.productId.isNotEmpty &&
          missingStkPerBox) {
        invalidStickRows.add(rowNumber.toString());
      }
    }
    if (invalidStickRows.isNotEmpty) {
      _setInlineError(
        'Missing Stk/Box for stick item row(s): ${invalidStickRows.join(', ')}. Refresh stock and re-add those items.',
      );
      return;
    }

    setState(() => _isSaving = true);
    _invoice.receiverName = _receiverNameCtrl.text.trim();
    _invoice.receiverAddress = _receiverAddrCtrl.text.trim();
    _invoice.receiverState = _receiverStateCtrl.text.trim();
    _invoice.globalDiscountPercent =
        double.tryParse(_globalDiscPercentCtrl.text) ?? 0.0;

    try {
      // Consume invoice number only when creating a new invoice.
      if (!widget.isEditing) {
        _invoice.invoiceNumber =
            await B2BStorageService.consumeNextInvoiceNumber(widget.settings);
      }

      await B2BStorageService.saveInvoice(_invoice);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _setInlineError(
          'Failed to save invoice: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    }
  }

  void _setInlineError(String msg) {
    if (!mounted) return;
    setState(() => _inlineErrorMessage = msg);
  }

  void _clearInlineError() {
    if (!mounted || _inlineErrorMessage == null) return;
    setState(() => _inlineErrorMessage = null);
  }

  // â”€â”€â”€ Date Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoice.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _invoice.date = picked);
  }

  // â”€â”€â”€ Item CRUD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Primary entry point for adding a new item.
  /// Shows catalog picker if catalog has products; otherwise manual entry.
  void _addItem() {
    _clearInlineError();
    if (_catalog.isNotEmpty) {
      _showProductPickerSheet();
    } else {
      _addManualItem();
    }
  }

  void _addManualItem() {
    _clearInlineError();
    final last = _invoice.items.isNotEmpty ? _invoice.items.last : null;
    final defaultDisc = double.tryParse(_defaultDiscPercentCtrl.text) ?? 0.0;
    _editItemDialog(
      B2BInvoiceItem(
        description: '',
        hsnCode: last?.hsnCode ?? widget.settings.defaultHsnCode,
        rateInclTax: last?.rateInclTax ?? 0.0,
        quantity: 0,
        unit: last?.unit ?? 'Nos',
        discountPercent: defaultDisc,
        gstPercent: 0.0,
      ),
      isNew: true,
    );
  }

  /// Shows a searchable bottom sheet to pick a product from the B2B catalog.
  Future<void> _showProductPickerSheet() async {
    // Fetch live stock and stamp onto catalog entries (null = no limit if API fails)
    try {
      final stockMap = await ApiService.getB2BStock();
      for (final p in _catalog) {
        final stock = stockMap[p.productId];
        p.availableStock = stock?.available;
        if (p.isStick) p.boxPieces = stock?.boxPieces;
      }
    } catch (e) {
      debugPrint('[B2B] picker stock refresh failed: $e');
      // Stock fetch failed — proceed without limits
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        catalog: _catalog,
        settings: widget.settings,
        alreadyAdded: _invoice.items.map((e) => e.description).toSet(),
        initialDefaultDiscountPercent:
            double.tryParse(_defaultDiscPercentCtrl.text) ?? 0.0,
        onConfirm: (picks, discountPercent) {
          // Sync the chosen disc% back to the form header field
          if (discountPercent > 0) {
            _defaultDiscPercentCtrl.text =
                discountPercent == discountPercent.truncateToDouble()
                ? discountPercent.toInt().toString()
                : discountPercent.toStringAsFixed(2);
          }
          if (picks.isEmpty) return;
          setState(() {
            for (final p in picks) {
              final hsn =
                  (p.override.hsnCode != null && p.override.hsnCode!.isNotEmpty)
                  ? p.override.hsnCode!
                  : widget.settings.defaultHsnCode;
              final rate =
                  p.override.b2bRateInclTax != null &&
                      p.override.b2bRateInclTax! > 0
                  ? p.override.b2bRateInclTax!
                  : double.tryParse(p.override.b2cPrice) ?? 0.0;
              final desc =
                  p.override.isNonStick && p.override.categoryName != null
                  ? '${p.override.productName} (${p.override.categoryName})'
                  : p.override.productName;
              _invoice.items.add(
                B2BInvoiceItem(
                  description: desc,
                  hsnCode: hsn,
                  rateInclTax: rate,
                  quantity: p.override.isStick && p.override.boxPieces != null
                      ? p.qty * p.override.boxPieces!
                      : p.qty,
                  unit: 'Nos',
                  discountPercent: discountPercent,
                  gstPercent: 0.0,
                  productId: p.override.productId,
                  productType: p.override.productType,
                  boxPieces: p.override.isStick ? p.override.boxPieces : null,
                ),
              );
            }
          });
        },
        onManualEntry: _addManualItem,
      ),
    );
  }

  void _editItem(int index) {
    _editItemDialog(_invoice.items[index].copyWith(), index: index);
  }

  void _deleteItem(int index) {
    _clearInlineError();
    setState(() => _invoice.items.removeAt(index));
  }

  void _editItemDialog(B2BInvoiceItem item, {int? index, bool isNew = false}) {
    showDialog(
      context: context,
      builder: (_) => _ItemDialog(
        item: item,
        defaultHsn: widget.settings.defaultHsnCode,
        onSave: (edited) {
          _clearInlineError();
          setState(() {
            if (isNew) {
              _invoice.items.add(edited);
            } else if (index != null) {
              _invoice.items[index] = edited;
            }
          });
        },
      ),
    );
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final moneyFmt = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.isEditing
              ? 'Edit Invoice #${_invoice.invoiceNumber}'
              : 'New Invoice #${_invoice.invoiceNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 14 : 22),
          children: [
            if (_inlineErrorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Text(
                  _inlineErrorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            // â”€â”€ Invoice Info Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _section(
              title: 'Invoice Info',
              icon: Icons.receipt_long_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _readonlyField(
                          'Invoice No.',
                          _invoice.invoiceNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: _readonlyField(
                            'Date',
                            dateFmt.format(_invoice.date),
                            trailing: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // â”€â”€ Receiver Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _section(
              title: 'Receiver (Billed To)',
              icon: Icons.storefront_rounded,
              child: Column(
                children: [
                  _inputField(
                    controller: _receiverNameCtrl,
                    label: 'Franchise / Receiver Name *',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => _clearInlineError(),
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _receiverAddrCtrl,
                    label: 'Address',
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _clearInlineError(),
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: _receiverStateCtrl,
                    label: 'State',
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => _clearInlineError(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // â”€â”€ Products Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _section(
              title: 'Products  (${_invoice.items.length})',
              icon: Icons.inventory_2_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF5C6BC0).withValues(alpha: 0.4),
                      ),
                    ),
                    child: TextField(
                      controller: _defaultDiscPercentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF283593),
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Disc %',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7986CB),
                          fontWeight: FontWeight.w500,
                        ),
                        suffixText: '%',
                        suffixStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5C6BC0),
                          fontWeight: FontWeight.w600,
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                      ),
                      onChanged: (val) {
                        _clearInlineError();
                        final percent = double.tryParse(val) ?? 0.0;
                        setState(() {
                          for (final item in _invoice.items) {
                            item.discountPercent = percent;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _addItem,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              child: _invoice.items.isEmpty
                  ? _emptyItemsHint()
                  : _buildItemsTable(moneyFmt),
            ),
            const SizedBox(height: 14),

            // ── Summary ──
            _buildSummarySection(moneyFmt),
            const SizedBox(height: 80),
          ], // end ListView children
        ), // end ListView
      ), // end Form
    );
  }

  // ─── Summary Section ──────────────────────────────────────────────────────

  Widget _buildSummarySection(NumberFormat moneyFmt) {
    final isMobile = AppTheme.isMobileOnly(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.summarize_rounded,
                    size: 18,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 15 : 17,
                    color: const Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quantity row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Quantity',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_invoice.totalQuantity.toInt()} pcs',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Net amount row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Net Amount',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '\u20B9${moneyFmt.format(_invoice.totalNetAmount)}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE8ECF0)),
                ),

                // Overall discount row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Overall Discount',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Container(
                      width: isMobile ? 90 : 110,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: TextFormField(
                        controller: _globalDiscPercentCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF57F17),
                        ),
                        decoration: const InputDecoration(
                          suffixText: '%',
                          suffixStyle: TextStyle(
                            color: Color(0xFFF57F17),
                            fontWeight: FontWeight.w600,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) {
                          _clearInlineError();
                          setState(() {
                            _invoice.globalDiscountPercent =
                                double.tryParse(_globalDiscPercentCtrl.text) ??
                                0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '- \u20B9${moneyFmt.format(_invoice.globalDiscount)}',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Grand total
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 16 : 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '\u20B9${moneyFmt.format(_invoice.grandTotal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 18 : 22,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Items Table Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildItemsTable(NumberFormat moneyFmt) {
    // Large, clean table columns
    const colSNo = 32.0;
    const colDesc = 140.0;
    const colHsn = 80.0;
    const colRate = 72.0;
    const colStkBox = 55.0;
    const colQty = 60.0;
    const colAmount = 105.0;
    const colDiscP = 52.0;
    const colDiscR = 100.0;
    const colNet = 105.0;
    const colAction = 56.0;
    const gap = 6.0;

    // ignore: prefer_const_declarations
    final TextStyle headerStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.3,
    );

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 48,
            ),
            child: Column(
              children: [
                // ── Column Headers ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: colSNo,
                        child: Text(
                          'S.No',
                          style: headerStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colDesc,
                        child: Text('Item', style: headerStyle),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colHsn,
                        child: Text(
                          'HSN',
                          style: headerStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colRate,
                        child: Text(
                          'Rate (Rs)',
                          style: headerStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colStkBox,
                        child: Text(
                          'Stk/Box',
                          style: headerStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colQty,
                        child: Text(
                          'Boxes',
                          style: headerStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colAmount,
                        child: Text(
                          'Gross (Rs)',
                          style: headerStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colDiscP,
                        child: Text(
                          'Disc %',
                          style: headerStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colDiscR,
                        child: Text(
                          'Disc (Rs)',
                          style: headerStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colNet,
                        child: Text(
                          'Net (Rs)',
                          style: headerStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: colAction),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // ── Data Rows ──
                ...List.generate(_invoice.items.length, (i) {
                  final item = _invoice.items[i];
                  final amount = item.rateInclTax * item.quantity;
                  final isEven = i.isEven;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: colSNo,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colDesc,
                          child: Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A202C),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colHsn,
                          child: Text(
                            item.hsnCode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colRate,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              moneyFmt.format(item.rateInclTax),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        // Sticks per box cell
                        SizedBox(
                          width: colStkBox,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.stkPerBoxLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: item.isNonStickProduct
                                    ? Colors.grey.shade600
                                    : item.boxPieces != null
                                    ? const Color(0xFF455A64)
                                    : Colors.red.shade300,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        // Boxes (quantity ÷ boxPieces)
                        SizedBox(
                          width: colQty,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.quantityInBoxes ==
                                        item.quantityInBoxes.truncateToDouble()
                                    ? '${item.quantityInBoxes.toInt()}'
                                    : item.quantityInBoxes.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colAmount,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              moneyFmt.format(amount),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colDiscP,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            decoration: item.discountPercent > 0
                                ? BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                : null,
                            child: Text(
                              item.discountPercent > 0
                                  ? '${item.discountPercent.toStringAsFixed(item.discountPercent == item.discountPercent.truncateToDouble() ? 0 : 2)}%'
                                  : '-',
                              style: TextStyle(
                                fontSize: 13,
                                color: item.discountPercent > 0
                                    ? const Color(0xFFD32F2F)
                                    : Colors.grey.shade400,
                                fontWeight: item.discountPercent > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colDiscR,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              item.discountAmount > 0
                                  ? moneyFmt.format(item.discountAmount)
                                  : '-',
                              style: TextStyle(
                                fontSize: 14,
                                color: item.discountAmount > 0
                                    ? const Color(0xFFD32F2F)
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        SizedBox(
                          width: colNet,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              moneyFmt.format(item.netAmount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        // Action buttons
                        SizedBox(
                          width: colAction,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _editItem(i),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 17,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _deleteItem(i),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 17,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // ── Totals Row ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE3F2FD),
                        const Color(0xFFBBDEFB).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: const Border(
                      top: BorderSide(color: Color(0xFF0D47A1), width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: colSNo),
                      const SizedBox(width: gap),
                      const SizedBox(
                        width: colDesc,
                        child: Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D47A1),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      const SizedBox(width: colHsn),
                      const SizedBox(width: gap),
                      const SizedBox(width: colRate),
                      const SizedBox(width: gap),
                      const SizedBox(width: colStkBox), // Stk/Box spacer
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colQty,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              // Sum of quantityInBoxes across all items
                              () {
                                final totalBoxes = _invoice.items.fold<double>(
                                  0,
                                  (s, e) => s + e.quantityInBoxes,
                                );
                                return totalBoxes ==
                                        totalBoxes.truncateToDouble()
                                    ? '${totalBoxes.toInt()}'
                                    : totalBoxes.toStringAsFixed(1);
                              }(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colAmount,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            moneyFmt.format(
                              _invoice.items.fold<double>(
                                0,
                                (s, e) => s + e.rateInclTax * e.quantity,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      const SizedBox(width: colDiscP),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colDiscR,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            moneyFmt.format(
                              _invoice.items.fold<double>(
                                0,
                                (s, e) => s + e.discountAmount,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: colNet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              moneyFmt.format(_invoice.totalNetAmount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: colAction),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _emptyItemsHint() {
    final isTablet = !AppTheme.isMobileOnly(context);
    return GestureDetector(
      onTap: _addItem,
      child: Container(
        height: isTablet ? 90 : 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
          color: const Color(0xFFF5F9FF),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: isTablet ? 20 : 16,
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tap to add products',
                style: TextStyle(
                  color: const Color(0xFF1565C0),
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 15 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final isTablet = !AppTheme.isMobileOnly(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 16 : 14,
              isTablet ? 14 : 12,
              8,
              isTablet ? 14 : 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8ECF0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: isTablet ? 20 : 17,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 16 : 14,
                    color: const Color(0xFF1A202C),
                  ),
                ),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(isTablet ? 18 : 14), child: child),
        ],
      ),
    );
  }

  Widget _readonlyField(String label, String value, {IconData? trailing}) {
    final isTablet = !AppTheme.isMobileOnly(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13 : 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 10,
            vertical: isTablet ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 15 : 13.5,
                    color: const Color(0xFF1A202C),
                  ),
                ),
              ),
              if (trailing != null)
                Icon(
                  trailing,
                  size: isTablet ? 20 : 16,
                  color: const Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A202C),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }
}

// â”€â”€â”€ Item Edit Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ItemDialog extends StatefulWidget {
  final B2BInvoiceItem item;
  final String defaultHsn;
  final ValueChanged<B2BInvoiceItem> onSave;

  const _ItemDialog({
    required this.item,
    required this.defaultHsn,
    required this.onSave,
  });

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late TextEditingController _descCtrl;
  late TextEditingController _hsnCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _discCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _hsnCtrl = TextEditingController(text: widget.item.hsnCode);
    _rateCtrl = TextEditingController(
      text: widget.item.rateInclTax > 0
          ? widget.item.rateInclTax.toStringAsFixed(2)
          : '',
    );
    _qtyCtrl = TextEditingController(
      text: widget.item.quantity > 0
          ? widget.item.quantity.toStringAsFixed(
              widget.item.quantity == widget.item.quantity.toInt() ? 0 : 2,
            )
          : '',
    );
    _unitCtrl = TextEditingController(text: widget.item.unit);
    _discCtrl = TextEditingController(
      text: widget.item.discountPercent > 0
          ? widget.item.discountPercent.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    for (final c in [
      _descCtrl,
      _hsnCtrl,
      _rateCtrl,
      _qtyCtrl,
      _unitCtrl,
      _discCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSave() {
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final disc = double.tryParse(_discCtrl.text) ?? 0;
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Description is required')));
      return;
    }
    // Use copyWith so that fields not editable in this dialog (boxPieces,
    // productId, productType) are preserved from the original item.
    widget.onSave(
      widget.item.copyWith(
        description: _descCtrl.text.trim(),
        hsnCode: _hsnCtrl.text.trim().isEmpty
            ? widget.defaultHsn
            : _hsnCtrl.text.trim(),
        rateInclTax: rate,
        quantity: qty,
        unit: _unitCtrl.text.trim().isEmpty ? 'Nos' : _unitCtrl.text.trim(),
        discountPercent: disc,
        gstPercent: 0.0,
      ),
    );
    Navigator.pop(context);
  }

  // Live preview
  double get _rate => double.tryParse(_rateCtrl.text) ?? 0;
  double get _qty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _disc => double.tryParse(_discCtrl.text) ?? 0;
  double get _discAmount => (_rate * _qty) * _disc / 100;
  double get _netAmount => (_rate * _qty) - _discAmount;

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,##0.00', 'en_IN');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Product Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _dialogField(
              _descCtrl,
              'Product Description *',
              caps: TextCapitalization.characters,
            ),
            const SizedBox(height: 10),
            _dialogField(_hsnCtrl, 'HSN Code', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dialogField(
                    _rateCtrl,
                    'Rate ₹',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dialogField(
                    _qtyCtrl,
                    'Quantity',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dialogField(
                    _unitCtrl,
                    'Unit (Nos / Kg...)',
                    caps: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dialogField(
                    _discCtrl,
                    'Discount %',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Live preview box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _previewRow(
                    'Discount Amount',
                    '₹${moneyFmt.format(_discAmount)}',
                    valueColor: AppTheme.error,
                  ),
                  _previewRow(
                    'Net Amount',
                    '₹${moneyFmt.format(_netAmount)}',
                    bold: true,
                    valueColor: const Color(0xFF1B5E20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Product',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _previewRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
// â”€â”€â”€ Product Picker Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Multi-select product picker with inline quantity steppers.
/// Users set +/âˆ’ quantities for any number of products, then tap
/// "Add to Invoice" to add them all at once â€” no per-product dialog needed.
class _ProductPickerSheet extends StatefulWidget {
  final List<B2BProductOverride> catalog;
  final B2BSettings settings;
  final Set<String> alreadyAdded;
  final double initialDefaultDiscountPercent;
  final void Function(
    List<({B2BProductOverride override, double qty})> picks,
    double discountPercent,
  )
  onConfirm;
  final VoidCallback onManualEntry;

  const _ProductPickerSheet({
    required this.catalog,
    required this.settings,
    required this.alreadyAdded,
    required this.initialDefaultDiscountPercent,
    required this.onConfirm,
    required this.onManualEntry,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  late final TextEditingController _discPercentCtrl;
  String _query = '';

  /// productId â†’ chosen quantity
  final Map<String, double> _quantities = {};

  /// productId -> TextEditingController for the inline qty TextField
  final Map<String, TextEditingController> _controllers = {};

  /// productId -> whether user entered more than available stock
  final Map<String, bool> _overStock = {};

  TextEditingController _controllerFor(String productId) {
    return _controllers.putIfAbsent(productId, () => TextEditingController());
  }

  /// Tub sub-categories currently expanded (shows products)
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _discPercentCtrl = TextEditingController(
      text: widget.initialDefaultDiscountPercent > 0
          ? widget.initialDefaultDiscountPercent.toStringAsFixed(
              widget.initialDefaultDiscountPercent ==
                      widget.initialDefaultDiscountPercent.truncateToDouble()
                  ? 0
                  : 2,
            )
          : '',
    );
    // Auto-expand the first tub category
    for (final p in widget.catalog) {
      if (p.isTub && p.categoryName != null) {
        _expandedCategories.add(p.categoryName!);
        break;
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _discPercentCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // â”€â”€ Filtered helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<B2BProductOverride> get _allFiltered {
    if (_query.isEmpty) return widget.catalog;
    final q = _query.toLowerCase();
    return widget.catalog
        .where((p) => p.productName.toLowerCase().contains(q))
        .toList();
  }

  List<B2BProductOverride> get _filteredSticks =>
      _allFiltered.where((p) => p.isStick).toList();

  List<B2BProductOverride> get _filteredTubs =>
      _allFiltered.where((p) => p.isTub).toList();

  // â”€â”€ Selection state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  int get _selectedCount => _quantities.values.where((q) => q > 0).length;
  double get _totalPcs {
    double total = 0;
    for (final p in widget.catalog) {
      final qty = _quantities[p.productId] ?? 0;
      if (qty > 0) {
        total += p.isStick && p.boxPieces != null ? qty * p.boxPieces! : qty;
      }
    }
    return total;
  }

  void _confirm() {
    final picks = <({B2BProductOverride override, double qty})>[];
    for (final p in widget.catalog) {
      final qty = _quantities[p.productId] ?? 0;
      if (qty > 0) picks.add((override: p, qty: qty));
    }
    final discPercent = double.tryParse(_discPercentCtrl.text) ?? 0.0;
    Navigator.pop(context);
    widget.onConfirm(picks, discPercent);
  }

  // â”€â”€ Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _productTile(B2BProductOverride p, NumberFormat moneyFmt) {
    final b2bRate = p.b2bRateInclTax != null && p.b2bRateInclTax! > 0
        ? p.b2bRateInclTax!
        : double.tryParse(p.b2cPrice) ?? 0;
    final qty = _quantities[p.productId] ?? 0;
    final isSelected = qty > 0;
    final descKey = p.isTub && p.categoryName != null
        ? '${p.productName} (${p.categoryName})'
        : p.productName;
    final alreadyIn = widget.alreadyAdded.contains(descKey);
    final actualQtyForTotal = p.isStick && p.boxPieces != null
        ? qty * p.boxPieces!
        : qty;
    final lineTotal = b2bRate * actualQtyForTotal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: isSelected
          ? const Color(0xFFE3F2FD)
          : alreadyIn
          ? const Color(0xFFFFF8F0)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: alreadyIn ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (b2bRate > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '\u20b9${b2bRate.toStringAsFixed(0)}/Nos',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (p.hsnCode != null && p.hsnCode!.isNotEmpty)
                        Text(
                          'HSN ${p.hsnCode}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (isSelected && b2bRate > 0)
                        Text(
                          '= \u20b9${lineTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (alreadyIn)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'In invoice',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (p.availableStock != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (p.availableStock! <= 0
                                        ? Colors.red
                                        : Colors.green)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.isStick
                                ? 'Stock: ${p.availableStock} boxes'
                                : 'Stock: ${p.availableStock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.availableStock! <= 0
                                  ? Colors.red
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (p.isStick && p.boxPieces != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '1 box = ${p.boxPieces} sticks',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ] else if (p.isStick) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Default: 1 box = 1 stick',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            // Quantity input
            SizedBox(
              width: 110,
              child: TextField(
                controller: _controllerFor(p.productId),
                enabled: !(p.availableStock != null && p.availableStock! <= 0),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1565C0),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  suffixText: p.isStick ? 'box' : 'pcs',
                  suffixStyle: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _overStock[p.productId] == true
                          ? Colors.red
                          : const Color(0xFF1565C0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _overStock[p.productId] == true
                          ? Colors.red
                          : const Color(0xFF1565C0),
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  helperText: _overStock[p.productId] == true
                      ? 'Max ${p.availableStock}'
                      : null,
                  helperStyle: const TextStyle(color: Colors.red, fontSize: 11),
                ),
                onChanged: (val) {
                  final entered = double.tryParse(val) ?? 0;
                  final max = p.availableStock != null
                      ? p.availableStock!.toDouble()
                      : double.infinity;
                  if (entered > max) {
                    final maxInt = max.toInt();
                    setState(() {
                      _overStock[p.productId] = true;
                      _quantities[p.productId] = max;
                    });
                    _controllerFor(p.productId).value = TextEditingValue(
                      text: maxInt.toString(),
                      selection: TextSelection.collapsed(
                        offset: maxInt.toString().length,
                      ),
                    );
                  } else {
                    setState(() {
                      _overStock[p.productId] = false;
                      if (entered <= 0) {
                        _quantities.remove(p.productId);
                      } else {
                        _quantities[p.productId] = entered;
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryHeader(String name, int count) {
    final isExpanded = _expandedCategories.contains(name);
    // Count selected products in this category
    final selectedInCat = widget.catalog
        .where((p) => p.isTub && (p.categoryName ?? '') == name)
        .where((p) => (_quantities[p.productId] ?? 0) > 0)
        .length;
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCategories.remove(name);
          } else {
            _expandedCategories.add(name);
          }
        });
      },
      child: Container(
        color: const Color(0xFFF0F4FF),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            const Icon(
              Icons.kitchen_outlined,
              size: 18,
              color: Color(0xFF1565C0),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            if (selectedInCat > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$selectedInCat sel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              '$count items',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1565C0),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSticksTab(
    List<B2BProductOverride> sticks,
    NumberFormat moneyFmt,
  ) {
    if (sticks.isEmpty) {
      return const Center(
        child: Text('No stick products', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: sticks.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 0.5, indent: 16, endIndent: 0),
      itemBuilder: (_, i) => _productTile(sticks[i], moneyFmt),
    );
  }

  Widget _buildTubsTab(List<B2BProductOverride> tubs, NumberFormat moneyFmt) {
    if (tubs.isEmpty) {
      return const Center(
        child: Text('No tub products', style: TextStyle(color: Colors.grey)),
      );
    }
    // Group by categoryName
    final seen = <String>{};
    final catOrder = <String>[];
    for (final p in tubs) {
      final cat = p.categoryName ?? 'Uncategorised';
      if (seen.add(cat)) catOrder.add(cat);
    }

    // When searching, auto-expand all matching categories
    if (_query.isNotEmpty) {
      for (final cat in catOrder) {
        _expandedCategories.add(cat);
      }
    }

    final rows = <Widget>[];
    for (final cat in catOrder) {
      final catProducts = tubs
          .where((p) => (p.categoryName ?? 'Uncategorised') == cat)
          .toList();
      rows.add(_categoryHeader(cat, catProducts.length));
      if (_expandedCategories.contains(cat)) {
        for (int i = 0; i < catProducts.length; i++) {
          rows.add(_productTile(catProducts[i], moneyFmt));
          if (i < catProducts.length - 1) {
            rows.add(const Divider(height: 0.5, indent: 16));
          }
        }
      }
    }
    return ListView(padding: EdgeInsets.zero, children: rows);
  }

  Widget _buildConfirmBar() {
    return Container(
      color: const Color(0xFF1565C0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_selectedCount product${_selectedCount == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_totalPcs.toInt()} pcs total',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Add to Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final moneyFmt = NumberFormat('#,##0.00', 'en_IN');
    final stickCount = widget.catalog.where((p) => p.isStick).length;
    final tubCount = widget.catalog.where((p) => p.isTub).length;

    return DefaultTabController(
      length: 2,
      child: Container(
        height: screenH * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF1565C0),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select Products',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onManualEntry();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Manual'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),

            // Search bar + default disc%
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search products…',
                        prefixIcon: const Icon(Icons.search, size: 22),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Default Discount - Enhanced styling
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1565C0).withValues(alpha: 0.1),
                          const Color(0xFF0D47A1).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 55,
                          height: 38,
                          child: TextField(
                            controller: _discPercentCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1565C0),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0D47A1),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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

            // Tabs
            TabBar(
              tabs: [
                Tab(text: 'Sticks ($stickCount)'),
                Tab(text: 'Tubs ($tubCount)'),
              ],
              labelColor: const Color(0xFF1565C0),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1565C0),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const Divider(height: 0.5),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildSticksTab(_filteredSticks, moneyFmt),
                  _buildTubsTab(_filteredTubs, moneyFmt),
                ],
              ),
            ),

            // Confirm action bar â€” shown only when something is selected
            if (_selectedCount > 0) _buildConfirmBar(),
          ],
        ),
      ),
    );
  }
}
