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
  String _selectedTab = 'IceSticks'; // Can be 'IceSticks', 'Tubs', or 'Scoops'
  AnimationController? _toggleAnimationController;
  AnimationController? _badgeAnimationController;
  final Map<String, AnimationController> _productBadgeControllers = {};

  // In-flight guard to prevent concurrent API mutations
  bool _isApiCallInFlight = false;

  // Pre-computed caches (updated in _updateTotals)
  Map<String, int> _quantityMap = {};
  int _iceCount = 0;
  int _tubsCount = 0;
  int _scoopsCount = 0;

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
            tubCategory: item.tubCategory,
            scoopPriceId: item.scoopPriceId,
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

  int _getTubProductQuantity(TubProduct tubProduct, String categoryId) {
    int totalQuantity = 0;
    for (final item in _currentOrderItems) {
      final productName = item.product.toUpperCase().trim();
      final tubName = tubProduct.name.trim().toUpperCase();
      final productNameMatches =
          productName.startsWith(tubName) || productName.contains(tubName);
      final categoryMatches = item.tubCategory?.toString() == categoryId;
      if (productNameMatches && categoryMatches) {
        totalQuantity += item.pieces;
      }
    }
    return totalQuantity;
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
    _iceCount = _currentOrderItems
        .where(
          (item) => item.tubCategory == null && item.productType != 'scoops',
        )
        .fold(0, (sum, item) => sum + item.pieces);
    _tubsCount = _currentOrderItems
        .where((item) => item.tubCategory != null)
        .fold(0, (sum, item) => sum + item.pieces);
    _scoopsCount = _currentOrderItems
        .where((item) => item.productType == 'scoops')
        .fold(0, (sum, item) => sum + item.pieces);

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

  OrderItem? _getTubOrderItem(TubProduct tubProduct, String categoryId) {
    final tubName = tubProduct.name.trim().toUpperCase();
    final idx = _currentOrderItems.indexWhere((item) {
      final productName = item.product.toUpperCase().trim();
      final productNameMatches =
          productName.startsWith(tubName) || productName.contains(tubName);
      final categoryMatches = item.tubCategory?.toString() == categoryId;
      return productNameMatches && categoryMatches;
    });
    return idx >= 0 ? _currentOrderItems[idx] : null;
  }

  Widget _buildProductItem(
    BuildContext context,
    Product product,
    int quantity,
    OrderItem? orderItem,
    bool isActive, {
    bool isIceSticks = false,
  }) {
    // Create a unique key for this specific product
    final String itemKey = 'product_${product.name}';
    final int availablePieces = product.pieces ?? 0;
    final bool isOutOfStock = product.isOutOfStock;
    final bool isLimitReached =
        !isOutOfStock && availablePieces > 0 && quantity >= availablePieces;
    final String? stockStatusText = isOutOfStock
        ? 'Out of stock'
        : isLimitReached
        ? 'Limit reached'
        : null;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.all(
          isIceSticks && AppTheme.isMobileOnly(context) ? 0.5 : 1.0,
        ),
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
                  padding: EdgeInsets.all(
                    isIceSticks && AppTheme.isMobileOnly(context) ? 0.5 : 1.0,
                  ),
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
                                    fontSize:
                                        isIceSticks &&
                                            AppTheme.isMobileOnly(context)
                                        ? 11
                                        : 10,
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
                if (stockStatusText != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withValues(alpha: 0.9)
                            : Colors.orange.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stockStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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

  Widget _buildTubItem(
    BuildContext context,
    TubProduct tubProduct,
    String categoryId,
    String quantityInMl,
    int quantity,
    OrderItem? orderItem,
  ) {
    // Create a unique key for this specific tub item
    final String itemKey = '${tubProduct.name}_$categoryId';

    final bool isTubOutOfStock = tubProduct.isOutOfStock;
    final bool isTubLimitReached =
        !isTubOutOfStock && quantity >= tubProduct.tubStock;
    final String? tubStatusText = isTubOutOfStock
        ? 'Out of stock'
        : isTubLimitReached
        ? 'Limit reached'
        : null;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 1.0 : 2.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isTubOutOfStock || quantity >= tubProduct.tubStock
                    ? null
                    : () {
                        _addTubProductToOrder(tubProduct, categoryId);
                        _animateBadgeForProduct(itemKey);
                      },
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicWidth(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: AppTheme.isMobileOnly(context) ? 38 : 52,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.isMobileOnly(context) ? 6 : 14,
                      vertical: AppTheme.isMobileOnly(context) ? 3 : 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isTubOutOfStock ? Colors.grey[100] : Colors.white,
                      border: Border.all(
                        color: isTubOutOfStock
                            ? Colors.red.withValues(alpha: 0.3)
                            : quantity > 0
                            ? AppTheme.primaryColor.withValues(alpha: 0.4)
                            : Colors.grey[300]!,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: quantity > 0
                              ? AppTheme.primaryColor.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${tubProduct.name} (${quantityInMl}ml) - ',
                                  style: TextStyle(
                                    color: isTubOutOfStock
                                        ? Colors.grey[500]
                                        : Colors.grey[900],
                                    fontSize: AppTheme.isMobileOnly(context)
                                        ? 12
                                        : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '₹${tubProduct.price}',
                                  style: TextStyle(
                                    color: isTubOutOfStock
                                        ? Colors.grey[400]
                                        : AppTheme.primaryColor,
                                    fontSize: AppTheme.isMobileOnly(context)
                                        ? 13
                                        : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (tubStatusText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              tubStatusText,
                              style: TextStyle(
                                color: isTubOutOfStock
                                    ? Colors.red[400]
                                    : Colors.orange[700],
                                fontSize: AppTheme.isMobileOnly(context)
                                    ? 10
                                    : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Floating game-style badge at bottom-left
            if (quantity > 0)
              Positioned(
                bottom: -15,
                left: -25,
                child: buildMenuBadge(
                  quantity,
                  onTap: orderItem != null
                      ? () {
                          _decreaseTubQuantity(orderItem);
                          _animateBadgeForProduct(itemKey);
                        }
                      : null,
                ),
              ),
          ],
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
    if (_isApiCallInFlight) return; // Prevent rapid concurrent calls

    final currentQty = _getProductQuantity(product);
    final maxAvailable = product.pieces ?? 0;
    if (maxAvailable <= 0 || currentQty >= maxAvailable) {
      return;
    }

    _isApiCallInFlight = true;
    try {
      // Check if product already exists in order
      final existingIndex = _currentOrderItems.indexWhere(
        (item) =>
            item.product.trim().toLowerCase() ==
            product.name.trim().toLowerCase(),
      );

      if (existingIndex >= 0) {
        // Optimistic local update for instant UI feedback
        setState(() {
          _currentOrderItems[existingIndex] = OrderItem(
            itemId: _currentOrderItems[existingIndex].itemId,
            orderItemId: _currentOrderItems[existingIndex].orderItemId,
            product: _currentOrderItems[existingIndex].product,
            price: _currentOrderItems[existingIndex].price,
            pieces: _currentOrderItems[existingIndex].pieces + 1,
            tubCategory: _currentOrderItems[existingIndex].tubCategory,
            scoopPriceId: _currentOrderItems[existingIndex].scoopPriceId,
            productType: _currentOrderItems[existingIndex].productType,
          );
          _updateTotals();
        });

        // Use itemId for increment  — no full re-fetch needed for optimistic path
        final itemId = _currentOrderItems[existingIndex].itemId;
        await ApiService.increaseOrderItemQuantity(itemId);
      } else {
        // Add new product to order
        await ApiService.addProductToOrder(widget.orderId, product.productId);
        // Refresh the entire order to ensure UI synchronization
        await _loadCurrentOrder();
      }
    } catch (e) {
      // Revert optimistic update on error
      await _loadCurrentOrder();
      if (kDebugMode) debugPrint('Error adding product: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Future<void> _addTubProductToOrder(
    TubProduct tubProduct,
    String categoryId,
  ) async {
    if (_isApiCallInFlight) return;

    final currentQty = _getTubProductQuantity(tubProduct, categoryId);
    final maxAvailable = tubProduct.tubStock;
    if (maxAvailable <= 0 || currentQty >= maxAvailable) {
      return;
    }

    _isApiCallInFlight = true;
    try {
      final existingOrderItem = _getTubOrderItem(tubProduct, categoryId);

      if (existingOrderItem != null) {
        // Optimistic local update
        final idx = _currentOrderItems.indexWhere(
          (i) => i.itemId == existingOrderItem.itemId,
        );
        if (idx >= 0) {
          setState(() {
            _currentOrderItems[idx] = OrderItem(
              itemId: _currentOrderItems[idx].itemId,
              orderItemId: _currentOrderItems[idx].orderItemId,
              product: _currentOrderItems[idx].product,
              price: _currentOrderItems[idx].price,
              pieces: _currentOrderItems[idx].pieces + 1,
              tubCategory: _currentOrderItems[idx].tubCategory,
              scoopPriceId: _currentOrderItems[idx].scoopPriceId,
              productType: _currentOrderItems[idx].productType,
            );
            _updateTotals();
          });
        }

        final idToUse =
            existingOrderItem.orderItemId ?? existingOrderItem.itemId;
        await ApiService.increaseTubOrderItemQuantity(idToUse);
      } else {
        await ApiService.addTubProductToOrder(
          widget.orderId,
          tubProduct.tubProductId,
          categoryId,
        );
        await _loadCurrentOrder();
      }
    } catch (e) {
      // Revert optimistic update on error
      await _loadCurrentOrder();
      if (kDebugMode) debugPrint('TUB ERROR: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Future<void> _decreaseTubQuantity(OrderItem orderItem) async {
    if (_isApiCallInFlight) return;
    _isApiCallInFlight = true;
    final idToUse = orderItem.orderItemId ?? orderItem.itemId;
    try {
      // Optimistic local update
      final idx = _currentOrderItems.indexWhere(
        (i) => i.itemId == orderItem.itemId,
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
              tubCategory: _currentOrderItems[idx].tubCategory,
              scoopPriceId: _currentOrderItems[idx].scoopPriceId,
              productType: _currentOrderItems[idx].productType,
            );
          } else {
            _currentOrderItems.removeAt(idx);
          }
          _updateTotals();
        });
      }
      await ApiService.decreaseTubOrderItemQuantity(idToUse);
    } catch (e) {
      await _loadCurrentOrder();
      if (kDebugMode) debugPrint('Error decreasing tub quantity: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Future<void> _decreaseQuantity(OrderItem item) async {
    if (_isApiCallInFlight) return;
    _isApiCallInFlight = true;
    try {
      // Optimistic local update for instant UI feedback
      final idx = _currentOrderItems.indexWhere((i) => i.itemId == item.itemId);
      if (idx >= 0) {
        setState(() {
          if (_currentOrderItems[idx].pieces > 1) {
            _currentOrderItems[idx] = OrderItem(
              itemId: _currentOrderItems[idx].itemId,
              orderItemId: _currentOrderItems[idx].orderItemId,
              product: _currentOrderItems[idx].product,
              price: _currentOrderItems[idx].price,
              pieces: _currentOrderItems[idx].pieces - 1,
              tubCategory: _currentOrderItems[idx].tubCategory,
              scoopPriceId: _currentOrderItems[idx].scoopPriceId,
              productType: _currentOrderItems[idx].productType,
            );
          } else {
            _currentOrderItems.removeAt(idx);
          }
          _updateTotals();
        });
      }

      // Use itemId for decrement operation — no full re-fetch for optimistic path
      await ApiService.decreaseOrderItemQuantity(item.itemId);
    } catch (e) {
      // Revert optimistic update on error
      await _loadCurrentOrder();
    } finally {
      _isApiCallInFlight = false;
    }
  }

  void _showOrderDetails() {
    if (_currentOrderItems.isEmpty) {
      // Order empty notification removed per user request
      return;
    }

    // Create order with current data (since getOrder API is no longer available)
    final order = Order(
      orderId: widget.orderId,
      items: _currentOrderItems,
      price: _totalPrice.toStringAsFixed(2),
      upiAmount: '0.0',
      cashAmount: '0.0',
      displayIndex: widget.orderIndex ?? 0,
      emoji: '🍦', // Default emoji
      color: '#2196F3', // Default color
      completed: false,
      orderDate: DateTime.now().toIso8601String(),
    );

    showDialog(
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
  }

  // Helper methods to count ice sticks and tubs (return cached values from _updateTotals)
  int _getIceCount() => _iceCount;

  int _getTubsCount() => _tubsCount;

  List<Widget> _buildProductRows(
    List<Product> products, {
    bool isIceSticks = false,
  }) {
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

    final int columns;
    if (isIceSticks) {
      columns = AppTheme.isMobileOnly(context) ? 5 : (isPortrait ? 8 : 13);
    } else {
      columns = AppTheme.isMobileOnly(context)
          ? (isPortrait ? 5 : 8)
          : (isPortrait ? 8 : 13);
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemSpacing = AppTheme.isMobileOnly(context)
        ? 10.0
        : 20.0; //change
    final double itemWidth = AppTheme.isMobileOnly(context)
        ? (screenWidth - 16) / columns
        : (screenWidth - 24) / columns;
    final double itemHeight = AppTheme.isMobileOnly(context)
        ? (isIceSticks ? 100.0 : 90.0)
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
          final isActive = product.active == true && !product.isOutOfStock;
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
              isIceSticks: isIceSticks,
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
                    isIceSticks: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTubsList() {
    if (_menu?.tubs?.categories.isEmpty ?? true) {
      return Center(
        child: Text(
          'No Tubs Available',
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
      padding: const EdgeInsets.all(5.0), // Added 5px padding to scroll panel
      child: ListView.builder(
        addAutomaticKeepAlives: false,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: AppTheme.responsiveValue(
            context,
            mobile:
                100, // Increased from 20 to 100 for better bottom spacing on mobile
            tablet:
                120, // Increased from 32 to 120 for better bottom spacing on tablet
            desktop:
                140, // Increased from 40 to 140 for better bottom spacing on desktop
          ),
        ),
        itemCount: _menu!.tubs!.categories.length,
        itemBuilder: (context, categoryIndex) {
          final tubCategory = _menu!.tubs!.categories[categoryIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.isMobileOnly(context)
                      ? 4.0
                      : AppTheme.spacingSmall,
                ),
                child: Text(
                  '${tubCategory.name} - ${tubCategory.quantityInMl}ml',
                  style: AppTheme.headingSmall(context).copyWith(
                    fontSize: AppTheme.isMobileOnly(context) ? 12 : 18,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.isMobileOnly(context)
                      ? 2.0
                      : AppTheme.spacingMedium,
                ),
                child: Wrap(
                  spacing: AppTheme.isMobileOnly(context) ? 10.0 : 22.0,
                  runSpacing: AppTheme.isMobileOnly(context) ? 14.0 : 18.0,
                  children: List.generate(tubCategory.products.length, (index) {
                    final tubProduct = tubCategory.products[index];
                    final quantity = _getTubProductQuantity(
                      tubProduct,
                      tubCategory.tubCategoryId,
                    );
                    final orderItem = _getTubOrderItem(
                      tubProduct,
                      tubCategory.tubCategoryId,
                    );
                    return _buildTubItem(
                      context,
                      tubProduct,
                      tubCategory.tubCategoryId,
                      tubCategory.quantityInMl,
                      quantity,
                      orderItem,
                    );
                  }),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Call delete order if the order is empty
        if (_currentOrderItems.isEmpty) {
          try {
            await ApiService.deleteOrder(widget.orderId);
          } catch (e) {
            // Optionally show error
          }
        }

        // Navigate back
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
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
                        // Mobile: Show ice, tubs, and scoops count
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
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.emoji_food_beverage,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_getTubsCount()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.icecream_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_getScoopsCount()}',
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
                        // Tablet/Desktop: Show order title + ice and tubs count
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
                        // Add ice, tubs, and scoops count for tablets/desktop too
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
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.emoji_food_beverage,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_getTubsCount()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.icecream_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_getScoopsCount()}',
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
                  if (_currentOrderItems.isEmpty) {
                    try {
                      await ApiService.deleteOrder(widget.orderId);
                    } catch (e) {
                      // Optionally show error
                    }
                  }
                  if (mounted) {
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
            : _menu == null ||
                  (_menu!.allIceStickCategories.isEmpty &&
                      (_menu!.tubs?.categories.isEmpty ?? true))
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
                          // Ice Sticks Tab
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 'IceSticks';
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppPerformance.normalAnimation,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.isMobileOnly(context)
                                    ? 10
                                    : AppTheme.responsiveValue(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 20,
                                      ),
                                vertical: AppTheme.isMobileOnly(context)
                                    ? 6
                                    : AppTheme.responsiveValue(
                                        context,
                                        mobile: 8,
                                        tablet: 10,
                                        desktop: 12,
                                      ),
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'IceSticks'
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.responsiveValue(
                                    context,
                                    mobile: 20,
                                    tablet: 20,
                                    desktop: 30,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.icecream_rounded,
                                    color: _selectedTab == 'IceSticks'
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: AppTheme.responsiveValue(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      desktop: 20,
                                    ),
                                  ),
                                  SizedBox(
                                    width: AppTheme.responsiveValue(
                                      context,
                                      mobile: 4,
                                      tablet: 6,
                                      desktop: 8,
                                    ),
                                  ),
                                  Text(
                                    'Ice Sticks',
                                    style: TextStyle(
                                      color: _selectedTab == 'IceSticks'
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppTheme.responsiveValue(
                                        context,
                                        mobile: 11,
                                        tablet: 15,
                                        desktop: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Tubs Tab
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 'Tubs';
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppPerformance.normalAnimation,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.isMobileOnly(context)
                                    ? 10
                                    : AppTheme.responsiveValue(
                                        context,
                                        mobile: 14,
                                        tablet: 24,
                                        desktop: 20,
                                      ),
                                vertical: AppTheme.isMobileOnly(context)
                                    ? 6
                                    : AppTheme.responsiveValue(
                                        context,
                                        mobile: 8,
                                        tablet: 10,
                                        desktop: 12,
                                      ),
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'Tubs'
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.responsiveValue(
                                    context,
                                    mobile: 20,
                                    tablet: 20,
                                    desktop: 30,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_food_beverage,
                                    color: _selectedTab == 'Tubs'
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: AppTheme.responsiveValue(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      desktop: 20,
                                    ),
                                  ),
                                  SizedBox(
                                    width: AppTheme.responsiveValue(
                                      context,
                                      mobile: 4,
                                      tablet: 6,
                                      desktop: 8,
                                    ),
                                  ),
                                  Text(
                                    'Tubs',
                                    style: TextStyle(
                                      color: _selectedTab == 'Tubs'
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppTheme.responsiveValue(
                                        context,
                                        mobile: 11,
                                        tablet: 15,
                                        desktop: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Scoops Tab
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTab = 'Scoops';
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppPerformance.normalAnimation,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.isMobileOnly(context)
                                    ? 10
                                    : AppTheme.responsiveValue(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 20,
                                      ),
                                vertical: AppTheme.isMobileOnly(context)
                                    ? 6
                                    : AppTheme.responsiveValue(
                                        context,
                                        mobile: 8,
                                        tablet: 10,
                                        desktop: 12,
                                      ),
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'Scoops'
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.responsiveValue(
                                    context,
                                    mobile: 20,
                                    tablet: 20,
                                    desktop: 30,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.icecream_outlined,
                                    color: _selectedTab == 'Scoops'
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: AppTheme.responsiveValue(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      desktop: 20,
                                    ),
                                  ),
                                  SizedBox(
                                    width: AppTheme.responsiveValue(
                                      context,
                                      mobile: 4,
                                      tablet: 6,
                                      desktop: 8,
                                    ),
                                  ),
                                  Text(
                                    'Scoops',
                                    style: TextStyle(
                                      color: _selectedTab == 'Scoops'
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppTheme.responsiveValue(
                                        context,
                                        mobile: 11,
                                        tablet: 15,
                                        desktop: 15,
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
                  // Content
                  Expanded(
                    child: _selectedTab == 'IceSticks'
                        ? _buildIceSticksList()
                        : _selectedTab == 'Tubs'
                        ? _buildTubsList()
                        : _buildScoopsList(),
                  ),
                ],
              ),
      ),
    );
  }

  // Scoops-related methods
  Widget _buildScoopsList() {
    final byCategory = _menu?.scoops?.byCategory ?? [];

    // If server provides the category-centric view, use it
    if (byCategory.isNotEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.isMobileOnly(context)
              ? 4.0
              : AppTheme.spacingMedium,
        ),
        padding: const EdgeInsets.all(5.0),
        child: ListView.builder(
          addAutomaticKeepAlives: false,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: AppTheme.responsiveValue(
              context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
          ),
          itemCount: byCategory.length,
          itemBuilder: (context, idx) {
            final catRow = byCategory[idx];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category header ──────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.isMobileOnly(context)
                        ? 4.0
                        : AppTheme.spacingSmall,
                  ),
                  child: Text(
                    '${catRow.name} - ${catRow.quantityInMl}ml',
                    style: AppTheme.headingSmall(context).copyWith(
                      fontSize: AppTheme.isMobileOnly(context) ? 12 : 18,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ── Scoop products in this category ──────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.isMobileOnly(context)
                        ? 2.0
                        : AppTheme.spacingMedium,
                  ),
                  child: Wrap(
                    spacing: AppTheme.isMobileOnly(context) ? 10.0 : 20.0,
                    runSpacing: AppTheme.isMobileOnly(context) ? 14.0 : 18.0,
                    children: catRow.scoopProducts
                        .map(
                          (p) => _buildScoopItemForCategory(
                            p,
                            catRow.tubCategoryId,
                            catRow.quantityInMl,
                          ),
                        )
                        .toList(),
                  ),
                ),
                SizedBox(height: AppTheme.isMobileOnly(context) ? 6 : 10),
              ],
            );
          },
        ),
      );
    }

    // ── Fallback: old layout grouped by scoop ml ──────────────────────
    if (_menu?.scoops?.scoopPrices.isEmpty ?? true) {
      return Center(
        child: Text(
          'No Scoops Available',
          style: AppTheme.headingSmall(
            context,
          ).copyWith(color: Colors.grey[600]),
        ),
      );
    }

    final Map<String, List<ScoopPrice>> groupedScoops = {};
    for (final scoop in _menu!.scoops!.scoopPrices) {
      groupedScoops.putIfAbsent(scoop.quantityInMl, () => []).add(scoop);
    }
    final groupKeys = groupedScoops.keys.toList()
      ..sort((a, b) {
        final aVal = int.tryParse(a) ?? 0;
        final bVal = int.tryParse(b) ?? 0;
        return bVal.compareTo(aVal);
      });

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.isMobileOnly(context)
            ? 4.0
            : AppTheme.spacingMedium,
      ),
      padding: const EdgeInsets.all(5.0),
      child: ListView.builder(
        addAutomaticKeepAlives: false,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: AppTheme.responsiveValue(
            context,
            mobile: 100,
            tablet: 120,
            desktop: 140,
          ),
        ),
        itemCount: groupKeys.length,
        itemBuilder: (context, groupIndex) {
          final mlKey = groupKeys[groupIndex];
          final scoopsInGroup = groupedScoops[mlKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Text(
                  'Scoop - ${mlKey}ml',
                  style: AppTheme.headingSmall(context).copyWith(
                    fontSize: AppTheme.isMobileOnly(context) ? 12 : 18,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.isMobileOnly(context)
                      ? 2.0
                      : AppTheme.spacingMedium,
                ),
                child: Wrap(
                  spacing: AppTheme.isMobileOnly(context) ? 10.0 : 20.0,
                  runSpacing: AppTheme.isMobileOnly(context) ? 14.0 : 18.0,
                  children: scoopsInGroup.map((sp) {
                    return _buildScoopItem(
                      context,
                      sp,
                      _getScoopQuantity(sp),
                      _getScoopOrderItem(sp),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Chip widget for a scoop product shown under its tub-category header.
  Widget _buildScoopItemForCategory(
    ScoopProductInCategory product,
    String categoryId,
    int tubCapacityMl,
  ) {
    final String itemKey = 'scoop_${product.scoopPriceId}_$categoryId';
    final bool isActive = product.active;
    final int quantity = _getQtyForExactCategory(
      product.scoopPriceId,
      categoryId,
    );
    final int scoopMl = int.tryParse(product.quantityInMl) ?? 100;
    // Effective scoops = ⌊(api_ml − tub_ml_in_order) / scoop_ml⌋
    final int effectiveScoops = _effectiveScoopsAvailable(
      scoopPriceId: product.scoopPriceId,
      categoryId: categoryId,
      scoopMl: scoopMl,
      tubCapacityMl: tubCapacityMl,
      tubProductName: product.name,
    );
    final bool isOutOfStock = effectiveScoops <= 0;
    final bool isLimitReached = !isOutOfStock && quantity >= effectiveScoops;
    final bool canAdd = isActive && !isOutOfStock && !isLimitReached;
    final String? stockStatusText = isOutOfStock
        ? 'Out of stock'
        : isLimitReached
        ? 'Limit reached'
        : null;
    final OrderItem? orderItem = _getOrderItemForExactCategory(
      product.scoopPriceId,
      categoryId,
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 1.0 : 2.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canAdd
                    ? () {
                        _addScoopByCategory(product.scoopPriceId, categoryId);
                        _animateBadgeForProduct(itemKey);
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicWidth(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: AppTheme.isMobileOnly(context) ? 38 : 52,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.isMobileOnly(context) ? 8 : 14,
                      vertical: AppTheme.isMobileOnly(context) ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: canAdd ? Colors.white : Colors.grey[100],
                      border: Border.all(
                        color: !canAdd
                            ? (isOutOfStock
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.4))
                            : quantity > 0
                            ? AppTheme.primaryColor.withValues(alpha: 0.4)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: !canAdd
                              ? (isOutOfStock
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.12))
                              : quantity > 0
                              ? AppTheme.primaryColor.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${product.name} (${product.quantityInMl}ml) - ',
                                  style: TextStyle(
                                    color: canAdd
                                        ? Colors.grey[900]
                                        : Colors.grey[500],
                                    fontSize: AppTheme.isMobileOnly(context)
                                        ? 12
                                        : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '₹${product.price}',
                                  style: TextStyle(
                                    color: canAdd
                                        ? AppTheme.primaryColor
                                        : Colors.grey[400],
                                    fontSize: AppTheme.isMobileOnly(context)
                                        ? 13
                                        : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (stockStatusText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              stockStatusText,
                              style: TextStyle(
                                color: isOutOfStock
                                    ? Colors.red[400]
                                    : Colors.orange[700],
                                fontSize: AppTheme.isMobileOnly(context)
                                    ? 10
                                    : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (quantity > 0)
              Positioned(
                bottom: -15,
                left: -25,
                child: buildMenuBadge(
                  quantity,
                  onTap: orderItem != null
                      ? () {
                          _decreaseScoopQuantity(orderItem);
                          _animateBadgeForProduct(itemKey);
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get order quantity for a specific scoop + category combo.
  int _getQtyForExactCategory(String scoopPriceId, String categoryId) {
    return _currentOrderItems
        .where(
          (item) =>
              item.productType == 'scoops' &&
              item.scoopPriceId.toString() == scoopPriceId &&
              item.tubCategory.toString() == categoryId,
        )
        .fold(0, (sum, item) => sum + item.pieces);
  }

  /// Get order item for a specific scoop + category combo.
  OrderItem? _getOrderItemForExactCategory(
    String scoopPriceId,
    String categoryId,
  ) {
    final idx = _currentOrderItems.indexWhere(
      (item) =>
          item.productType == 'scoops' &&
          item.scoopPriceId.toString() == scoopPriceId &&
          item.tubCategory.toString() == categoryId,
    );
    return idx >= 0 ? _currentOrderItems[idx] : null;
  }

  /// Add scoop to order directly with a known category — no bottom-sheet picker needed.
  Future<void> _addScoopByCategory(
    String scoopPriceId,
    String categoryId,
  ) async {
    if (_isApiCallInFlight) return;

    final currentQty = _getQtyForExactCategory(scoopPriceId, categoryId);
    ScoopCategory? selectedCategory;
    ScoopPrice? selectedScoopPrice;
    final scoopPrices = _menu?.scoops?.scoopPrices ?? const <ScoopPrice>[];
    for (final scoop in scoopPrices) {
      if (scoop.scoopPriceId != scoopPriceId) continue;
      for (final category in scoop.categories) {
        if (category.tubCategoryId == categoryId) {
          selectedCategory = category;
          selectedScoopPrice = scoop;
          break;
        }
      }
      if (selectedCategory != null) break;
    }
    // Use effective scoops (accounting for tubs already in the order)
    final int scoopMl =
        int.tryParse(selectedScoopPrice?.quantityInMl ?? '100') ?? 100;
    final int tubCapacityMl = _tubCapacityMlForCategory(categoryId);
    final int effectiveMax = _effectiveScoopsAvailable(
      scoopPriceId: scoopPriceId,
      categoryId: categoryId,
      scoopMl: scoopMl,
      tubCapacityMl: tubCapacityMl,
      tubProductName: selectedScoopPrice?.tubProductName ?? '',
    );
    if (effectiveMax <= 0 || currentQty >= effectiveMax) {
      return;
    }

    _isApiCallInFlight = true;
    try {
      final existing = _getOrderItemForExactCategory(scoopPriceId, categoryId);
      if (existing != null) {
        // Optimistic local update
        final idx = _currentOrderItems.indexWhere(
          (i) => i.itemId == existing.itemId,
        );
        if (idx >= 0) {
          setState(() {
            _currentOrderItems[idx] = OrderItem(
              itemId: _currentOrderItems[idx].itemId,
              orderItemId: _currentOrderItems[idx].orderItemId,
              product: _currentOrderItems[idx].product,
              price: _currentOrderItems[idx].price,
              pieces: _currentOrderItems[idx].pieces + 1,
              tubCategory: _currentOrderItems[idx].tubCategory,
              scoopPriceId: _currentOrderItems[idx].scoopPriceId,
              productType: _currentOrderItems[idx].productType,
            );
            _updateTotals();
          });
        }
        await ApiService.increaseScoopOrderItemQuantity(
          existing.orderItemId ?? existing.itemId,
        );
      } else {
        await ApiService.addScoopToOrder(
          widget.orderId,
          scoopPriceId,
          categoryId: categoryId,
        );
        await _loadCurrentOrder();
      }
    } catch (e) {
      await _loadCurrentOrder();
      if (kDebugMode) debugPrint('ERROR ADDING SCOOP BY CATEGORY: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Widget _buildScoopItem(
    BuildContext context,
    ScoopPrice scoopPrice,
    int quantity,
    OrderItem? orderItem,
  ) {
    final String itemKey = 'scoop_${scoopPrice.scoopPriceId}';
    final bool isActive = scoopPrice.active ?? true;
    final int? availableScoops = scoopPrice.availableScoops;
    final bool isOutOfStock = availableScoops != null && availableScoops <= 0;
    final bool isLimitReached =
        availableScoops != null &&
        availableScoops > 0 &&
        quantity >= availableScoops;
    final bool canAdd = isActive && !isOutOfStock && !isLimitReached;
    final String? stockStatusText = isOutOfStock
        ? 'Out of stock'
        : isLimitReached
        ? 'Limit reached'
        : null;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 1.0 : 2.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canAdd
                    ? () {
                        _addScoopToOrder(scoopPrice);
                        _animateBadgeForProduct(itemKey);
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicWidth(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: AppTheme.isMobileOnly(context) ? 38 : 52,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.isMobileOnly(context) ? 8 : 14,
                      vertical: AppTheme.isMobileOnly(context) ? 6 : 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: !canAdd ? Colors.grey[100] : Colors.white,
                      border: Border.all(
                        color: !canAdd
                            ? (isOutOfStock
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.4))
                            : quantity > 0
                            ? AppTheme.primaryColor.withValues(alpha: 0.4)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: !canAdd
                              ? (isOutOfStock
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.12))
                              : quantity > 0
                              ? AppTheme.primaryColor.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${scoopPrice.tubProductName} (${scoopPrice.quantityInMl}ml) - ',
                                  style: TextStyle(
                                    color: canAdd
                                        ? Colors.grey[900]
                                        : Colors.grey[500],
                                    fontSize: AppTheme.isMobileOnly(context)
                                        ? 12
                                        : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '₹${scoopPrice.price}',
                                  style: TextStyle(
                                    color: canAdd
                                        ? AppTheme.primaryColor
                                        : Colors.grey[400],
                                    fontSize: AppTheme.isMobileOnly(context)
                                        ? 13
                                        : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (stockStatusText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              stockStatusText,
                              style: TextStyle(
                                color: isOutOfStock
                                    ? Colors.red[400]
                                    : Colors.orange[700],
                                fontSize: AppTheme.isMobileOnly(context)
                                    ? 10
                                    : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Floating badge for order quantity
            if (quantity > 0)
              Positioned(
                bottom: -15,
                left: -25,
                child: buildMenuBadge(
                  quantity,
                  onTap: orderItem != null
                      ? () {
                          _decreaseScoopQuantity(orderItem);
                          _animateBadgeForProduct(itemKey);
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getScoopQuantity(ScoopPrice scoopPrice) {
    return _currentOrderItems
        .where(
          (item) =>
              item.productType == 'scoops' &&
              item.scoopPriceId.toString() == scoopPrice.scoopPriceId,
        )
        .fold(0, (sum, item) => sum + item.pieces);
  }

  OrderItem? _getScoopOrderItem(ScoopPrice scoopPrice) {
    final idx = _currentOrderItems.indexWhere(
      (item) =>
          item.productType == 'scoops' &&
          item.scoopPriceId.toString() == scoopPrice.scoopPriceId,
    );
    return idx >= 0 ? _currentOrderItems[idx] : null;
  }

  Future<void> _addScoopToOrder(ScoopPrice scoopPrice) async {
    if (_isApiCallInFlight) return;
    _isApiCallInFlight = true;
    try {
      // If categories are available, show picker
      if (scoopPrice.categories.isNotEmpty) {
        _isApiCallInFlight = false; // unlock while user picks
        final selectedCategory = await _showScoopCategoryPicker(scoopPrice);
        if (selectedCategory == null) return; // User cancelled
        _isApiCallInFlight = true;

        final currentQty = _getQtyForExactCategory(
          scoopPrice.scoopPriceId,
          selectedCategory.tubCategoryId,
        );
        if (currentQty >= selectedCategory.availableScoops) {
          return;
        }

        final existingOrderItem = _getScoopOrderItemByCategory(
          scoopPrice,
          selectedCategory.tubCategoryId,
        );

        if (existingOrderItem != null) {
          final idToUse =
              existingOrderItem.orderItemId ?? existingOrderItem.itemId;
          await ApiService.increaseScoopOrderItemQuantity(idToUse);
        } else {
          await ApiService.addScoopToOrder(
            widget.orderId,
            scoopPrice.scoopPriceId,
            categoryId: selectedCategory.tubCategoryId,
          );
        }
        await _loadCurrentOrder();
      } else {
        // Fallback: no categories, add directly
        final existingOrderItem = _getScoopOrderItem(scoopPrice);

        if (existingOrderItem != null) {
          final idToUse =
              existingOrderItem.orderItemId ?? existingOrderItem.itemId;
          await ApiService.increaseScoopOrderItemQuantity(idToUse);
          await _loadCurrentOrder();
        } else {
          await ApiService.addScoopToOrder(
            widget.orderId,
            scoopPrice.scoopPriceId,
          );
          await _loadCurrentOrder();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ERROR ADDING SCOOP: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  Future<ScoopCategory?> _showScoopCategoryPicker(ScoopPrice scoopPrice) async {
    return showModalBottomSheet<ScoopCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(AppTheme.isMobileOnly(context) ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Row(
                children: [
                  Icon(
                    Icons.icecream_outlined,
                    color: AppTheme.primaryColor,
                    size: AppTheme.isMobileOnly(context) ? 24 : 32,
                  ),
                  SizedBox(width: AppTheme.isMobileOnly(context) ? 8 : 12),
                  Expanded(
                    child: Text(
                      '${scoopPrice.tubProductName} - Select Tub',
                      style: TextStyle(
                        fontSize: AppTheme.isMobileOnly(context) ? 18 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.isMobileOnly(context) ? 10 : 14,
                      vertical: AppTheme.isMobileOnly(context) ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${scoopPrice.price}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.isMobileOnly(context) ? 16 : 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose which tub size to take the scoop from:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: AppTheme.isMobileOnly(context) ? 13 : 17,
                ),
              ),
              const SizedBox(height: 16),
              // Category list
              ...scoopPrice.categories.map((category) {
                final int currentQty = _getQtyForExactCategory(
                  scoopPrice.scoopPriceId,
                  category.tubCategoryId,
                );
                final bool hasStock = category.availableScoops > 0;
                final bool isLimitReached =
                    hasStock && currentQty >= category.availableScoops;
                final bool canSelect = hasStock && !isLimitReached;
                final String statusText = !hasStock
                    ? 'Out of stock'
                    : isLimitReached
                    ? 'Limit reached'
                    : '${category.availableScoops - currentQty} scoops left';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSelect
                          ? () => Navigator.of(ctx).pop(category)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.isMobileOnly(context) ? 16 : 22,
                          vertical: AppTheme.isMobileOnly(context) ? 14 : 18,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: canSelect ? Colors.white : Colors.grey[100],
                          border: Border.all(
                            color: canSelect
                                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                : (!hasStock
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : Colors.orange.withValues(alpha: 0.45)),
                            width: 1.5,
                          ),
                          boxShadow: canSelect
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Tub icon with size
                            Container(
                              width: AppTheme.isMobileOnly(context) ? 48 : 64,
                              height: AppTheme.isMobileOnly(context) ? 48 : 64,
                              decoration: BoxDecoration(
                                color: canSelect
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_drink_outlined,
                                    color: canSelect
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                    size: AppTheme.isMobileOnly(context)
                                        ? 20
                                        : 28,
                                  ),
                                  Text(
                                    '${category.quantityInMl}ml',
                                    style: TextStyle(
                                      fontSize: AppTheme.isMobileOnly(context)
                                          ? 9
                                          : 13,
                                      fontWeight: FontWeight.bold,
                                      color: canSelect
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Category info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: AppTheme.isMobileOnly(context)
                                          ? 15
                                          : 20,
                                      fontWeight: FontWeight.w600,
                                      color: canSelect
                                          ? Colors.grey[900]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${category.tubsInStock} tubs | ${(category.liter * 1000).toInt()}ml available',
                                    style: TextStyle(
                                      fontSize: AppTheme.isMobileOnly(context)
                                          ? 12
                                          : 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: AppTheme.isMobileOnly(context)
                                          ? 11
                                          : 14,
                                      fontWeight: FontWeight.w600,
                                      color: !hasStock
                                          ? Colors.red[400]
                                          : (isLimitReached
                                                ? Colors.orange[700]
                                                : Colors.green[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  OrderItem? _getScoopOrderItemByCategory(
    ScoopPrice scoopPrice,
    String categoryId,
  ) {
    final idx = _currentOrderItems.indexWhere(
      (item) =>
          item.productType == 'scoops' &&
          item.scoopPriceId.toString() == scoopPrice.scoopPriceId &&
          item.tubCategory.toString() == categoryId,
    );
    return idx >= 0 ? _currentOrderItems[idx] : null;
  }

  // ── Stock helpers for cross-type ml accounting ─────────────────────────

  /// Returns capacity_ml for a tub category ID.
  int _tubCapacityMlForCategory(String categoryId) {
    for (final cat in _menu?.tubs?.categories ?? []) {
      if (cat.tubCategoryId == categoryId) {
        return int.tryParse(cat.quantityInMl) ?? 1000;
      }
    }
    return 1000;
  }

  /// Returns number of tub items (non-scoop) in the current order that belong
  /// to [tubProductName] (matched by product name) and [categoryId].
  int _tubsInOrderForCategory(String tubProductName, String categoryId) {
    if (tubProductName.isEmpty) return 0;
    return _currentOrderItems
        .where(
          (item) =>
              item.productType != 'scoops' &&
              item.tubCategory?.toString() == categoryId &&
              item.product.toUpperCase().contains(tubProductName.toUpperCase()),
        )
        .fold<int>(0, (sum, item) => sum + item.pieces);
  }

  /// Returns the effective liter (from the API) for a (scoopPriceId, categoryId) pair.
  double _literForScoopCategory(String scoopPriceId, String categoryId) {
    for (final sp in _menu?.scoops?.scoopPrices ?? []) {
      if (sp.scoopPriceId != scoopPriceId) continue;
      for (final cat in sp.categories) {
        if (cat.tubCategoryId == categoryId) return cat.liter;
      }
    }
    return 0.0;
  }

  /// Effective scoops available for [scoopPriceId] / [categoryId] after
  /// subtracting ml consumed by tubs already in the current order.
  int _effectiveScoopsAvailable({
    required String scoopPriceId,
    required String categoryId,
    required int scoopMl,
    required int tubCapacityMl,
    required String tubProductName,
  }) {
    final apiMl = (_literForScoopCategory(scoopPriceId, categoryId) * 1000)
        .toInt();
    final tubsInOrder = _tubsInOrderForCategory(tubProductName, categoryId);
    final tubMlConsumed = tubsInOrder * tubCapacityMl;
    final availMl = (apiMl - tubMlConsumed).clamp(0, apiMl);
    return scoopMl > 0 ? availMl ~/ scoopMl : 0;
  }

  Future<void> _decreaseScoopQuantity(OrderItem orderItem) async {
    if (_isApiCallInFlight) return;
    _isApiCallInFlight = true;
    try {
      final idToUse = orderItem.orderItemId ?? orderItem.itemId;
      // Optimistic local update
      final idx = _currentOrderItems.indexWhere(
        (i) => i.itemId == orderItem.itemId,
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
              tubCategory: _currentOrderItems[idx].tubCategory,
              scoopPriceId: _currentOrderItems[idx].scoopPriceId,
              productType: _currentOrderItems[idx].productType,
            );
          } else {
            _currentOrderItems.removeAt(idx);
          }
          _updateTotals();
        });
      }
      if (orderItem.pieces > 1) {
        await ApiService.decreaseScoopOrderItemQuantity(idToUse);
      } else {
        await ApiService.deleteScoopOrderItem(idToUse);
      }
    } catch (e) {
      await _loadCurrentOrder();
      if (kDebugMode) debugPrint('ERROR DECREASING SCOOP: $e');
    } finally {
      _isApiCallInFlight = false;
    }
  }

  int _getScoopsCount() => _scoopsCount;
}
