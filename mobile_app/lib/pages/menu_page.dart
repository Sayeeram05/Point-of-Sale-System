import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/optimized_image_service.dart';
import '../services/app_performance.dart';
import '../models/menu.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/order_detail_dialog.dart';

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
  AnimationController? _toggleAnimationController;
  AnimationController? _badgeAnimationController;
  final Map<String, AnimationController> _productBadgeControllers = {};

  // In-flight guard to prevent concurrent API mutations
  bool _isApiCallInFlight = false;

  // Pre-computed caches (updated in _updateTotals)
  Map<String, int> _quantityMap = {};
  int _iceCount = 0;
  bool _suppressDeleteOnPop = false;

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
    if (widget.initialOrderItems != null) {
      _currentOrderItems = List<OrderItem>.from(widget.initialOrderItems!);
      _updateTotals();
    }

    // Initialize toggle animation with optimized duration
    _toggleAnimationController = AnimationController(
      duration: AppPerformance.normalAnimation,
      vsync: this,
    );

    // Initialize badge animation controller with optimized duration
    _badgeAnimationController = AnimationController(
      duration: AppPerformance.slowAnimation,
      vsync: this,
    );

    _loadMenu();
  }

  @override
  void dispose() {
    _toggleAnimationController?.dispose();
    _badgeAnimationController?.dispose();
    // Dispose all product badge controllers
    for (final controller in _productBadgeControllers.values) {
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

      // Preload all product images in the background so they are
      // ready instantly when the user scrolls to them.
      _preloadAllProductImages(menu);

      // Also load the current order to populate _currentOrderItems
      await _loadCurrentOrder();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

    // Pre-compute quantity lookup map for O(1) access (was O(n) per product per build)
    final map = <String, int>{};
    for (final item in _currentOrderItems) {
      final key = item.product.trim().toLowerCase();
      map[key] = (map[key] ?? 0) + item.pieces;
    }
    _quantityMap = map;

    // Cache counts (was recomputed 6× in AppBar per build)
    _iceCount = _currentOrderItems.fold(0, (sum, item) => sum + item.pieces);

    // Trigger badge animation when totals update
    _badgeAnimationController?.forward().then((_) {
      _badgeAnimationController?.reverse();
    });
  }

  static const int _maxBadgeControllers = 50;

  void _animateBadgeForProduct(String productKey) {
    // Create or get animation controller for this specific product
    if (!_productBadgeControllers.containsKey(productKey)) {
      // Evict oldest entries if at capacity
      if (_productBadgeControllers.length >= _maxBadgeControllers) {
        final oldest = _productBadgeControllers.keys.first;
        _productBadgeControllers[oldest]?.dispose();
        _productBadgeControllers.remove(oldest);
      }
      _productBadgeControllers[productKey] = AnimationController(
        duration: AppPerformance.slowAnimation,
        vsync: this,
      );
    }

    final controller = _productBadgeControllers[productKey]!;
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



  Widget _buildProductItem(
    BuildContext context,
    Product product,
    int quantity,
    OrderItem? orderItem,
    bool isActive, {
    bool isIceSticks = true,
  }) {
    // Create a unique key for this specific product
    final String itemKey = 'product_${product.name}';

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                isActive &&
                    (product.pieces == null || quantity < product.pieces!)
                ? () {
                    _addProductToOrder(product);
                    // Trigger animation for this specific item
                    _animateBadgeForProduct(itemKey);
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main container with modern card design
                AnimatedContainer(
                  duration: AppPerformance.normalAnimation,
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(1.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    gradient: quantity > 0
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.08),
                              AppTheme.primaryColor.withValues(alpha: 0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.white, Colors.grey[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                      color: quantity > 0
                          ? AppTheme.primaryColor.withValues(alpha: 0.3)
                          : Colors.grey[200]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: quantity > 0
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.08),
                        spreadRadius: 0,
                        blurRadius: quantity > 0 ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[50],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child:
                            product.image != null && product.image!.isNotEmpty
                            ? OptimizedImageService.optimizedNetworkImage(
                                imageUrl: product.image!,
                                width:
                                    400, // Use reasonable max size instead of infinity
                                height:
                                    400, // Use reasonable max size instead of infinity
                                fit: BoxFit.contain,
                                errorWidget: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[200]!,
                                        Colors.grey[100]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.icecream_rounded,
                                        color: Colors.grey[500],
                                        size:
                                            isIceSticks &&
                                                AppTheme.isMobileOnly(context)
                                            ? 36
                                            : 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize:
                                              isIceSticks &&
                                                  AppTheme.isMobileOnly(context)
                                              ? 11
                                              : 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[200]!,
                                      Colors.grey[100]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.icecream_rounded,
                                      color: Colors.grey[500],
                                      size:
                                          isIceSticks &&
                                              AppTheme.isMobileOnly(context)
                                          ? 36
                                          : 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize:
                                            isIceSticks &&
                                                AppTheme.isMobileOnly(context)
                                            ? 11
                                            : 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                // Unified badge UI for both ice sticks and tubs
                if (quantity > 0)
                  Positioned(
                    bottom: -8,
                    left: -19,
                    child: buildMenuBadge(
                      quantity,
                      onTap: orderItem != null
                          ? () {
                              _decreaseQuantity(orderItem);
                              _animateBadgeForProduct(itemKey);
                            }
                          : null,
                    ),
                  ),
                // Enhanced inactive overlay — shows product name
                if (!isActive)
                  Positioned(
                    left: 6,
                    right: 6,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: Colors.red.withValues(alpha: 0.9),
                              size:
                                  isIceSticks && AppTheme.isMobileOnly(context)
                                  ? 16
                                  : 14,
                            ),
                            const SizedBox(height: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // Unified badge UI for both ice sticks and tubs
  Widget buildMenuBadge(int quantity, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: AppTheme.isMobileOnly(context) ? 30 : 38,
          minHeight: AppTheme.isMobileOnly(context) ? 30 : 38,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.isMobileOnly(context) ? 10 : 14,
          vertical: AppTheme.isMobileOnly(context) ? 5 : 8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'x$quantity',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.isMobileOnly(context) ? 13 : 17,
              letterSpacing: 1.0,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addProductToOrder(Product product) async {
    if (_isApiCallInFlight) return; // Prevent rapid concurrent updates

    _isApiCallInFlight = true;
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

  // Helper methods to count ice sticks (return cached values from _updateTotals)
  int _getIceCount() => _iceCount;

  List<Widget> _buildProductRows(List<Product> products) {
    // Filter out duplicate products based on name (keep only the first occurrence)
    final Map<String, Product> uniqueProducts = {};
    for (final product in products) {
      final String productName = product.name.toLowerCase();
      if (!uniqueProducts.containsKey(productName)) {
        uniqueProducts[productName] = product;
      }
    }

    final List<Product> filteredProducts = uniqueProducts.values.toList();

    // Responsive columns based on orientation and device
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    final int columns =
        AppTheme.isMobileOnly(context) ? 5 : (isPortrait ? 8 : 13);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemSpacing = AppTheme.isMobileOnly(context)
        ? 10.0
        : 20.0; //change
    final double itemWidth = AppTheme.isMobileOnly(context)
        ? (screenWidth - 16) / columns
        : (screenWidth - 24) / columns;
    final double itemHeight = AppTheme.isMobileOnly(context)
        ? 100.0
        : AppTheme.responsiveValue(
            context,
            mobile: 90,
            tablet: 105,
            desktop: 100,
          );

    return [
      Wrap(
        spacing: itemSpacing,
        runSpacing: AppTheme.isMobileOnly(context) ? 14.0 : 18.0,
        children: filteredProducts.map((product) {
          final quantity = _getProductQuantity(product);
          final orderItem = _getOrderItem(product);
          final isActive = product.active != false;
          return SizedBox(
            key: ValueKey('product_${product.productId}'),
            width: itemWidth,
            height: itemHeight,
            child: _buildProductItem(
              context,
              product,
              quantity,
              orderItem,
              isActive,
              isIceSticks: true,
            ),
          );
        }).toList(),
      ),
    ];
  }

  Widget _buildIceSticksList() {
    if (_menu == null || _menu!.allIceStickCategories.isEmpty) {
      return Center(
        child: Text(
          'No Ice Sticks Available',
          style: AppTheme.headingSmall(
            context,
          ).copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.isMobileOnly(context)
            ? 4.0
            : AppTheme.spacingMedium,
      ),
      child: ListView.builder(
        addAutomaticKeepAlives: false,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: AppTheme.responsiveValue(
            context,
            mobile:
                80, // Increased from 20 to 80 for better bottom spacing on mobile
            tablet:
                100, // Increased from 32 to 100 for better bottom spacing on tablet
            desktop:
                120, // Increased from 40 to 120 for better bottom spacing on desktop
          ),
        ),
        itemCount: _menu!.allIceStickCategories.length,
        itemBuilder: (context, categoryIndex) {
          final category = _menu!.allIceStickCategories[categoryIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.isMobileOnly(context)
                      ? 4.0
                      : AppTheme.spacingSmall,
                ),
                child: Text(
                  category.name,
                  style: AppTheme.headingSmall(context).copyWith(
                    fontSize: AppTheme.isMobileOnly(context) ? 12 : 18,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Category products with row wrapping (max 11 items per row)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.isMobileOnly(context)
                      ? 2.0
                      : AppTheme.spacingMedium,
                ),
                child: Column(
                  children: _buildProductRows(
                    category.products,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final appBarHeight = AppTheme.responsiveValue(
      context,
      mobile: 40.0,
      tablet: 56.0,
      desktop: 48.0,
    );

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: AppTheme.elevationMedium,
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: AppTheme.isMobileOnly(context)
                  ? Row(
                      children: [
                        // Mobile: Show order number first
                        Text(
                          widget.orderIndex != null
                              ? 'Order #${widget.orderIndex}'
                              : 'Order #${widget.orderId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Mobile: Show ice count
                        Row(
                          children: [
                            const Icon(
                              Icons.icecream_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_getIceCount()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Tablet/Desktop: Show order title + ice count
                        Text(
                          widget.orderIndex != null
                              ? 'Order #${widget.orderIndex}'
                              : 'New Order',
                          style: AppTheme.headingMedium(context).copyWith(
                            color: Colors.white,
                            fontSize: AppTheme.responsiveValue(
                              context,
                              mobile: 14,
                              tablet: 22,
                              desktop: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add ice count for tablets/desktop too
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.icecream_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_getIceCount()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.85),
                                AppTheme.primaryLight.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_totalPieces',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.currency_rupee_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              Text(
                                _totalPrice.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: AppTheme.responsiveValue(
                    context,
                    mobile: 20,
                    tablet: 28,
                    desktop: 28,
                  ),
                ),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final shouldPop = await _handleWillPop();
                  if (shouldPop && mounted) {
                    navigator.pop(true);
                  }
                },
              ),
              actions: [
                Container(
                  margin: EdgeInsets.only(
                    right: AppTheme.spacingLarge,
                    top: AppTheme.isMobileOnly(context) ? 6 : 0,
                    bottom: AppTheme.isMobileOnly(context) ? 6 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pending button removed per user request
                      // Complete/Done button - always show in app bar
                      ElevatedButton.icon(
                        onPressed: _showOrderDetails,
                        style: AppTheme.successButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            AppTheme.success,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          elevation: WidgetStateProperty.all(0),
                          shadowColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                            ),
                          ),
                          padding: WidgetStateProperty.all(
                            EdgeInsets.symmetric(
                              horizontal: AppTheme.responsiveValue(
                                context,
                                mobile: 8, // Reduced padding for mobile
                                tablet: 18,
                                desktop: 16,
                              ),
                              vertical: AppTheme.responsiveValue(
                                context,
                                mobile: 4, // Reduced padding for mobile
                                tablet: 12,
                                desktop: 10,
                              ),
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.payment_rounded,
                          size: AppTheme.responsiveValue(
                            context,
                            mobile: 14,
                            tablet: 22,
                            desktop: 18,
                          ),
                        ),
                        label: Text(
                          AppTheme.isMobileOnly(context)
                              ? 'Done' // "Done" on mobile phones
                              : 'Complete', // "Complete" on tablets and larger screens
                          style: AppTheme.labelMedium.copyWith(
                            color: Colors.white,
                            fontSize: AppTheme.responsiveValue(
                              context,
                              mobile: 10,
                              tablet: 16,
                              desktop: 14,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              )
            : _error.isNotEmpty
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXLarge),
                  margin: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: AppTheme.cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.elevationMedium,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: AppTheme.responsiveValue(
                            context,
                            mobile: 48,
                            tablet: 64,
                            desktop: 72,
                          ),
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Text(
                        'Failed to load menu',
                        style: AppTheme.headingSmall(context).copyWith(
                          fontSize: AppTheme.responsiveValue(
                            context,
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),
                          color: AppTheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: AppTheme.responsiveValue(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),
                      ElevatedButton.icon(
                        onPressed: _loadMenu,
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingLarge,
                              vertical: AppTheme.spacingMedium,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          'Try Again',
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _menu == null || _menu!.allIceStickCategories.isEmpty
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXLarge),
                  margin: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: AppTheme.elevatedCardDecoration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          size: AppTheme.responsiveValue(
                            context,
                            mobile: 56,
                            tablet: 72,
                            desktop: 88,
                          ),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),
                      Text(
                        'No Menu Items Available',
                        style: AppTheme.headingSmall(context).copyWith(
                          fontSize: AppTheme.responsiveValue(
                            context,
                            mobile: 22,
                            tablet: 26,
                            desktop: 30,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        'Contact your administrator to add menu items',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(
                          fontSize: AppTheme.responsiveValue(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  // Toggle Button - centered
                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppTheme.responsiveValue(
                          context,
                          mobile: 8,
                          tablet: 12,
                          desktop: 16,
                        ),
                        vertical: AppTheme.responsiveValue(
                          context,
                          mobile: 4,
                          tablet: 6,
                          desktop: 8,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.responsiveValue(
                            context,
                            mobile: 20,
                            tablet: 25,
                            desktop: 30,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: AppTheme.responsiveValue(
                              context,
                              mobile: 6,
                              tablet: 8,
                              desktop: 10,
                            ),
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Only show Ice Sticks tab
                          // removed Tubs and Scoops tabs
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _buildIceSticksList(),
                  ),
                ],
              ),
      ),
    );
  }

  // Scoops-related methods
}
  // Scoops and tubs removed: related UI and helper methods deleted.
