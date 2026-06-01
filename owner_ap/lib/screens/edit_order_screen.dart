import 'dart:async';
import 'package:flutter/material.dart';
import '../services/base_api_service.dart';
import 'orders_screen.dart';

// Exact same design tokens as woffle_menu_page.dart
class _C {
  static const primary          = Color(0xFFFF8C00);
  static const primaryLight     = Color(0xFFFFF3E0);
  static const background       = Color(0xFFF5F5F0);
  static const cardBg           = Colors.white;
  static const imageBg          = Color(0xFFEDE8E1);
  static const pillBg           = Color(0xFFF0EDE8);
  static const textDark         = Color(0xFF1C1917);
  static const textMid          = Color(0xFF57534E);
  static const textLight        = Color(0xFF9CA3AF);
  static const chipUnselected   = Color(0xFFF0EDE8);
}

class EditOrderScreen extends StatefulWidget {
  /// Pass an existing order to edit it, or null to create a new order.
  final OrderItem? order;

  const EditOrderScreen({super.key, this.order});

  bool get isCreateMode => order == null;

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen>
    with SingleTickerProviderStateMixin {
  // Data
  List<Map<String, dynamic>> _allProducts = [];
  List<_CartEntry> _cart = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // For create mode: holds the newly created order id after first save
  int? _createdOrderId;

  // Totals
  double _totalPrice = 0.0;
  int _totalPieces = 0;

  // Controllers — same as woffle_menu_page
  late AnimationController _fabAnimController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Debounce timer for auto-save on quantity change
  Timer? _saveDebounce;

  int? get _orderId {
    if (_createdOrderId != null) return _createdOrderId;
    if (widget.order == null) return null;
    final rawId = widget.order!.id;
    return int.tryParse(rawId) ??
        int.tryParse(
          RegExp(r'\d+').firstMatch(rawId)?.group(0) ?? '',
        );
  }

  String get _displayTitle {
    if (widget.isCreateMode) return 'New Order';
    final num = widget.order!.orderNumber;
    if (num != null && num.trim().isNotEmpty) {
      final clean = num.trim();
      return clean.startsWith('#') ? 'Order $clean' : 'Order #$clean';
    }
    return 'Order ${widget.order!.displayOrderNumber}';
  }

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _fabAnimController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Called after every cart change in edit mode — debounced PUT.
  void _scheduleAutoSave() {
    if (widget.isCreateMode) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () async {
      await _autoSaveExistingOrder();
    });
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await BaseApiService.get('/products/menu/');
      if (response is Map<String, dynamic>) {
        final cats = <String>['All'];
        final allProducts = <Map<String, dynamic>>[];
        for (final entry in response.entries) {
          final categoryName = entry.key;
          cats.add(categoryName);
          if (entry.value is List) {
            for (final p in (entry.value as List)) {
              if (p is Map<String, dynamic>) {
                allProducts.add({...p, '_categoryName': categoryName});
              }
            }
          }
        }
        setState(() {
          _allProducts = allProducts;
          _categories = cats;
          _isLoading = false;
        });
        if (!widget.isCreateMode) {
          _populateCartFromOrder(allProducts);
        }
        _fabAnimController.forward();
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _populateCartFromOrder(List<Map<String, dynamic>> products) {
    final entries = <_CartEntry>[];
    for (final itemStr in widget.order!.items) {
      final qtyMatch  = RegExp(r'Quantity:\s*(\d+)').firstMatch(itemStr);
      final nameMatch = RegExp(r'ProductName:\s*([^,}]+)').firstMatch(itemStr);
      final priceMatch = RegExp(r'PriceAtPurchase:\s*([\d.]+)').firstMatch(itemStr);
      final idMatch   = RegExp(r'ProductID:\s*(\d+)').firstMatch(itemStr);

      final qty   = int.tryParse(qtyMatch?.group(1) ?? '1') ?? 1;
      final name  = nameMatch?.group(1)?.trim() ?? itemStr;
      final price = double.tryParse(priceMatch?.group(1) ?? '0') ?? 0;
      final pid   = int.tryParse(idMatch?.group(1) ?? '');

      Map<String, dynamic>? match;
      if (pid != null) {
        final pidStr = pid.toString();
        match = products.cast<Map<String, dynamic>?>().firstWhere(
          (p) => p != null &&
              (p['ID']?.toString() == pidStr || p['id']?.toString() == pidStr),
          orElse: () => null,
        );
      }
      match ??= products.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p != null &&
            p['Name']?.toString().trim().toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );

      if (match != null) {
        entries.add(_CartEntry(
          product: match,
          quantity: qty,
          priceOverride: price > 0 ? price : null,
        ));
      }
    }
    if (entries.isNotEmpty) {
      setState(() => _cart = entries);
      _updateTotals();
    }
  }

  void _updateTotals() {
    _totalPrice = _cart.fold(
      0.0,
      (sum, e) => sum + (e.priceOverride ?? _toDouble(e.product['Price'])) * e.qty,
    );
    _totalPieces = _cart.fold(0, (sum, e) => sum + e.qty);
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final q = _searchController.text.toLowerCase();
    return _allProducts.where((p) {
      final name = p['Name']?.toString().toLowerCase() ?? '';
      final matchesSearch = q.isEmpty || name.contains(q);
      final matchesCat = _selectedCategory == 'All' ||
          p['_categoryName']?.toString() == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _addProduct(Map<String, dynamic> product) {
    final idx = _cart.indexWhere((e) => e.product['ID'] == product['ID']);
    setState(() {
      if (idx >= 0) {
        _cart[idx].qty++;
      } else {
        _cart.add(_CartEntry(product: product, quantity: 1));
      }
      _updateTotals();
    });
    if (_totalPieces == 1) _fabAnimController.forward();
    _scheduleAutoSave();
  }

  void _decreaseProduct(Map<String, dynamic> product) {
    final idx = _cart.indexWhere((e) => e.product['ID'] == product['ID']);
    if (idx < 0) return;
    setState(() {
      if (_cart[idx].qty > 1) {
        _cart[idx].qty--;
      } else {
        _cart.removeAt(idx);
      }
      _updateTotals();
    });
    _scheduleAutoSave();
  }

  List<Map<String, dynamic>> get _cartPayload => _cart.map((e) => {
    'ProductID': e.product['ID'],
    'Quantity': e.qty,
    'PriceAtPurchase': e.priceOverride ?? _toDouble(e.product['Price']),
  }).toList();

  /// Creates a new pending order via POST. Returns the new order id on success.
  Future<int?> _createPendingOrder() async {
    if (_cart.isEmpty) return null;
    final totalQty = _cart.fold<int>(0, (s, e) => s + e.qty);
    try {
      final response = await BaseApiService.post('/orders/create/', {
        'UpiAmount': 0,
        'CashAmount': 0,
        'TotalQuantity': totalQty,
        'Completed': false,
        'OrderItems': _cartPayload,
      });
      return (response['order_id'] as num?)?.toInt();
    } catch (e) {
      debugPrint('[EditOrderScreen] POST failed: $e');
      return null;
    }
  }

  /// Saves (PUT) changes to an existing order without completing it.
  Future<void> _autoSaveExistingOrder() async {
    final id = _orderId;
    if (id == null || _cart.isEmpty) return;
    final totalQty = _cart.fold<int>(0, (s, e) => s + e.qty);
    try {
      await BaseApiService.put('/orders/$id/update/', {
        'UpiAmount': 0,
        'CashAmount': 0,
        'TotalQuantity': totalQty,
        'Completed': false,
        'OrderItems': _cartPayload,
      });
      debugPrint('[EditOrderScreen] Auto-saved order $id (${_cart.length} items)');
    } catch (e) {
      debugPrint('[EditOrderScreen] Auto-save PUT failed for order $id: $e');
    }
  }

  /// Called when the back button is pressed.
  Future<void> _handleBack() async {
    // Cancel any pending debounced save — we do a synchronous save below
    _saveDebounce?.cancel();
    _saveDebounce = null;

    if (_cart.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    if (widget.isCreateMode) {
      // Create mode: POST a pending order then go back
      setState(() => _isSaving = true);
      final newId = await _createPendingOrder();
      if (mounted) setState(() => _isSaving = false);
      if (!mounted) return;
      if (newId != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order saved as pending'),
          backgroundColor: Color(0xFF4CAF50),
        ));
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop(false);
      }
    } else {
      // Edit mode: PUT to update the existing order as pending
      setState(() => _isSaving = true);
      await _autoSaveExistingOrder();
      if (mounted) setState(() => _isSaving = false);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveOrder({bool completed = false, double upi = 0, double cash = 0}) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one product'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final totalQty = _cart.fold<int>(0, (s, e) => s + e.qty);
      final payload = {
        'UpiAmount': upi,
        'CashAmount': cash,
        'TotalQuantity': totalQty,
        'Completed': completed,
        'OrderItems': _cartPayload,
      };

      if (widget.isCreateMode) {
        // Create mode: POST
        final response = await BaseApiService.post('/orders/create/', payload);
        _createdOrderId = (response['order_id'] as num?)?.toInt();
      } else {
        // Edit mode: PUT — cancel debounce first to avoid double-save
        _saveDebounce?.cancel();
        _saveDebounce = null;
        final id = _orderId;
        if (id == null) return;
        await BaseApiService.put('/orders/$id/update/', payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(completed ? 'Order marked as complete!' : 'Order saved successfully'),
        backgroundColor: const Color(0xFF4CAF50),
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showCompleteDialog() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one product first'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final orderId = widget.isCreateMode ? 'New Order' : widget.order!.displayOrderNumber;
    final customerName = widget.isCreateMode ? '' : widget.order!.customerName;
    await showDialog(
      context: context,
      builder: (ctx) => _CompleteOrderDialog(
        orderId: orderId,
        customerName: customerName,
        cart: _cart,
        totalPrice: _totalPrice,
        onConfirm: (upi, cash) => _saveOrder(
          completed: true,
          upi: upi,
          cash: cash,
        ),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleBack();
      },
      child: Scaffold(
        backgroundColor: _C.background,
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchBar(),
                            _buildCategoryChips(),
                            _buildSectionHeader(),
                            Expanded(child: _buildProductsGrid()),
                          ],
                        ),
            ),
          ],
        ),
        floatingActionButton:
            _totalPieces > 0 ? _buildFloatingCartSummary() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: _C.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _C.primary),
                      ),
                    )
                  : IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: _C.textDark, size: 20),
                    ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayTitle,
                      style: const TextStyle(
                        color: _C.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_totalPieces > 0)
                      Text(
                        '$_totalPieces items · ₹${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _C.textMid,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _showCompleteDialog,
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: _C.primary.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search bar — exact match ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: _C.textDark),
        decoration: InputDecoration(
          hintText: 'Search menu items…',
          hintStyle: const TextStyle(color: _C.textLight, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded,
              color: _C.textLight, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _C.textLight, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: _C.chipUnselected,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _C.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Category chips — exact match ────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _C.primary : _C.chipUnselected,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _C.textMid,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Section header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader() {
    final label =
        _selectedCategory == 'All' ? 'All Items' : _selectedCategory;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _C.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_filteredProducts.length})',
            style: const TextStyle(color: _C.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Product grid — exact match ───────────────────────────────────────────

  Widget _buildProductsGrid() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No items found',
                style: TextStyle(color: _C.textLight, fontSize: 15)),
          ],
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final crossAxisCount = w >= 1200 ? 6 : w >= 900 ? 4 : w >= 600 ? 4 : 2;
    const cardHeight = 195.0;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: cardHeight,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _buildProductCard(products[i]),
    );
  }

  // ─── Product card — exact match of woffle_menu_page ──────────────────────

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['Name']?.toString() ?? '—';
    final priceStr = _toDouble(product['Price']).toStringAsFixed(0);
    final pid = product['ID'];
    final entry = _cart.cast<_CartEntry?>().firstWhere(
          (e) => e?.product['ID'] == pid,
          orElse: () => null,
        );
    final quantity = entry?.qty ?? 0;

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    final imageUrl = product['image_url']?.toString();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ~65% ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsBox(initials),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _initialsBox(initials),
                    )
                  : _initialsBox(initials),
            ),
          ),

          // ── Name · Price (one compact line) ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(
              '$name · ₹$priceStr',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.textDark,
              ),
            ),
          ),

          // ── Quantity pill (full width) ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
            child: quantity == 0
                ? GestureDetector(
                    onTap: () => _addProduct(product),
                    child: Container(
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _C.pillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.primary,
                        ),
                      ),
                    ),
                  )
                : _buildQuantityPill(quantity: quantity, product: product),
          ),
        ],
      ),
    );
  }

  // ─── Quantity pill — exact match ─────────────────────────────────────────

  Widget _buildQuantityPill({
    required int quantity,
    required Map<String, dynamic> product,
  }) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          // Left cream pill: minus + count
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: _C.pillBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  // Minus button
                  GestureDetector(
                    onTap: () => _decreaseProduct(product),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      child: const Icon(Icons.remove_rounded,
                          size: 14, color: _C.textMid),
                    ),
                  ),
                  // Count
                  Expanded(
                    child: Center(
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Right solid orange circle: plus only
          GestureDetector(
            onTap: () => _addProduct(product),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: _C.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Initials placeholder (fallback when no product image) ──────────────

  Widget _initialsBox(String initials) {
    return Container(
      color: _C.imageBg,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFFB66F1A),
          ),
        ),
      ),
    );
  }

  // ─── Floating cart FAB — exact match ─────────────────────────────────────

  Widget _buildFloatingCartSummary() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _fabAnimController,
        curve: Curves.easeOutBack,
      )),
      child: GestureDetector(
        onTap: _showCompleteDialog,
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_totalPieces item${_totalPieces == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${_totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Save Order →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Loading / Error states ───────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(_C.primary)),
          SizedBox(height: 16),
          Text('Loading menu…',
              style: TextStyle(color: _C.textMid, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: _C.textLight),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textDark, fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartEntry {
  Map<String, dynamic> product;
  int qty;
  double? priceOverride;

  _CartEntry({
    required this.product,
    required int quantity,
    this.priceOverride,
  }) : qty = quantity;
}

// ─── Complete Order Dialog — exact replica of woffle_order_detail_dialog ─────

class _CompleteOrderDialog extends StatefulWidget {
  final String orderId;
  final String customerName;
  final List<_CartEntry> cart;
  final double totalPrice;
  final void Function(double upi, double cash) onConfirm;

  const _CompleteOrderDialog({
    required this.orderId,
    required this.customerName,
    required this.cart,
    required this.totalPrice,
    required this.onConfirm,
  });

  @override
  State<_CompleteOrderDialog> createState() => _CompleteOrderDialogState();
}

class _CompleteOrderDialogState extends State<_CompleteOrderDialog> {
  late String _payMode;
  late TextEditingController _cashCtrl;
  late TextEditingController _upiCtrl;
  late FocusNode _cashFocus;
  late FocusNode _upiFocus;
  String? _error;
  bool _editingCash = false;
  bool _editingUPI  = false;

  @override
  void initState() {
    super.initState();
    _payMode  = 'Cash';
    _cashCtrl = TextEditingController(
        text: widget.totalPrice.toStringAsFixed(2));
    _upiCtrl  = TextEditingController();
    _cashFocus = FocusNode();
    _upiFocus  = FocusNode();
    _cashCtrl.addListener(_onCashChanged);
    _upiCtrl.addListener(_onUpiChanged);
  }

  @override
  void dispose() {
    _cashCtrl.removeListener(_onCashChanged);
    _upiCtrl.removeListener(_onUpiChanged);
    _cashCtrl.dispose();
    _upiCtrl.dispose();
    _cashFocus.dispose();
    _upiFocus.dispose();
    super.dispose();
  }

  void _switchMode(String mode) {
    setState(() {
      _payMode = mode;
      _error   = null;
      if (mode == 'Cash') {
        _cashCtrl.text = widget.totalPrice.toStringAsFixed(2);
        _upiCtrl.text  = '';
      } else if (mode == 'UPI') {
        _upiCtrl.text  = widget.totalPrice.toStringAsFixed(2);
        _cashCtrl.text = '';
      } else {
        _cashCtrl.text = '';
        _upiCtrl.text  = '';
      }
    });
  }

  void _onUpiChanged() {
    if (_payMode == 'Both' && !_editingCash) {
      _editingUPI = true;
      final upi  = double.tryParse(_upiCtrl.text) ?? 0;
      final cash = (widget.totalPrice - upi).clamp(0, widget.totalPrice);
      if (_upiCtrl.text.isNotEmpty) _cashCtrl.text = cash.toStringAsFixed(2);
      _editingUPI = false;
    }
  }

  void _onCashChanged() {
    if (_payMode == 'Both' && !_editingUPI) {
      _editingCash = true;
      final cash = double.tryParse(_cashCtrl.text) ?? 0;
      final upi  = (widget.totalPrice - cash).clamp(0, widget.totalPrice);
      if (_cashCtrl.text.isNotEmpty) _upiCtrl.text = upi.toStringAsFixed(2);
      _editingCash = false;
    }
  }

  void _submit() {
    double upi = 0, cash = 0;
    if (_payMode == 'Cash') {
      cash = double.tryParse(_cashCtrl.text) ?? 0;
    } else if (_payMode == 'UPI') {
      upi = double.tryParse(_upiCtrl.text) ?? 0;
    } else {
      cash = double.tryParse(_cashCtrl.text) ?? 0;
      upi  = double.tryParse(_upiCtrl.text)  ?? 0;
    }
    final total = upi + cash;
    if ((total - widget.totalPrice).abs() > 0.5) {
      setState(() => _error =
          'Total must match ₹${widget.totalPrice.toStringAsFixed(0)}');
      return;
    }
    Navigator.of(context).pop();
    widget.onConfirm(upi, cash);
  }

  int get _totalPcs => widget.cart.fold(0, (s, e) => s + e.qty);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet    = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: isTablet ? 500 : 380,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Orange gradient header ─────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // Emoji box
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('??',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Order ID
                    Expanded(
                      child: Text(
                        widget.orderId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // PENDING pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('PENDING',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    // Close X
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Items header ─────────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded,
                              size: 18, color: _C.textDark),
                          const SizedBox(width: 6),
                          Text(
                            'Items (${widget.cart.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _C.textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_totalPcs pcs',
                            style: const TextStyle(
                                color: _C.textLight, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Items table ───────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(28),
                            1: FlexColumnWidth(3),
                            2: FixedColumnWidth(40),
                            3: FixedColumnWidth(70),
                            4: FixedColumnWidth(72),
                          },
                          children: [
                            // Header row
                            TableRow(
                              decoration: const BoxDecoration(
                                  color: Color(0xFF546E7A)),
                              children: [
                                '#', 'Item', 'Qty', 'Price', 'Amount'
                              ].map((h) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 8),
                                child: Text(h,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    )),
                              )).toList(),
                            ),
                            // Data rows
                            ...widget.cart.asMap().entries.map((entry) {
                              final idx  = entry.key;
                              final item = entry.value;
                              final name  = item.product['Name']?.toString() ?? '—';
                              final price = item.priceOverride ??
                                  (double.tryParse(
                                          item.product['Price']?.toString() ?? '0') ??
                                      0);
                              final amount = price * item.qty;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: idx.isEven
                                      ? Colors.white
                                      : const Color(0xFFF5F7FA),
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade200),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 8),
                                    child: Text('${idx + 1}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _C.textMid)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 8),
                                    child: Text(name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _C.textDark)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 8),
                                    child: Text('${item.qty}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _C.textDark)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 8),
                                    child: Text(
                                        '₹${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _C.textDark)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 8),
                                    child: Text(
                                        '₹${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _C.textDark,
                                        )),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Blue total card ───────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE3F2FD),
                              Color(0xFFBBDEFB)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textDark,
                                )),
                            Text(
                              '₹${widget.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Payment Method ────────────────────────────
                      const Text('Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _C.textDark,
                          )),
                      const SizedBox(height: 10),

                      // Cash / UPI / Both chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _chip('Cash',
                              Icons.payments,
                              Colors.green),
                          _chip('UPI',
                              Icons.qr_code,
                              Colors.blue),
                          _chip('Both',
                              Icons.swap_horiz,
                              Colors.deepPurple),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Amount fields
                      if (_payMode == 'Cash' || _payMode == 'Both')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: _cashCtrl,
                            focusNode: _cashFocus,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(
                              labelText: 'Cash Amount',
                              prefixText: '₹',
                              helperText:
                                  'Enter the cash received from customer',
                            ),
                          ),
                        ),
                      if (_payMode == 'UPI' || _payMode == 'Both')
                        TextField(
                          controller: _upiCtrl,
                          focusNode: _upiFocus,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            labelText: 'UPI Amount',
                            prefixText: '₹',
                            helperText: 'Enter the UPI payment amount',
                          ),
                        ),

                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ],
                      const SizedBox(height: 16),

                      // ── Mark Complete button ──────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(
                              Icons.check_circle_rounded, size: 20),
                          label: const Text('Mark Complete',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color selectedColor) {
    final selected = _payMode == label;
    return ChoiceChip(
      avatar: Icon(icon,
          color: selected ? Colors.white : Colors.grey, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 14)),
      selected: selected,
      selectedColor: selectedColor,
      onSelected: (_) => _switchMode(label),
    );
  }
}
