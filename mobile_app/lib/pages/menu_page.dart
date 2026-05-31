import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/optimized_image_service.dart';
import '../models/menu.dart';
import '../models/order.dart';
import '../widgets/order_detail_dialog.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _Colors {
  static const primary          = Color(0xFFFF8C00);
  static const primaryLight     = Color(0xFFFFF3E0);
  static const background       = Color(0xFFF5F5F0);
  static const cardBg           = Colors.white;
  static const imageBg          = Color(0xFFEDE8E1);
  static const pillBg           = Color(0xFFF0EDE8);
  static const textDark         = Color(0xFF1C1917);
  static const textMid          = Color(0xFF57534E);
  static const textLight        = Color(0xFF9CA3AF);
  static const chipUnselectedBg = Color(0xFFF0EDE8);
}

class MenuPage extends StatefulWidget {
  final int orderId;
  final int? orderIndex;
  final List<OrderItem>? initialOrderItems;

  const MenuPage({
    super.key,
    required this.orderId,
    this.orderIndex,
    this.initialOrderItems,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  Menu? _menu;
  List<OrderItem> _currentOrderItems = [];
  bool _isLoading = true;
  String _error = '';
  double _totalPrice = 0.0;
  int _totalPieces = 0;

  // Animation controllers
  AnimationController? _cartAnimationController;
  AnimationController? _fabAnimationController;
  final Map<String, AnimationController> _productAnimationControllers = {};

  // Category and search functionality
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // UI state
  bool _isApiCallInFlight = false;
  bool _suppressDeleteOnPop = false;
  Map<String, int> _quantityMap = {};

  Future<bool> _syncOrderBeforePop() async {
    if (_isApiCallInFlight) return false;
    if (_currentOrderItems.isEmpty) return true;

    _isApiCallInFlight = true;
    try {
      final orderItemsPayload = _currentOrderItems.map((item) {
        return {
          'ProductID': item.itemId,
          'Quantity': item.pieces,
          'PriceAtPurchase': item.price,
        };
      }).toList();

      debugPrint('Sync order before pop orderId=${widget.orderId} items=$orderItemsPayload');

      await ApiService.updateOrderWithItems(
        widget.orderId,
        totalQuantity: _totalPieces,
        orderItems: orderItemsPayload,
        upiAmount: 0.0,
        cashAmount: 0.0,
        completed: false,
      );

      // Prevent delete on pop because we synced items successfully
      _suppressDeleteOnPop = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to sync order before pop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save order items — try again')),
        );
      }
      return false;
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Future<bool> _handleWillPop() async {
    if (_suppressDeleteOnPop) {
      return true;
    }

    if (_currentOrderItems.isNotEmpty) {
      return await _syncOrderBeforePop();
    }

    try {
      await ApiService.deleteOrder(widget.orderId);
    } catch (_) {
      // Ignore delete errors on empty order cleanup.
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.initialOrderItems != null) {
      _currentOrderItems = List<OrderItem>.from(widget.initialOrderItems!);
      _updateTotals();
    }

    _loadMenu();
  }

  void _initializeAnimations() {
    _cartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _cartAnimationController?.dispose();
    _fabAnimationController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    for (final controller in _productAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final menu = await ApiService.getMenu(
        forceRefresh: true,
        excludeOrder: widget.orderId,
      );

      setState(() {
        _menu = menu;
        _isLoading = false;
      });

      _extractCategories(menu);
      _preloadAllProductImages(menu);
      await _loadCurrentOrder();
      
      // Trigger initial animations
      _fabAnimationController?.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _extractCategories(Menu menu) {
    final Set<String> categorySet = {'All'};
    
    // Extract categories from ice sticks
    for (final categories in menu.iceSticks.values) {
      for (final category in categories) {
        categorySet.add(category.name);
      }
    }

    setState(() {
      _categories = categorySet.toList()..sort();
    });
  }

  /// Collect every product image URL from the menu and preload them all
  /// concurrently so they're in the disk/memory cache before the user
  /// sees placeholder spinners.
  void _preloadAllProductImages(Menu menu) {
    final List<String> urls = [];

    // Ice Stick products
    for (final categories in menu.iceSticks.values) {
      for (final category in categories) {
        for (final product in category.products) {
          if (product.image != null && product.image!.isNotEmpty) {
            urls.add(product.image!);
          }
        }
      }
    }

    if (urls.isNotEmpty) {
      // Fire-and-forget — downloads happen in the background with
      // controlled concurrency (6 parallel downloads at a time).
      OptimizedImageService.preloadImages(urls, concurrency: 8);
    }
  }

  Future<void> _loadCurrentOrder() async {
    try {
      // Fetch only this order instead of the entire daily summary
      final currentOrder = await ApiService.getOrderById(widget.orderId);

      setState(() {
        _currentOrderItems = currentOrder.items.map((item) {
          return OrderItem(
            itemId: item.itemId,
            orderItemId: item.orderItemId,
            product: item.product,
            price: item.price,
            pieces: item.pieces,
            productType: item.productType,
          );
        }).toList();
        _updateTotals();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading current order: $e');
    }
  }

  int _getProductQuantity(Product product) {
    return _quantityMap[product.name.trim().toLowerCase()] ?? 0;
  }



  void _updateTotals() {
    _totalPrice = _currentOrderItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    _totalPieces = _currentOrderItems.fold(0, (sum, item) => sum + item.pieces);

    final map = <String, int>{};
    for (final item in _currentOrderItems) {
      final key = item.product.trim().toLowerCase();
      map[key] = (map[key] ?? 0) + item.pieces;
    }
    _quantityMap = map;

    // Trigger cart animation
    _cartAnimationController?.forward().then((_) {
      _cartAnimationController?.reverse();
    });
  }

  void _animateProduct(String productKey) {
    if (!_productAnimationControllers.containsKey(productKey)) {
      _productAnimationControllers[productKey] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }

    final controller = _productAnimationControllers[productKey]!;
    controller.forward().then((_) {
      controller.reverse();
    });
  }

  
  OrderItem? _getOrderItem(Product product) {
    final target = product.name.trim().toLowerCase();
    final idx = _currentOrderItems.indexWhere(
      (item) => item.product.trim().toLowerCase() == target,
    );
    return idx >= 0 ? _currentOrderItems[idx] : null;
  }

  List<Product> _getFilteredProducts() {
    if (_menu == null) return [];

    List<Product> allProducts = [];

    // Get products based on selected category
    if (_selectedCategory == 'All') {
      // Get all products from all categories
      for (final categories in _menu!.iceSticks.values) {
        for (final category in categories) {
          allProducts.addAll(category.products);
        }
      }
    } else {
      // Get products from specific category
      for (final categories in _menu!.iceSticks.values) {
        for (final category in categories) {
          if (category.name == _selectedCategory) {
            allProducts = category.products;
            break;
          }
        }
      }
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      allProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Remove duplicates based on name
    final Map<String, Product> uniqueProducts = {};
    for (final product in allProducts) {
      final String productName = product.name.toLowerCase();
      if (!uniqueProducts.containsKey(productName)) {
        uniqueProducts[productName] = product;
      }
    }

    return uniqueProducts.values.toList();
  }

  



  // ── UI Components ──────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _Colors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final shouldPop = await _handleWillPop();
                  if (shouldPop && mounted) navigator.pop();
                },
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: _Colors.textDark, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.orderIndex != null
                          ? 'Order #${widget.orderIndex}'
                          : 'Order #${widget.orderId}',
                      style: const TextStyle(
                        color: _Colors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_totalPieces > 0)
                      Text(
                        '$_totalPieces items • ₹${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _Colors.textMid,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showOrderDetails,
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: _Colors.primary.withValues(alpha: 0.45),
                  padding: const EdgeInsets.only(
                      left: 16, right: 22, top: 14, bottom: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: _Colors.textDark),
        decoration: InputDecoration(
          hintText: 'Search menu items…',
          hintStyle:
              const TextStyle(color: _Colors.textLight, fontSize: 15),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _Colors.textLight, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _Colors.textLight, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: _Colors.chipUnselectedBg,
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
            borderSide:
                const BorderSide(color: _Colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? _Colors.primary
                    : _Colors.chipUnselectedBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _Colors.textMid,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Product product) {
    final quantity   = _getProductQuantity(product);
    final orderItem  = _getOrderItem(product);
    final isActive   = product.active != false;
    final productKey = 'product_${product.name}';
    final priceAmt   =
        double.tryParse(product.price.toString())?.toStringAsFixed(0)
        ?? product.price.toString();

    return Container(
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Expanded image + fixed-height footer = fills mainAxisExtent exactly.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image (takes all remaining vertical space) ────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.image != null && product.image!.isNotEmpty
                      ? OptimizedImageService.optimizedNetworkImage(
                          imageUrl: product.image!,
                          width: 300,
                          height: 220,
                          fit: BoxFit.cover,
                          errorWidget: _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  if (!isActive)
                    Container(
                      color: Colors.black.withValues(alpha: 0.52),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Unavailable',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Footer: name-price + quantity pill (fixed height) ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Name - price" on one line, wraps to 2 lines max
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _Colors.textDark,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: product.name),
                      TextSpan(
                        text: ' - ',
                        style: TextStyle(color: _Colors.textMid),
                      ),
                      TextSpan(
                        text: '\u20b9$priceAmt',
                        style: const TextStyle(color: _Colors.textDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                // Quantity bar
                if (!isActive)
                  Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _Colors.pillBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Unavailable',
                      style: TextStyle(
                          color: _Colors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  _buildQuantityPill(
                    quantity: quantity,
                    orderItem: orderItem,
                    product: product,
                    productKey: productKey,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _Colors.imageBg,
      child: const Center(
        child: Icon(Icons.restaurant_menu_rounded,
            color: Color(0xFFC4B5A5), size: 34),
      ),
    );
  }

  Widget _buildQuantityPill({
    required int quantity,
    required OrderItem? orderItem,
    required Product product,
    required String productKey,
  }) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          // Left: cream pill — minus button + count
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: _Colors.pillBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: quantity > 0 && orderItem != null
                        ? () {
                            _decreaseQuantity(orderItem);
                            _animateProduct(productKey);
                          }
                        : null,
                    child: SizedBox(
                      width: 34,
                      height: double.infinity,
                      child: Center(
                        child: Icon(
                          Icons.remove_rounded,
                          size: 15,
                          color: quantity > 0
                              ? _Colors.textMid
                              : _Colors.textLight,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _Colors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Right: solid orange circle — plus only
          GestureDetector(
            onTap: () {
              _addProductToOrder(product);
              _animateProduct(productKey);
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: _Colors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    final label = _selectedCategory == 'All'
        ? 'All Items'
        : _selectedCategory;
    final products = _getFilteredProducts();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _Colors.textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _Colors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${products.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    final filteredProducts = _getFilteredProducts();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'No items found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _Colors.textMid),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different category or search term',
              style: TextStyle(fontSize: 13, color: _Colors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final crossAxisCount = MediaQuery.of(context).size.width >= 900
        ? 4
        : MediaQuery.of(context).size.width >= 600
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 240,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) =>
          _buildItemCard(context, filteredProducts[index]),
    );
  }

  Future<void> _addProductToOrder(Product product) async {
    if (_isApiCallInFlight) return;

    _isApiCallInFlight = true;
    final productKey = 'product_${product.name}';
    
    try {
      final existingIndex = _currentOrderItems.indexWhere(
        (item) =>
            item.product.trim().toLowerCase() ==
            product.name.trim().toLowerCase(),
      );

      if (existingIndex >= 0) {
        setState(() {
          _currentOrderItems[existingIndex] = OrderItem(
            itemId: _currentOrderItems[existingIndex].itemId,
            orderItemId: _currentOrderItems[existingIndex].orderItemId,
            product: _currentOrderItems[existingIndex].product,
            price: _currentOrderItems[existingIndex].price,
            pieces: _currentOrderItems[existingIndex].pieces + 1,
            productType: _currentOrderItems[existingIndex].productType,
          );
          _updateTotals();
        });
      } else {
        setState(() {
          _currentOrderItems.add(OrderItem(
            itemId: int.tryParse(product.productId) ?? 0,
            orderItemId: null,
            product: product.name,
            price: product.price,
            pieces: 1,
            productType: 'ice_sticks',
          ));
          _updateTotals();
        });
      }
      
      _animateProduct(productKey);
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding product: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }





  Future<void> _decreaseQuantity(OrderItem item) async {
    if (_isApiCallInFlight) return;
    _isApiCallInFlight = true;
    try {
      final idx = _currentOrderItems.indexWhere(
        (i) => (i.orderItemId ?? i.itemId) == (item.orderItemId ?? item.itemId),
      );
      if (idx >= 0) {
        setState(() {
          if (_currentOrderItems[idx].pieces > 1) {
            _currentOrderItems[idx] = OrderItem(
              itemId: _currentOrderItems[idx].itemId,
              orderItemId: _currentOrderItems[idx].orderItemId,
              product: _currentOrderItems[idx].product,
              price: _currentOrderItems[idx].price,
              pieces: _currentOrderItems[idx].pieces - 1,
              productType: _currentOrderItems[idx].productType,
            );
          } else {
            _currentOrderItems.removeAt(idx);
          }
          _updateTotals();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error decreasing quantity: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Future<void> _showOrderDetails() async {
    if (_currentOrderItems.isEmpty) {
      // Order empty notification removed per user request
      return;
    }

    // Create order with current data (since getOrder API is no longer available)
    final order = Order(
      orderId: widget.orderId,
      orderLabel: '#ORD-${widget.orderId}',
      items: _currentOrderItems,
      price: _totalPrice.toStringAsFixed(2),
      totalAmount: _totalPrice.toStringAsFixed(2),
      upiAmount: '0.0',
      cashAmount: '0.0',
      paymentMethod: '',
      customerName: '',
      status: 'Pending',
      displayIndex: widget.orderIndex ?? 0,
      emoji: '🍦', // Default emoji
      color: '#2196F3', // Default color
      completed: false,
      orderDate: DateTime.now().toIso8601String(),
    );

    final completed = await showDialog<bool>(
      context: context,
      builder: (context) => OrderDetailDialog(
        order: order,
        onMarkComplete: () {
          Navigator.of(context).pop(true);
        },
        onMarkIncomplete: () {},
        onDelete: null, // Delete button removed
      ),
    );

    if (completed == true) {
      // Order marked complete on server — skip item sync to preserve completion status
      // Just close the menu page without syncing items
      _suppressDeleteOnPop = true;
      if (mounted) {
        Navigator.of(context).pop(true);
        return;
      }
    }
  }

  Widget _buildFloatingCartSummary() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _fabAnimationController!,
        curve: Curves.easeOutBack,
      )),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _Colors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _Colors.primary.withValues(alpha: 0.4),
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
              child: const Icon(Icons.shopping_bag_rounded,
                  color: Colors.white, size: 22),
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
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showOrderDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'View Cart',
                  style: TextStyle(
                    color: _Colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _Colors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading menu…',
            style: TextStyle(
                color: _Colors.textMid,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
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
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Color(0xFFFFB74D)),
            const SizedBox(height: 16),
            const Text(
              'Could not load menu',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _Colors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _Colors.textMid),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMenu,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 56, color: Color(0xFFD4C4B0)),
          SizedBox(height: 16),
          Text(
            'No Menu Items Available',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _Colors.textMid),
          ),
          SizedBox(height: 6),
          Text(
            'Contact your administrator to add items',
            style: TextStyle(fontSize: 13, color: _Colors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _handleWillPop();
        if (shouldPop && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: _Colors.background,
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error.isNotEmpty
                      ? _buildErrorState()
                      : _menu == null ||
                              _menu!.allIceStickCategories.isEmpty
                          ? _buildEmptyState()
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
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
