import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/debug_service.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../widgets/order_detail_dialog.dart';
import '../widgets/emoji_color_dialog.dart';
import 'menu_page.dart';
import 'settings_page.dart';
import '../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  DailySummary? _dailySummary;
  bool _isLoading = true;
  String _error = '';
  late AnimationController _animationController;
  late AnimationController _staggerController;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final summary = await ApiService.getDailySummary(
        dateString,
        forceRefresh: forceRefresh,
      );

      // Auto-delete empty pending orders (cleanup for orders left empty)
      final emptyOrders = summary.orders
          .where((order) => order.items.isEmpty && !order.completed)
          .toList();
      if (emptyOrders.isNotEmpty) {
        // Parallel delete — N orders in 1 round-trip window instead of N sequential
        await Future.wait(
          emptyOrders.map((o) async {
            try {
              await ApiService.deleteOrder(o.orderId);
            } catch (_) {}
          }),
        );
        // Filter locally instead of re-fetching from server
        final emptyIds = emptyOrders.map((o) => o.orderId).toSet();
        final cleanOrders = summary.orders
            .where((o) => !emptyIds.contains(o.orderId))
            .toList();
        final cleanSummary = DailySummary(
          totalOrders: cleanOrders.length,
          totalRevenue: summary.totalRevenue,
          totalUpi: summary.totalUpi,
          totalCash: summary.totalCash,
          completedOrders: (summary.completedOrders ?? 0),
          pendingOrders: (summary.pendingOrders ?? 0) - emptyOrders.length,
          orders: cleanOrders,
        );
        setState(() {
          _dailySummary = cleanSummary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _dailySummary = summary;
          _isLoading = false;
        });
      }

      _animationController.forward();
      _staggerController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Order> _getFilteredOrders() {
    if (_dailySummary == null) return [];
    return _dailySummary!.orders;
  }

  /// Computes sorted orders for display and their corresponding display numbers.
  ///
  /// Display numbers are assigned based on creation time (oldest order = #1).
  /// The returned list is sorted by status (pending first) then by date (newest first),
  /// but each order retains its proper sequential number based on when it was created.
  (List<Order> sortedOrders, Map<int, int> displayNumbers) _computeSortedOrdersWithDisplayNumbers() {
    final filtered = _getFilteredOrders();
    if (filtered.isEmpty) {
      return (<Order>[], <int, int>{});
    }

    // Create a copy for sorting by creation time to assign display numbers
    final ordersByCreationTime = List<Order>.from(filtered);
    // Sort by creation date (oldest first) to assign sequential numbers
    ordersByCreationTime.sort((a, b) {
      final aDate = a.parsedOrderDate;
      final bDate = b.parsedOrderDate;
      if (aDate != null && bDate != null) {
        return aDate.compareTo(bDate); // Oldest first
      }
      // Fallback: use orderId as proxy for creation time if date unavailable
      return a.orderId.compareTo(b.orderId);
    });

    // Assign display numbers based on creation order (oldest = #1)
    final displayNumbers = <int, int>{};
    for (int i = 0; i < ordersByCreationTime.length; i++) {
      displayNumbers[ordersByCreationTime[i].orderId] = i + 1;
    }

    // Now create the display-sorted list (pending first, then by date newest first)
    final sortedForDisplay = List<Order>.from(filtered);
    sortedForDisplay.sort((a, b) {
      // First: sort by completion status (pending first)
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      // Second: sort by date (newest first for display)
      final bDate = b.parsedOrderDate;
      final aDate = a.parsedOrderDate;
      if (bDate != null && aDate != null) return bDate.compareTo(aDate);
      return 0;
    });

    return (sortedForDisplay, displayNumbers);
  }

  Future<void> _createNewOrder() async {
    try {
      final order = await ApiService.createOrder();
      DebugService.log('Order : $order');
      if (mounted) {
        // Calculate the new order's display number (will be the highest = total orders)
        int displayNumber = 1;
        if (_dailySummary != null) {
          // Newest order gets the next sequential number
          displayNumber = _dailySummary!.orders.length + 1;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MenuPage(orderId: order.orderId, orderIndex: displayNumber),
          ),
        );
        _staggerController.reset();
        _loadDashboardData(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
    }
  }

  Future<void> _showOrderDetail(Order order) async {
    // Pass displayIndex to OrderDetailDialog for correct UI display
    // Use displayIndex from API for all logic and display
    final result = await showDialog(
      context: context,
      builder: (context) => OrderDetailDialog(
        order: order,
        onMarkComplete: () {
          _loadDashboardData(forceRefresh: true);
        },
        onMarkIncomplete: () async {
          Navigator.of(context).pop();
          await _markOrderIncomplete(order);
        },
        onDelete: () async {
          Navigator.of(context).pop();
          await _deleteOrder(order);
        },
      ),
    );
    if (result == true) {
      _loadDashboardData(forceRefresh: true);
      return;
    }

    if (result is Map &&
        result.containsKey('upi') &&
        result.containsKey('cash')) {
      try {
        await ApiService.markOrderComplete(
          order.orderId,
          upiAmount: result['upi'],
          cashAmount: result['cash'],
        );
      } catch (e) {
        debugPrint('Error completing order: $e');
      } finally {
        _loadDashboardData(forceRefresh: true);
      }
    }
  }

  Future<void> _markOrderIncomplete(Order order) async {
    try {
      await ApiService.markOrderIncomplete(order.orderId);
      _loadDashboardData(forceRefresh: true);

      // Order marked incomplete notification removed per user request
    } catch (e) {
      debugPrint('Error marking order incomplete: $e');
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteOrder(order.orderId);
        _loadDashboardData(forceRefresh: true);

        // Order deleted notification removed per user request
      } catch (e) {
        debugPrint('Error deleting order: $e');
      }
    }
  }

  Widget _buildMobileDrawer() {
    final isTablet = AppTheme.isTablet(context);
    return Drawer(
      width: isTablet ? 320 : null,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 26 : 20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: isTablet ? 30 : 24,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Text(
                    'Fruitice',
                    style: AppTheme.headingMedium(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 24 : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 28 : 20),
            _buildDrawerItem(
              icon: Icons.list_alt,
              title: 'Orders',
              subtitle: '${_dailySummary?.orders.length ?? 0} orders',
              isSelected: _selectedTabIndex == 0,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(height: 16),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Manage preferences',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final isTablet = AppTheme.isTablet(context);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 3 : 2,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          size: isTablet ? 32 : 28,
        ),
        title: Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: isTablet ? 18 : 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodySmall.copyWith(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.7)
                : AppTheme.textTertiary,
            fontSize: isTablet ? 14 : 13,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = AppTheme.isTablet(context);
    final isMobile = AppTheme.isMobile(context);
    final orientation = mediaQuery.orientation;

    // Pre-compute summary cards once (was called 18× per build)
    final cards = _dailySummary != null
        ? _buildSummaryCards(isTablet, compact: true)
        : <Widget>[];

    // Pre-compute filtered & sorted orders with proper display numbers
    // Orders are sorted by status (pending first) then by date (newest first for display)
    // But display numbers are assigned by creation time (oldest = #1, newest = highest)
    final (sortedOrders, displayNumbers) = _computeSortedOrdersWithDisplayNumbers();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: _buildMobileDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        toolbarHeight: AppTheme.responsiveValue(
          context,
          mobile: 56,
          tablet: 72,
          desktop: 90,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: isTablet ? 30 : 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Fruitice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 28 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'sans-serif-black',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              iconSize: isTablet ? 26 : 20,
              onPressed: () => _loadDashboardData(forceRefresh: true),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: isTablet ? 80 : 48,
                    color: Colors.red,
                  ),
                  SizedBox(height: isTablet ? 20 : 12),
                  Text(
                    'Failed to load data',
                    style: AppTheme.headingMedium(
                      context,
                    ).copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: isTablet ? 28 : 16),
                  ElevatedButton.icon(
                    onPressed: () => _loadDashboardData(forceRefresh: true),
                    icon: Icon(Icons.refresh, size: isTablet ? 24 : 18),
                    label: Text(
                      'Retry',
                      style: TextStyle(fontSize: isTablet ? 18 : 14),
                    ),
                  ),
                ],
              ),
            )
          : _dailySummary == null
          ? Center(
              child: Text(
                'No data available',
                style: AppTheme.headingMedium(context),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadDashboardData(forceRefresh: true),
              child: CustomScrollView(
                slivers: [
                  // Summary section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 4,
                        vertical: isTablet ? 6 : 4,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 4,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.07),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_dailySummary != null) ...[
                            if (isTablet)
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 1, child: cards[0]),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 1, child: cards[1]),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 1, child: cards[2]),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 1, child: cards[3]),
                                  ],
                                ),
                              )
                            else if (isMobile)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: cards[0]),
                                      const SizedBox(width: 4),
                                      Expanded(child: cards[1]),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: cards[2]),
                                      const SizedBox(width: 4),
                                      Expanded(child: cards[3]),
                                    ],
                                  ),
                                ],
                              )
                            else
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: cards[0]),
                                    const SizedBox(width: 8),
                                    Expanded(child: cards[1]),
                                    const SizedBox(width: 8),
                                    Expanded(child: cards[2]),
                                    const SizedBox(width: 8),
                                    Expanded(child: cards[3]),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Removed orders section header for minimal UI

                  // Orders grid
                  sortedOrders.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            height: 200,
                            margin: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: isTablet ? 80 : 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: isTablet ? 20 : 12),
                                Text(
                                  () {
                                    switch (_selectedTabIndex) {
                                      case 1:
                                        return 'No pending orders';
                                      case 2:
                                        return 'No completed orders';
                                      default:
                                        return 'No orders today';
                                    }
                                  }(),
                                  style: AppTheme.headingMedium(context)
                                      .copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                SizedBox(height: isTablet ? 8 : 6),
                                Text(
                                  _selectedTabIndex == 0
                                      ? 'Tap the + button to create your first order'
                                      : 'No orders in this category',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.responsiveValue(
                                context,
                                mobile: 4,
                                tablet: 8,
                                desktop: 18,
                              ),
                            ),
                            child: StaggeredGrid.count(
                              crossAxisCount: AppTheme.responsiveValue(
                                context,
                                mobile: orientation == Orientation.landscape
                                    ? 3
                                    : 2,
                                tablet: orientation == Orientation.landscape
                                    ? 4
                                    : 3,
                                desktop: orientation == Orientation.landscape
                                    ? 6
                                    : 6,
                              ).round(),
                              mainAxisSpacing: AppTheme.responsiveValue(
                                context,
                                mobile: 4,
                                tablet: 8,
                                desktop: 16,
                              ),
                              crossAxisSpacing: AppTheme.responsiveValue(
                                context,
                                mobile: 4,
                                tablet: 8,
                                desktop: 16,
                              ),
                              children: sortedOrders.asMap().entries.map((entry) {
                                final listIndex = entry.key;
                                final order = entry.value;
                                // Get the proper display number based on creation order
                                final displayNumber = displayNumbers[order.orderId] ?? (listIndex + 1);
                                final rawDelay = listIndex * 0.1;
                                final animationDelay = rawDelay.clamp(0.0, 1.0);
                                final animation =
                                    Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(
                                        parent: _staggerController,
                                        curve: Interval(
                                          animationDelay,
                                          (animationDelay + 0.3).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                    );
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        0,
                                        50 * (1 - animation.value),
                                      ),
                                      child: Opacity(
                                        opacity: animation.value,
                                        child: Transform.scale(
                                          scale: 0.8 + (0.2 * animation.value),
                                          child: RepaintBoundary(
                                            child: OrderCard(
                                              order: order,
                                              displayNumber: displayNumber,
                                              onTap: () => _showOrderDetail(order),
                                              onDoubleTap: order.completed
                                                  ? null
                                                  : () => _showOrderOptions(
                                                      order,
                                                    ),
                                              onLongPress: order.completed
                                                  ? null
                                                  : () => _showOrderOptions(
                                                      order,
                                                    ),
                                              onEmojiColorTap: () async {
                                                final prevEmoji = order.emoji;
                                                final prevColor = order.color;
                                                await showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      EmojiColorDialog(
                                                        order: order,
                                                        onChanged: () {},
                                                      ),
                                                );
                                                if (order.emoji != prevEmoji ||
                                                    order.color != prevColor) {
                                                  try {
                                                    await ApiService.updateOrderAppearance(
                                                      order.orderId,
                                                      emoji: order.emoji,
                                                      color: order.color,
                                                    );
                                                    _loadDashboardData(
                                                      forceRefresh: true,
                                                    );
                                                  } catch (e) {
                                                    debugPrint(
                                                      'Error updating order appearance: $e',
                                                    );
                                                  }
                                                }
                                              },
                                              onOrderDeleted: () =>
                                                  _loadDashboardData(
                                                    forceRefresh: true,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                  // Bottom padding for FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButton: SizedBox(
        height: isTablet ? 76 : 60,
        width: isTablet ? 76 : 60,
        child: FloatingActionButton(
          onPressed: _createNewOrder,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 22 : 16),
          ),
          child: Icon(
            Icons.add,
            size: isTablet ? 48 : 44,
            weight: 900, // Use boldest available weight
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSummaryCards(bool isTablet, {bool compact = false}) {
    final cards = [
      _SummaryCard(
        title: 'Orders',
        value: '${_dailySummary!.totalOrders}',
        icon: Icons.shopping_cart,
        color: Colors.blue,
        isTablet: isTablet,
        compact: compact,
      ),
      _SummaryCard(
        title: 'Sales',
        value: '₹${_formatIndian(_dailySummary!.totalRevenue)}',
        icon: Icons.attach_money,
        color: Colors.teal,
        isTablet: isTablet,
        compact: compact,
      ),
      _SummaryCard(
        title: 'UPI',
        value: '₹${_formatIndian(_dailySummary!.totalUpi)}',
        icon: Icons.payment,
        color: Colors.purple,
        isTablet: isTablet,
        compact: compact,
      ),
      _SummaryCard(
        title: 'Cash',
        value: '₹${_formatIndian(_dailySummary!.totalCash)}',
        icon: Icons.money,
        color: Colors.indigo,
        isTablet: isTablet,
        compact: compact,
      ),
    ];

    // Removed the automatic Expanded wrapper as the calling code handles it
    return cards;
  }

  /// Format number in Indian numbering system (e.g. 1,23,456)
  static String _formatIndian(double value) {
    final intVal = value.truncate();
    if (intVal < 1000) return intVal.toString();
    final str = intVal.toString();
    final last3 = str.substring(str.length - 3);
    String remaining = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    while (remaining.length > 2) {
      buffer.write(remaining.substring(0, remaining.length - 2));
      buffer.write(',');
      remaining = remaining.substring(remaining.length - 2);
    }
    buffer.write(remaining);
    return '$buffer,$last3';
  }

  void _showOrderOptions(Order order) {
    // Open MenuPage and refresh dashboard when returning
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(
          orderId: order.orderId,
          orderIndex: order.displayIndex,
          initialOrderItems: order.items,
        ),
      ),
    ).then((result) {
      // Always refresh dashboard when returning from menu page
      _staggerController.reset();
      _loadDashboardData(forceRefresh: true);
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isTablet;
  final bool compact;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isTablet,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 2 : 1),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? (isTablet ? 8 : 6) : (isTablet ? 10 : 6),
        vertical: compact ? (isTablet ? 6 : 4) : (isTablet ? 8 : 5),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? (isTablet ? 11 : 9) : (isTablet ? 12 : 10),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: compact ? (isTablet ? 16 : 14) : (isTablet ? 20 : 16),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...
}


class PaymentDialog extends StatefulWidget {
  final Order order;
  final Function(double upiAmount, double cashAmount) onPaymentConfirmed;

  const PaymentDialog({
    super.key,
    required this.order,
    required this.onPaymentConfirmed,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMode = 'Cash'; // Cash, UPI, Both
  final _upiController = TextEditingController();
  final _cashController = TextEditingController();

  @override
  void dispose() {
    _upiController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_paymentMode == 'Both') {
      final upiAmount = double.tryParse(_upiController.text) ?? 0.0;
      final cashAmount = double.tryParse(_cashController.text) ?? 0.0;
      final totalAmount = widget.order.totalPrice;

      if (_upiController.text.isNotEmpty && _cashController.text.isEmpty) {
        final remainingCash = totalAmount - upiAmount;
        if (remainingCash >= 0) {
          _cashController.text = remainingCash.toStringAsFixed(2);
        }
      } else if (_cashController.text.isNotEmpty &&
          _upiController.text.isEmpty) {
        final remainingUpi = totalAmount - cashAmount;
        if (remainingUpi >= 0) {
          _upiController.text = remainingUpi.toStringAsFixed(2);
        }
      }
    }
  }

  Widget _buildPaymentModeChip(String mode, bool isTablet) {
    final isSelected = _paymentMode == mode;
    final displayText = mode == 'Both' ? 'Both (Cash + UPI)' : mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMode = mode;
          _upiController.clear();
          _cashController.clear();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 12,
          vertical: isTablet ? 14 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: isTablet ? 16 : 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isTablet ? 600 : double.infinity,
        padding: EdgeInsets.all(isTablet ? 28 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Payment',
              style: TextStyle(
                fontSize: isTablet ? 20 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 20 : 12),

            // Order summary
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Always use displayIndex from API for order number
                  Text(
                    'Order #${widget.order.displayIndex}',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.order.items.map(
                    (item) => Text(
                      '${item.product} (${item.pieces}x) - ₹${item.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: isTablet ? 15 : 10),
                    ),
                  ),
                  Divider(height: isTablet ? 20 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${widget.order.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: isTablet ? 24 : 16),

            // Payment mode selection
            Text(
              'Payment Mode:',
              style: TextStyle(
                fontSize: isTablet ? 20 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 6),

            // Payment mode buttons as an alternative to deprecated RadioGroup
            Wrap(
              spacing: 8,
              children: [
                _buildPaymentModeChip('Cash', isTablet),
                _buildPaymentModeChip('UPI', isTablet),
                _buildPaymentModeChip('Both', isTablet),
              ],
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Payment amount fields
            if (_paymentMode == 'UPI' || _paymentMode == 'Both')
              Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                child: TextField(
                  controller: _upiController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'UPI Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _onAmountChanged(),
                ),
              ),

            if (_paymentMode == 'Cash' || _paymentMode == 'Both')
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cash Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _onAmountChanged(),
              ),

            SizedBox(height: isTablet ? 24 : 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: isTablet ? 16 : 12),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final upiAmount =
                          double.tryParse(_upiController.text) ?? 0.0;
                      final cashAmount =
                          double.tryParse(_cashController.text) ?? 0.0;
                      final totalEntered = upiAmount + cashAmount;

                      if ((totalEntered - widget.order.totalPrice).abs() <
                          0.01) {
                        Navigator.of(context).pop();
                        widget.onPaymentConfirmed(upiAmount, cashAmount);
                      } else {
                        // Payment validation notification removed per user request
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 8,
                      ),
                    ),
                    child: Text(
                      'Complete Order',
                      style: TextStyle(fontSize: isTablet ? 18 : 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
