import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/debug_service.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import '../waffle/screens/waffle_dashboard_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../widgets/order_detail_dialog.dart';
import '../widgets/emoji_color_dialog.dart';
import 'menu_page.dart';
import 'settings_page.dart';
import 'b2b/b2b_password_gate_page.dart';
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
  int _selectedBrandIndex = 0;
  final GlobalKey _waffleDashboardKey = GlobalKey();

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

    switch (_selectedTabIndex) {
      case 0: // All orders
        return _dailySummary!.orders;
      case 1: // Pending orders
        return _dailySummary!.orders
            .where((order) => !order.completed)
            .toList();
      case 2: // Completed orders
        return _dailySummary!.orders.where((order) => order.completed).toList();
      default:
        return _dailySummary!.orders;
    }
  }

  Future<void> _createNewOrder() async {
    try {
      final order = await ApiService.createOrder();
      DebugService.log('Order : $order');
      if (mounted) {
        // Order created notification removed per user request
        int newOrderIndex = 1;
        if (_dailySummary != null && _dailySummary!.orders.isNotEmpty) {
          final sortedOrders = List<Order>.from(_dailySummary!.orders);
          // Sort by completion status first (pending first), then by date (newest first)
          sortedOrders.sort((a, b) {
            // If completion status is different, put pending orders first
            if (a.completed != b.completed) {
              return a.completed
                  ? 1
                  : -1; // false (pending) comes before true (completed)
            }
            // If same completion status, sort by date (newest first)
            final bDate = b.parsedOrderDate;
            final aDate = a.parsedOrderDate;
            if (bDate != null && aDate != null) return bDate.compareTo(aDate);
            return 0;
          });
          newOrderIndex =
              sortedOrders.indexWhere((o) => o.orderId == order.orderId) + 1;
          if (newOrderIndex == 0) newOrderIndex = sortedOrders.length + 1;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MenuPage(orderId: order.orderId, orderIndex: newOrderIndex),
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
    if (result is Map &&
        result.containsKey('upi') &&
        result.containsKey('cash')) {
      try {
        await ApiService.markOrderComplete(
          order.orderId,
          upiAmount: result['upi'],
          cashAmount: result['cash'],
        );
        _loadDashboardData(forceRefresh: true);
        // Order completed notification removed per user request
      } catch (e) {
        debugPrint('Error completing order: $e');
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
              title: 'All Orders',
              subtitle: '${_dailySummary?.orders.length ?? 0} orders',
              isSelected: _selectedTabIndex == 0,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                  _tabController.index = 0;
                });
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.pending_actions,
              title: 'Pending Orders',
              subtitle: '${_dailySummary?.pendingOrders ?? 0} pending',
              isSelected: _selectedTabIndex == 1,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                  _tabController.index = 1;
                });
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.check_circle,
              title: 'Completed Orders',
              subtitle: '${_dailySummary?.completedOrders ?? 0} completed',
              isSelected: _selectedTabIndex == 2,
              onTap: () {
                setState(() {
                  _selectedTabIndex = 2;
                  _tabController.index = 2;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(height: 40),
            _buildDrawerItem(
              icon: Icons.business_center_outlined,
              title: 'B2B Invoices',
              subtitle: 'Franchise billing',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const B2BPasswordGatePage(),
                  ),
                );
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

  Widget _buildBrandToggle() {
    final isTablet = AppTheme.isTablet(context);
    const brands = ['Fruitice', 'Waffle'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(brands.length, (index) {
          final selected = _selectedBrandIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBrandIndex = index;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 12 : 10,
                horizontal: isTablet ? 20 : 16,
              ),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                brands[index],
                style: TextStyle(
                  color: selected ? AppTheme.primaryColor : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          );
        }),
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

    // Pre-compute filtered & sorted orders once (was computed 2× per build with O(n log n) sort)
    final sortedOrders = () {
      final filtered = _getFilteredOrders();
      final sorted = List<Order>.from(filtered);
      sorted.sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        final bDate = b.parsedOrderDate;
        final aDate = a.parsedOrderDate;
        if (bDate != null && aDate != null) return bDate.compareTo(aDate);
        return 0;
      });
      return sorted;
    }();

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
            Expanded(child: _buildBrandToggle()),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              iconSize: isTablet ? 26 : 20,
              onPressed: () {
                if (_selectedBrandIndex == 0) {
                  _loadDashboardData(forceRefresh: true);
                } else {
                  final state = _waffleDashboardKey.currentState;
                  if (state != null) {
                    try {
                      (state as dynamic).refresh();
                    } catch (_) {}
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedBrandIndex,
        children: [
          _buildFruiticeBody(
            isTablet,
            isMobile,
            orientation,
            cards,
            sortedOrders,
          ),
          WaffleDashboardScreen(key: _waffleDashboardKey),
        ],
      ),
      floatingActionButton: SizedBox(
        height: isTablet ? 76 : 60,
        width: isTablet ? 76 : 60,
        child: FloatingActionButton(
          onPressed: () {
            if (_selectedBrandIndex == 0) {
              _createNewOrder();
            } else {
              final state = _waffleDashboardKey.currentState;
              if (state != null) {
                try {
                  (state as dynamic).createOrder();
                } catch (_) {}
              }
            }
          },
          backgroundColor: AppTheme.primaryDark,
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

  Widget _buildFruiticeBody(
    bool isTablet,
    bool isMobile,
    Orientation orientation,
    List<Widget> cards,
    List<Order> sortedOrders,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
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
      );
    }

    if (_dailySummary == null) {
      return Center(
        child: Text(
          'No data available',
          style: AppTheme.headingMedium(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...cards,
          const SizedBox(height: 20),
          if (sortedOrders.isEmpty) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  _selectedTabIndex == 0
                      ? 'No orders today. Tap + to create one.'
                      : _selectedTabIndex == 1
                      ? 'No pending orders.'
                      : 'No completed orders yet.',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
          ] else ...[
            ...sortedOrders.asMap().entries.map(
              (entry) {
                final index = entry.key + 1; // Sequential 1-based index
                final order = entry.value;
                return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OrderCard(
                  order: order,
                  index: index,
                  onTap: () => _showOrderDetail(order),
                  onDoubleTap: order.completed
                      ? null
                      : () => _showOrderOptions(order),
                  onLongPress: order.completed
                      ? null
                      : () => _showOrderOptions(order),
                  onEmojiColorTap: () async {
                    final prevEmoji = order.emoji;
                    final prevColor = order.color;
                    await showDialog(
                      context: context,
                      builder: (context) =>
                          EmojiColorDialog(order: order, onChanged: () {}),
                    );
                    if (order.emoji != prevEmoji || order.color != prevColor) {
                      try {
                        await ApiService.updateOrderAppearance(
                          order.orderId,
                          emoji: order.emoji,
                          color: order.color,
                        );
                        _loadDashboardData(forceRefresh: true);
                      } catch (_) {}
                    }
                  },
                  onOrderDeleted: () => _loadDashboardData(forceRefresh: true),
                ),
              );
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  List<Widget> _buildSummaryCards(bool isTablet, {bool compact = false}) {
    // Removed unused isPortraitTablet variable
    final cards = [
      _SummaryCard(
        title: 'Orders',
        value: '${_dailySummary!.totalOrders}',
        icon: Icons.shopping_cart,
        color: AppTheme.primaryColor,
        isTablet: isTablet,
        compact: compact,
      ),
      _SummaryCard(
        title: 'Done',
        value: '${_dailySummary!.completedOrders ?? 0}',
        icon: Icons.check_circle,
        color: Colors.green,
        isTablet: isTablet,
        compact: compact,
      ),
      _SummaryCard(
        title: 'Pending',
        value: '${_dailySummary!.pendingOrders ?? 0}',
        icon: Icons.pending_actions,
        color: Colors.orange,
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

class _OrdersStatCard extends StatelessWidget {
  final int orders;
  final int done;
  final int pending;

  const _OrdersStatCard({
    required this.orders,
    required this.done,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$orders',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Orders',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: Colors.grey[300]),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '$done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: Colors.grey[300]),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '$pending',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonePendingCard extends StatelessWidget {
  final int done;
  final int pending;
  final bool isTablet;
  final bool compact;

  const _DonePendingCard({
    required this.done,
    required this.pending,
    required this.isTablet,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = compact
        ? (isTablet ? 12.0 : 12.0)
        : (isTablet ? 17.0 : 12.0);

    Widget half(
      String label,
      String value,
      Color color,
      BorderRadius borderRadius,
    ) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? (isTablet ? 6 : 4) : (isTablet ? 16 : 8),
            vertical: compact ? (isTablet ? 6 : 4) : (isTablet ? 8 : 5),
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: borderRadius,
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 2 : 1),
      child: Row(
        children: [
          half(
            'Done',
            '$done',
            Colors.green,
            const BorderRadius.only(
              topLeft: Radius.circular(7),
              bottomLeft: Radius.circular(7),
            ),
          ),
          const SizedBox(width: 2),
          half(
            'Pending',
            '$pending',
            Colors.orange,
            const BorderRadius.only(
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
          ),
        ],
      ),
    );
  }
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
