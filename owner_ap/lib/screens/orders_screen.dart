import 'package:flutter/material.dart';
import '../services/base_api_service.dart';
import '../theme/WOFL_theme.dart';
import '../widgets/widgets.dart';
import 'edit_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedRange = 'today';
  bool _isLoading = true;
  String? _errorMessage;
  DateTimeRange? _customRange;

  // Summary data
  int _orderCount = 0;
  double _totalRevenue = 0;
  double _upiAmount = 0;
  double _cashAmount = 0;

  // Orders list
  List<OrderItem> _orders = [];
  String _searchQuery = '';
  String _sortBy = 'newest';
  int _currentPage = 0;
  final int _ordersPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadOrdersData();
  }

  Future<void> _loadOrdersData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint = _buildEndpoint();
      print('Loading orders from: $endpoint'); // Debug log
      final response = await BaseApiService.get(endpoint);
      print('Orders API response: $response'); // Debug log

      if (response is Map<String, dynamic>) {
        final summary = response['summary'] as Map<String, dynamic>? ?? {};
        final ordersData = response['orders'] as List<dynamic>? ?? [];

        if (!mounted) return;

        setState(() {
          _orderCount = _toInt(summary['orders_count']);
          _totalRevenue = _toDouble(summary['total_amount']);
          _upiAmount = _toDouble(summary['total_upi']);
          _cashAmount = _toDouble(summary['total_cash']);
          _orders = ordersData
              .map((order) => OrderItem.fromJson(order))
              .toList();
          _currentPage = 0;
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Orders loaded from backend - ${_orders.length} orders found',
                  ),
                ],
              ),
              backgroundColor: WOFLTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw ApiException('Invalid response format from orders API');
      }
    } catch (e) {
      print('Orders API error: $e'); // Debug log

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load orders: ${e.toString()}';
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Backend connection failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: WOFLTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  // Removed _generateMockOrders method - using real backend data only

  String _buildEndpoint() {
    if (_selectedRange == 'custom' && _customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end;
      return '/orders/?date=custom&start_date=${start.toIso8601String().substring(0, 10)}&end_date=${end.toIso8601String().substring(0, 10)}';
    }
    return '/orders/?date=$_selectedRange';
  }

  void _changeRange(String range) {
    if (_selectedRange == range) return;

    setState(() {
      _selectedRange = range;
      if (range != 'custom') {
        _customRange = null;
      }
    });

    _loadOrdersData();
  }

  Future<void> _pickCustomRange() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => _CompactDateRangeDialog(
        initial: _customRange,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _customRange = result;
      _selectedRange = 'custom';
    });
    _loadOrdersData();
  }

  String _selectedRangeLabel() {
    if (_selectedRange == 'custom' && _customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end;
      return '${_formatDate(start)} to ${_formatDate(end)}';
    }

    switch (_selectedRange) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'this_year':
        return 'This Year';
      default:
        return 'Today';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  List<OrderItem> get _filteredOrders {
    var filtered = _orders.where((order) {
      if (_searchQuery.isEmpty) return true;
      return order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          order.items.any(
            (item) => item.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
    }).toList();

    // Sort orders
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_high':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_low':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WOFLTheme.background,
      body: Container(
        decoration: BoxDecoration(gradient: WOFLTheme.backgroundGradient),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    WOFLTheme.primary,
                  ),
                ),
              )
            : _errorMessage != null
            ? _buildErrorState(context)
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isCompact = screenWidth < 1000;

                    if (isCompact) {
                      return Padding(
                        padding: const EdgeInsets.all(WOFLTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: WOFLTheme.spacingM),
                            _buildSummaryCards(),
                            const SizedBox(height: WOFLTheme.spacingM),
                            _buildTopBar(),
                            const SizedBox(height: WOFLTheme.spacingM),
                            Expanded(child: _buildOrdersList()),
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: (screenWidth * 0.3).clamp(300.0, 400.0),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(WOFLTheme.spacingM),
                            child: _buildSidebar(context),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: WOFLTheme.spacingM,
                              right: WOFLTheme.spacingM,
                              bottom: WOFLTheme.spacingM,
                            ),
                            child: _buildMainContent(context),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: WOFLCard(
        padding: const EdgeInsets.all(WOFLTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: WOFLTheme.error, size: 48),
            const SizedBox(height: WOFLTheme.spacingM),
            Text(
              'Unable to load order data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: WOFLTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WOFLTheme.spacingS),
            Text(
              _errorMessage ?? 'Something went wrong while loading orders.',
              style: TextStyle(color: WOFLTheme.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WOFLTheme.spacingL),
            WOFLButton(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: _loadOrdersData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return WOFLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: WOFLTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: WOFLTheme.creamWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: WOFLTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Management',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: WOFLTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: WOFLTheme.spacingXS),
                    Text(
                      'Track sales activity and review order history',
                      style: TextStyle(color: WOFLTheme.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WOFLTheme.spacingL),
          _buildDateRangeSection(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: TextStyle(
            color: WOFLTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: WOFLTheme.spacingM),
        Wrap(
          spacing: WOFLTheme.spacingS,
          runSpacing: WOFLTheme.spacingS,
          children: [
            _buildDateChip('Today', 'today'),
            _buildDateChip('Week', 'this_week'),
            _buildDateChip('Month', 'this_month'),
            _buildDateChip('Year', 'this_year'),
            _buildCustomRangeChip(),
          ],
        ),
        const SizedBox(height: WOFLTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(WOFLTheme.spacingM),
          decoration: BoxDecoration(
            color: WOFLTheme.softOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WOFLTheme.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: WOFLTheme.primary, size: 18),
              const SizedBox(width: WOFLTheme.spacingS),
              Text(
                _selectedRangeLabel(),
                style: TextStyle(
                  color: WOFLTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(String label, String range) {
    final isActive = _selectedRange == range;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeRange(range),
        borderRadius: BorderRadius.circular(WOFLTheme.badgeRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WOFLTheme.spacingM,
            vertical: WOFLTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isActive ? WOFLTheme.primary : WOFLTheme.creamWhite,
            borderRadius: BorderRadius.circular(WOFLTheme.badgeRadius),
            border: Border.all(
              color: isActive ? WOFLTheme.primary : WOFLTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? WOFLTheme.creamWhite : WOFLTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeChip() {
    final isActive = _selectedRange == 'custom';
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickCustomRange,
          borderRadius: BorderRadius.circular(WOFLTheme.badgeRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WOFLTheme.spacingM,
              vertical: WOFLTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: isActive ? WOFLTheme.primary : WOFLTheme.creamWhite,
              borderRadius: BorderRadius.circular(WOFLTheme.badgeRadius),
              border: Border.all(
                color: isActive ? WOFLTheme.primary : WOFLTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isActive ? WOFLTheme.creamWhite : WOFLTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: WOFLTheme.spacingS),
                Text(
                  isActive && _customRange != null
                      ? '${_fmtD(_customRange!.start)} – ${_fmtD(_customRange!.end)}'
                      : 'Custom',
                  style: TextStyle(
                    color: isActive ? WOFLTheme.creamWhite : WOFLTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  String _fmtD(DateTime d) =>
      '${d.day} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]}';

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final spacing = WOFLTheme.spacingS;
        final columns = screenWidth < 600
            ? 1
            : screenWidth < 1000
            ? 2
            : 4;
        final cardWidth = (screenWidth - (columns - 1) * spacing) / columns;

        final cards = [
          _buildSummaryCard(
            Icons.shopping_cart_rounded,
            'Total Orders',
            _orderCount.toString(),
            WOFLTheme.primary,
          ),
          _buildSummaryCard(
            Icons.attach_money_rounded,
            'Revenue',
            '₹${_totalRevenue.toStringAsFixed(0)}',
            WOFLTheme.success,
          ),
          _buildSummaryCard(
            Icons.qr_code_rounded,
            'UPI Payments',
            '₹${_upiAmount.toStringAsFixed(0)}',
            WOFLTheme.secondary,
          ),
          _buildSummaryCard(
            Icons.payments_rounded,
            'Cash Payments',
            '₹${_cashAmount.toStringAsFixed(0)}',
            WOFLTheme.accent,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth.clamp(180.0, screenWidth),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return WOFLCard(
      padding: const EdgeInsets.symmetric(
        horizontal: WOFLTheme.spacingS,
        vertical: WOFLTheme.spacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: WOFLTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: WOFLTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: WOFLTheme.spacingM),
        _buildSummaryCards(),
        const SizedBox(height: WOFLTheme.spacingM),
        WOFLButton(
          text: 'Refresh Data',
          icon: Icons.refresh_rounded,
          onPressed: _loadOrdersData,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        const SizedBox(height: WOFLTheme.spacingM),
        Expanded(child: _buildOrdersList()),
      ],
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 600;

        if (isCompact) {
          return Column(
            children: [
              // Search bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: WOFLTheme.textLight,
                  ),
                  hintText: 'Search orders, customers, or items...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WOFLTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WOFLTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: WOFLTheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  filled: true,
                  fillColor: WOFLTheme.creamWhite,
                ),
              ),
              const SizedBox(height: WOFLTheme.spacingS),
              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: WOFLButton(
                        text: 'New Order',
                        icon: Icons.add_rounded,
                        onPressed: _showCreateOrderDialog,
                      ),
                    ),
                  ),
                  const SizedBox(width: WOFLTheme.spacingS),
                  Flexible(
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                          _currentPage = 0;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'newest',
                          child: Text('Newest First'),
                        ),
                        const PopupMenuItem(
                          value: 'oldest',
                          child: Text('Oldest First'),
                        ),
                        const PopupMenuItem(
                          value: 'amount_high',
                          child: Text('Highest Amount'),
                        ),
                        const PopupMenuItem(
                          value: 'amount_low',
                          child: Text('Lowest Amount'),
                        ),
                      ],
                      child: WOFLCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WOFLTheme.spacingS,
                          vertical: WOFLTheme.spacingXS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _getSortLabel(),
                                style: TextStyle(
                                  color: WOFLTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: WOFLTheme.textLight,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: WOFLTheme.textLight,
                  ),
                  hintText: 'Search orders, customers, or items...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WOFLTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: WOFLTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: WOFLTheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  filled: true,
                  fillColor: WOFLTheme.creamWhite,
                ),
              ),
            ),
            const SizedBox(width: WOFLTheme.spacingS),
            SizedBox(
              height: 44,
              child: WOFLButton(
                text: 'New Order',
                icon: Icons.add_rounded,
                onPressed: _showCreateOrderDialog,
              ),
            ),
            const SizedBox(width: WOFLTheme.spacingS),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                  _currentPage = 0;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'newest',
                  child: Text('Newest First'),
                ),
                const PopupMenuItem(
                  value: 'oldest',
                  child: Text('Oldest First'),
                ),
                const PopupMenuItem(
                  value: 'amount_high',
                  child: Text('Highest Amount'),
                ),
                const PopupMenuItem(
                  value: 'amount_low',
                  child: Text('Lowest Amount'),
                ),
              ],
              child: WOFLCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: WOFLTheme.spacingM,
                  vertical: WOFLTheme.spacingS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSortLabel(),
                      style: TextStyle(
                        color: WOFLTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: WOFLTheme.spacingS),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: WOFLTheme.textLight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'amount_high':
        return 'Highest Amount';
      case 'amount_low':
        return 'Lowest Amount';
      default:
        return 'Newest First';
    }
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return Center(
        child: WOFLCard(
          child: Padding(
            padding: const EdgeInsets.all(WOFLTheme.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: WOFLTheme.textLight,
                  size: 48,
                ),
                const SizedBox(height: WOFLTheme.spacingM),
                Text(
                  'No orders found',
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: WOFLTheme.spacingS),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try adjusting your search criteria'
                      : 'No orders for the selected date range',
                  style: TextStyle(color: WOFLTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pageCount = (filteredOrders.length / _ordersPerPage).ceil();
    final currentPage = _currentPage.clamp(
      0,
      pageCount > 0 ? pageCount - 1 : 0,
    );
    final pageOrders = filteredOrders
        .skip(currentPage * _ordersPerPage)
        .take(_ordersPerPage)
        .toList();

    if (pageOrders.isEmpty) {
      return Center(
        child: WOFLCard(
          child: Padding(
            padding: const EdgeInsets.all(WOFLTheme.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: WOFLTheme.textLight,
                  size: 48,
                ),
                const SizedBox(height: WOFLTheme.spacingM),
                Text(
                  'No orders found on this page',
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: WOFLTheme.spacingS),
                Text(
                  'Try switching pages or adjusting your filters.',
                  style: TextStyle(color: WOFLTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final maxCardWidth = screenWidth < 500 ? screenWidth : 420.0;
              final childAspectRatio = screenWidth < 600 ? 1.05 : 1.2;

              return GridView.builder(
                padding: const EdgeInsets.only(top: WOFLTheme.spacingS),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCardWidth,
                  crossAxisSpacing: WOFLTheme.spacingS,
                  mainAxisSpacing: WOFLTheme.spacingS,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: pageOrders.length,
                itemBuilder: (context, index) {
                  final order = pageOrders[index];
                  return _buildOrderCard(order);
                },
              );
            },
          ),
        ),
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(
              top: WOFLTheme.spacingS,
              left: WOFLTheme.spacingS,
              right: WOFLTheme.spacingS,
              bottom: WOFLTheme.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Page ${currentPage + 1} of $pageCount',
                      style: TextStyle(
                        color: WOFLTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: WOFLTheme.spacingS),
                    Text(
                      'Showing ${pageOrders.length} of ${filteredOrders.length} orders',
                      style: TextStyle(color: WOFLTheme.textLight),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: currentPage > 0
                          ? () => setState(() => _currentPage = currentPage - 1)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WOFLTheme.primary,
                        side: BorderSide(color: WOFLTheme.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(WOFLTheme.buttonRadius)),
                      ),
                      child: const Text('Previous',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    const SizedBox(width: WOFLTheme.spacingS),
                    OutlinedButton(
                      onPressed: currentPage < pageCount - 1
                          ? () => setState(() => _currentPage = currentPage + 1)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WOFLTheme.primary,
                        side: BorderSide(color: WOFLTheme.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(WOFLTheme.buttonRadius)),
                      ),
                      child: const Text('Next',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _navigateToEditOrderScreen(OrderItem order) async {
    final isPending = order.status.toLowerCase() == 'pending';

    if (!isPending) {
      // Ask the user to unlock the order first
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_open_rounded, color: WOFLTheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text('Unlock Order'),
            ],
          ),
          content: Text(
            'Order ${order.id} is currently "${order.status}".\n\n'
            'To edit it, the status must first be set to Pending. '
            'Do you want to change it to Pending now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WOFLTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Set to Pending'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      final updatedOrder = await _setOrderToPending(order);
      if (updatedOrder == null || !mounted) return;

      // Navigate with the freshly-pending order
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditOrderScreen(order: updatedOrder)),
      );
      if (result == true) _loadOrdersData();
    } else {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditOrderScreen(order: order)),
      );
      if (result == true) _loadOrdersData();
    }
  }

  /// PATCHes the order to Completed=false (Pending) and returns the updated OrderItem.
  /// Returns null on failure.
  Future<OrderItem?> _setOrderToPending(OrderItem order) async {
    final id = int.tryParse(order.id)?.toString() ??
        RegExp(r'\d+').firstMatch(order.id)?.group(0);
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not parse order ID: ${order.id}'),
            backgroundColor: WOFLTheme.error,
          ),
        );
      }
      return null;
    }
    try {
      await BaseApiService.patch('/orders/$id/patch/', {'Completed': false});

      // Rebuild locally — keep everything the same, just flip status
      final updated = OrderItem(
        id: order.id,
        orderNumber: order.orderNumber,
        date: order.date,
        items: order.items,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        status: 'Pending',
        customerName: order.customerName,
      );

      // Update in the live list so the card reflects the change immediately
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${order.displayOrderNumber} set to Pending'),
              ],
            ),
            backgroundColor: WOFLTheme.success,
          ),
        );
      }

      return updated;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: WOFLTheme.error,
          ),
        );
      }
      return null;
    }
  }

  Widget _buildOrderCard(OrderItem order) {
    final isCompleted = order.status.toLowerCase() == 'completed' ||
        order.status.toLowerCase() == 'done';

    return Material(
      color: Colors.transparent,
      // Single tap on completed card opens details dialog
      child: InkWell(
        onDoubleTap: () => _navigateToEditOrderScreen(order),
        onLongPress: () => _navigateToEditOrderScreen(order),
        borderRadius: BorderRadius.circular(WOFLTheme.cardRadius),
        child: WOFLCard(
          padding: const EdgeInsets.all(0),
          child: isCompleted
              ? GestureDetector(
                  onTap: () => _showAllItemsDialog(order),
                  child: _buildCompletedOrderCard(order),
                )
              : _buildPendingOrderCard(order),
        ),
      ),
    );
  }

  // ─── COMPLETED ORDER CARD (Reference Design) ───────────────────────────────

  Widget _buildCompletedOrderCard(OrderItem order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Green header banner ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: WOFLTheme.success.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(WOFLTheme.cardRadius),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: WOFLTheme.success,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'ORDER COMPLETED',
                style: TextStyle(
                  color: WOFLTheme.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // ── Order number + badges ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: order number · date · spacer · DONE · delete
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    order.displayOrderNumber,
                    style: TextStyle(
                      color: WOFLTheme.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatOrderDate(order.date),
                    style: TextStyle(
                      color: WOFLTheme.textLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: WOFLTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DONE',
                      style: TextStyle(
                        color: WOFLTheme.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showDeleteOrderDialog(order),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: WOFLTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.delete_outline, size: 16, color: WOFLTheme.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Row 2: payment badge (truncated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WOFLTheme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: WOFLTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 10, color: WOFLTheme.textLight),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        order.paymentMethod,
                        style: TextStyle(color: WOFLTheme.textLight, fontSize: 10, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Items list ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: order.items.take(3).map((item) {
              final nameMatch = RegExp(r'ProductName[:\s]+([^,}]+)', caseSensitive: false).firstMatch(item);
              final qtyMatch = RegExp(r'Quantity[:\s]+(\d+)', caseSensitive: false).firstMatch(item);
              final priceMatch = RegExp(r'(?:PriceAtPurchase|Price|UnitPrice)[:\s]+([\d.]+)', caseSensitive: false).firstMatch(item);
              final name = nameMatch != null ? nameMatch.group(1)!.trim() : item.replaceAll(RegExp(r'[{}]'), '');
              final qty = int.tryParse(qtyMatch?.group(1) ?? '1') ?? 1;
              final unitPrice = double.tryParse(priceMatch?.group(1) ?? '0') ?? 0.0;
              final lineTotal = (qty * unitPrice).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(color: WOFLTheme.textDark, fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('x$qty  ', style: TextStyle(color: WOFLTheme.textLight, fontSize: 11)),
                    Text('₹$lineTotal', style: TextStyle(color: WOFLTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        if (order.items.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              '+ ${order.items.length - 3} more items · tap to view all',
              style: TextStyle(color: WOFLTheme.primary, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),

        const Spacer(),

        // ── Total Amount row ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: WOFLTheme.background.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(WOFLTheme.cardRadius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: WOFLTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: WOFLTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WOFLTheme.border),
                ),
                child: Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── PENDING ORDER CARD (Compact Design) ─────────────────────────────────

  Widget _buildPendingOrderCard(OrderItem order) {
    return Padding(
      padding: const EdgeInsets.all(WOFLTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header row with order number and menu
          Row(
            children: [
              Expanded(
                child: Text(
                  order.displayOrderNumber,
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditOrderDialog(order);
                  } else if (value == 'delete') {
                    _showDeleteOrderDialog(order);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: WOFLTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text('Edit', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete,
                          size: 12,
                          color: WOFLTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text('Delete', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: WOFLTheme.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: WOFLTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Status and date row
          Row(
            children: [
              WOFLBadge.status(
                order.status,
                icon: Icons.check_circle_rounded,
                isSmall: true,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatOrderDate(order.date),
                  style: TextStyle(
                    color: WOFLTheme.textLight,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items section — show qty × unit price per item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...order.items.take(3).map((item) {
                  final nameMatch = RegExp(r'ProductName:\s*([^,}]+)').firstMatch(item);
                  final qtyMatch = RegExp(r'Quantity:\s*(\d+)').firstMatch(item);
                  final priceMatch = RegExp(r'PriceAtPurchase:\s*([\d.]+)').firstMatch(item);
                  final name = nameMatch?.group(1)?.trim() ?? item;
                  final qty = int.tryParse(qtyMatch?.group(1) ?? '1') ?? 1;
                  final unitPrice = double.tryParse(priceMatch?.group(1) ?? '0') ?? 0.0;
                  final lineTotal = (qty * unitPrice).toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(color: WOFLTheme.textDark, fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${qty}×₹${unitPrice.toStringAsFixed(0)}',
                          style: TextStyle(color: WOFLTheme.textLight, fontSize: 9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹$lineTotal',
                          style: TextStyle(color: WOFLTheme.textDark, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
                if (order.items.length > 3)
                  Text(
                    '+ ${order.items.length - 3} more',
                    style: TextStyle(color: WOFLTheme.textLight, fontSize: 9, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Footer divider + amount
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: WOFLTheme.border.withValues(alpha: 0.4))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: WOFLTheme.textDark, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WOFLTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.paymentMethod.length > 6 ? order.paymentMethod.substring(0, 6) + '..' : order.paymentMethod,
                    style: TextStyle(color: WOFLTheme.primary, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          // Tap hint
          Row(
            children: [
              Icon(
                order.status.toLowerCase() == 'pending' ? Icons.edit_rounded : Icons.lock_rounded,
                size: 10,
                color: order.status.toLowerCase() == 'pending' ? WOFLTheme.primary : WOFLTheme.textLight,
              ),
              const SizedBox(width: 3),
              Text(
                order.status.toLowerCase() == 'pending' ? 'Double-tap to edit' : 'Double-tap to unlock',
                style: TextStyle(
                  fontSize: 9,
                  color: order.status.toLowerCase() == 'pending' ? WOFLTheme.primary : WOFLTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Order Details Dialog ────────────────────────────────────────────────

  void _showAllItemsDialog(OrderItem order) {
    final isCompleted = order.status.toLowerCase() == 'completed' ||
        order.status.toLowerCase() == 'done';
    final accentColor = isCompleted ? WOFLTheme.success : WOFLTheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: WOFLTheme.cardBackground,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.78,
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ${order.displayOrderNumber}',
                                style: TextStyle(
                                  color: WOFLTheme.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${order.items.length} item${order.items.length != 1 ? 's' : ''}  ·  ${_formatOrderDate(order.date)}',
                                style: TextStyle(color: WOFLTheme.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: WOFLTheme.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.close, size: 18, color: WOFLTheme.textLight),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Status + payment chips
                    Row(
                      children: [
                        _chip(
                          icon: isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                          label: isCompleted ? 'Completed' : 'Pending',
                          color: accentColor,
                          bg: accentColor.withValues(alpha: 0.12),
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: order.paymentMethod,
                          color: WOFLTheme.textLight,
                          bg: WOFLTheme.background,
                          border: WOFLTheme.border,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Items list ───────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: order.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final nameMatch = RegExp(r'ProductName[:\s]+([^,}]+)', caseSensitive: false).firstMatch(item);
                      final qtyMatch = RegExp(r'Quantity[:\s]+(\d+)', caseSensitive: false).firstMatch(item);
                      final priceMatch = RegExp(r'(?:PriceAtPurchase|Price|UnitPrice)[:\s]+([\d.]+)', caseSensitive: false).firstMatch(item);
                      final name = nameMatch?.group(1)?.trim() ?? item.replaceAll(RegExp(r'[{}]'), '');
                      final qty = int.tryParse(qtyMatch?.group(1) ?? '1') ?? 1;
                      final unitPrice = double.tryParse(priceMatch?.group(1) ?? '0') ?? 0.0;
                      final lineTotal = qty * unitPrice;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: WOFLTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WOFLTheme.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            // Index badge
                            Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Name + qty × price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(color: WOFLTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$qty × ₹${unitPrice.toStringAsFixed(0)}',
                                    style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // Line total
                            Text(
                              '₹${lineTotal.toStringAsFixed(0)}',
                              style: TextStyle(color: WOFLTheme.textDark, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Footer ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: WOFLTheme.background.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(top: BorderSide(color: WOFLTheme.border.withValues(alpha: 0.4))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(color: WOFLTheme.textDark, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    Color? border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Navigation functions for order management
  void _showCreateOrderDialog() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EditOrderScreen()))
        .then((result) { if (result == true) _loadOrdersData(); });
  }

  void _showEditOrderDialog(OrderItem order) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => EditOrderScreen(order: order)))
        .then((result) { if (result == true) _loadOrdersData(); });
  }

  void _showDeleteOrderDialog(OrderItem order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WOFLTheme.cardRadius),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WOFLTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                color: WOFLTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: WOFLTheme.spacingM),
            Text(
              'Delete Order',
              style: TextStyle(
                color: WOFLTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete order ${order.id}?',
              style: TextStyle(color: WOFLTheme.textDark),
            ),
            const SizedBox(height: WOFLTheme.spacingS),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: WOFLTheme.textLight, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                child: WOFLButton(
                  text: 'Cancel',
                  type: WOFLButtonType.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: WOFLTheme.spacingM),
              SizedBox(
                height: 40,
                child: WOFLButton(
                  text: 'Delete',
                  icon: Icons.delete,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteOrder(order.id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createOrder(Map<String, dynamic> orderData) async {
    try {
      // Extract OrderItems for separate creation
      final orderItems =
          orderData.remove('OrderItems') as List<Map<String, dynamic>>? ?? [];

      // Create the order first
      final response = await BaseApiService.post('/orders/create/', orderData);

      // If order creation successful and we have items, create them
      if (orderItems.isNotEmpty) {
        final orderId = response['ID'];

        // Create each order item
        for (final itemData in orderItems) {
          itemData['OrderId'] = orderId;
          try {
            // Note: We might need to create OrderItems via a different endpoint
            // For now, we'll update the order with items using PUT
            await BaseApiService.put('/orders/$orderId/update/', {
              ...orderData,
              'OrderItems': orderItems,
            });
            break; // Only need to do this once for all items
          } catch (e) {
            // If OrderItems creation fails, continue anyway
            print('Failed to create order items: $e');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Order created successfully'),
              ],
            ),
            backgroundColor: WOFLTheme.success,
          ),
        );
        _loadOrdersData(); // Refresh the orders list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: ${e.toString()}'),
            backgroundColor: WOFLTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _updateOrder(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final id = int.tryParse(orderId)?.toString() ??
          RegExp(r'\d+').firstMatch(orderId)?.group(0);
      if (id == null) throw Exception('Invalid order ID format');

      await BaseApiService.put('/orders/$id/update/', orderData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Order updated successfully'),
              ],
            ),
            backgroundColor: WOFLTheme.success,
          ),
        );
        _loadOrdersData(); // Refresh the orders list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: ${e.toString()}'),
            backgroundColor: WOFLTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      final id = int.tryParse(orderId)?.toString() ??
          RegExp(r'\d+').firstMatch(orderId)?.group(0);
      if (id == null) throw Exception('Invalid order ID format');

      await BaseApiService.delete('/orders/$id/delete/');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Order deleted successfully'),
              ],
            ),
            backgroundColor: WOFLTheme.success,
          ),
        );
        _loadOrdersData(); // Refresh the orders list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete order: ${e.toString()}'),
            backgroundColor: WOFLTheme.error,
          ),
        );
      }
    }
  }
}

// Order Dialog Widget for Create/Edit
class _OrderDialog extends StatefulWidget {
  final String title;
  final OrderItem? order;
  final Function(Map<String, dynamic>) onSave;

  const _OrderDialog({required this.title, required this.onSave, this.order});

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _upiAmountController = TextEditingController();
  final _cashAmountController = TextEditingController();

  String _selectedStatus = 'Completed';
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.order != null) {
      _selectedStatus = widget.order!.status;

      // Parse payment amounts from payment method
      if (widget.order!.paymentMethod.contains('UPI') &&
          widget.order!.paymentMethod.contains('Cash')) {
        // Mixed payment - extract amounts
        final upiMatch = RegExp(
          r'UPI ₹(\d+(?:\.\d+)?)',
        ).firstMatch(widget.order!.paymentMethod);
        final cashMatch = RegExp(
          r'Cash ₹(\d+(?:\.\d+)?)',
        ).firstMatch(widget.order!.paymentMethod);
        _upiAmountController.text = upiMatch?.group(1) ?? '0';
        _cashAmountController.text = cashMatch?.group(1) ?? '0';
      } else if (widget.order!.paymentMethod == 'UPI') {
        _upiAmountController.text = widget.order!.totalAmount.toString();
        _cashAmountController.text = '0';
      } else {
        _upiAmountController.text = '0';
        _cashAmountController.text = widget.order!.totalAmount.toString();
      }

      // We'll populate selected products after products list loads
      _selectedProducts = [];
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await BaseApiService.get('/products/');
      if (response is List) {
        setState(() {
          _products = response.cast<Map<String, dynamic>>();
        });
        // If editing an existing order, try to map its item strings to product objects
        if (widget.order != null && _selectedProducts.isEmpty) {
          _populateSelectedProductsFromOrder();
        }
      }
    } catch (e) {
      // Handle error silently, user can still create orders
    }
  }

  void _populateSelectedProductsFromOrder() {
    final order = widget.order!;
    final List<Map<String, dynamic>> populated = [];

    for (final itemStr in order.items) {
      // Attempt to parse quantity from trailing " (n)" style
      final qtyMatch = RegExp(r"\((\d+)\)\s*").firstMatch(itemStr);
      int qty = 1;
      String name = itemStr;
      if (qtyMatch != null) {
        qty = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
        name = itemStr.replaceAll(RegExp(r"\s*\(\d+\)\s*$"), '').trim();
      }

      final match = _products.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p != null && p['Name']?.toString().trim() == name,
        orElse: () => null,
      );

      if (match != null) {
        populated.add({'product': match, 'quantity': qty});
      }
    }

    if (populated.isNotEmpty) {
      setState(() {
        _selectedProducts = populated;
      });
    }
  }

  @override
  void dispose() {
    _upiAmountController.dispose();
    _cashAmountController.dispose();
    super.dispose();
  }

  void _addProduct() {
    if (_products.isEmpty) return;

    setState(() {
      _selectedProducts.add({'product': _products.first, 'quantity': 1});
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one product'),
          backgroundColor: WOFLTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final upiAmount = double.tryParse(_upiAmountController.text) ?? 0;
    final cashAmount = double.tryParse(_cashAmountController.text) ?? 0;

    // Calculate total quantity
    final totalQuantity = _selectedProducts.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    final orderData = {
      'UpiAmount': upiAmount,
      'CashAmount': cashAmount,
      'TotalQuantity': totalQuantity,
      'Completed': _selectedStatus == 'Completed',
      'ColorId': 1, // Default color
      'EmojiId': 1, // Default emoji
      'OrderItems': _selectedProducts
          .map(
            (item) => {
              'ProductID': item['product']['ID'],
              'Quantity': item['quantity'],
              'PriceAtPurchase': item['product']['Price'],
            },
          )
          .toList(),
    };

    try {
      await widget.onSave(orderData);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error handling is done in the parent
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WOFLTheme.cardRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final isCompact = screenWidth < 600;

          return Container(
            width: isCompact ? screenWidth * 0.95 : 600,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.9,
              maxWidth: screenWidth * 0.95,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(WOFLTheme.spacingL),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: WOFLTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.order == null
                              ? Icons.add_shopping_cart
                              : Icons.edit,
                          color: WOFLTheme.creamWhite,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: WOFLTheme.spacingM),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: WOFLTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: WOFLTheme.textLight),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WOFLTheme.spacingL,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Products Section
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Products',
                                  style: TextStyle(
                                    color: WOFLTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: _products.isEmpty
                                        ? null
                                        : _addProduct,
                                    icon: Icon(Icons.add, size: 16),
                                    label: Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: WOFLTheme.primary,
                                      foregroundColor: WOFLTheme.creamWhite,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: WOFLTheme.spacingM),

                          // Selected Products List
                          if (_selectedProducts.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                WOFLTheme.spacingL,
                              ),
                              decoration: BoxDecoration(
                                color: WOFLTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: WOFLTheme.border),
                              ),
                              child: Center(
                                child: Text(
                                  'No products added yet',
                                  style: TextStyle(
                                    color: WOFLTheme.textLight,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...List.generate(_selectedProducts.length, (index) {
                              final item = _selectedProducts[index];
                              final product =
                                  item['product'] as Map<String, dynamic>;

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: WOFLTheme.spacingM,
                                ),
                                padding: const EdgeInsets.all(
                                  WOFLTheme.spacingM,
                                ),
                                decoration: BoxDecoration(
                                  color: WOFLTheme.creamWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: WOFLTheme.border),
                                ),
                                child: Column(
                                  children: [
                                    // Product dropdown - full width
                                    DropdownButtonFormField<
                                      Map<String, dynamic>
                                    >(
                                      value: product,
                                      decoration: InputDecoration(
                                        labelText: 'Product',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      isExpanded: true,
                                      items: _products.map((prod) {
                                        return DropdownMenuItem(
                                          value: prod,
                                          child: Text(
                                            '${prod['Name']} - ₹${prod['Price']}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedProducts[index]['product'] =
                                              value!;
                                        });
                                      },
                                    ),
                                    const SizedBox(
                                      height: WOFLTheme.spacingM,
                                    ),

                                    // Quantity and delete row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item['quantity']
                                                .toString(),
                                            decoration: InputDecoration(
                                              labelText: 'Quantity',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              final qty =
                                                  int.tryParse(value) ?? 1;
                                              setState(() {
                                                _selectedProducts[index]['quantity'] =
                                                    qty;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: WOFLTheme.spacingM,
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _removeProduct(index),
                                          icon: Icon(
                                            Icons.delete,
                                            color: WOFLTheme.error,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: WOFLTheme.error
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: WOFLTheme.spacingL),

                          // Payment amounts
                          if (isCompact)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _upiAmountController,
                                  decoration: InputDecoration(
                                    labelText: 'UPI Amount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.qr_code,
                                      color: WOFLTheme.primary,
                                    ),
                                    prefixText: '₹',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final amount = double.tryParse(value ?? '');
                                    if (amount == null || amount < 0) {
                                      return 'Invalid amount';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: WOFLTheme.spacingM),
                                TextFormField(
                                  controller: _cashAmountController,
                                  decoration: InputDecoration(
                                    labelText: 'Cash Amount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.payments,
                                      color: WOFLTheme.primary,
                                    ),
                                    prefixText: '₹',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final amount = double.tryParse(value ?? '');
                                    if (amount == null || amount < 0) {
                                      return 'Invalid amount';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _upiAmountController,
                                    decoration: InputDecoration(
                                      labelText: 'UPI Amount',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.qr_code,
                                        color: WOFLTheme.primary,
                                      ),
                                      prefixText: '₹',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      final amount = double.tryParse(
                                        value ?? '',
                                      );
                                      if (amount == null || amount < 0) {
                                        return 'Invalid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: WOFLTheme.spacingM),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cashAmountController,
                                    decoration: InputDecoration(
                                      labelText: 'Cash Amount',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.payments,
                                        color: WOFLTheme.primary,
                                      ),
                                      prefixText: '₹',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      final amount = double.tryParse(
                                        value ?? '',
                                      );
                                      if (amount == null || amount < 0) {
                                        return 'Invalid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: WOFLTheme.spacingL),

                          // Status
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.check_circle,
                                color: WOFLTheme.primary,
                              ),
                            ),
                            isExpanded: true,
                            items: ['Completed', 'Pending'].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                          const SizedBox(height: WOFLTheme.spacingL),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(WOFLTheme.spacingL),
                  child: isCompact
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WOFLTheme.primary,
                                  foregroundColor: WOFLTheme.creamWhite,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                WOFLTheme.creamWhite,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Save Order'),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: WOFLTheme.spacingM),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: WOFLTheme.textDark,
                                  side: BorderSide(color: WOFLTheme.border),
                                ),
                                child: Text('Cancel'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: WOFLTheme.textDark,
                                    side: BorderSide(color: WOFLTheme.border),
                                  ),
                                  child: Text('Cancel'),
                                ),
                              ),
                            ),
                            const SizedBox(width: WOFLTheme.spacingM),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveOrder,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WOFLTheme.primary,
                                    foregroundColor: WOFLTheme.creamWhite,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  WOFLTheme.creamWhite,
                                                ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, size: 20),
                                            const SizedBox(width: 8),
                                            Text('Save Order'),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Order Item Model
class OrderItem {
  final String id;
  final String? orderNumber;
  final DateTime date;
  final List<String> items;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String customerName;

  OrderItem({
    required this.id,
    this.orderNumber,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.customerName,
  });

  /// Returns the display order number (e.g., "#1", "#2", "#3")
  String get displayOrderNumber {
    if (orderNumber != null && orderNumber!.trim().isNotEmpty) {
      final clean = orderNumber!.trim();
      return clean.startsWith('#') ? clean : '#$clean';
    }
    // Fallback: use the raw id
    final numericMatch = RegExp(r'(\d+)', caseSensitive: false).firstMatch(id);
    if (numericMatch != null) {
      return '#${numericMatch.group(1)}';
    }
    return '#$id';
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ??
          json['OrderNumber']?.toString() ??
          json['orderNumber']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  final pid   = e['ProductID'] ?? e['productID'] ?? '';
                  final name  = e['ProductName'] ?? e['productName'] ?? '';
                  final qty   = e['Quantity'] ?? e['quantity'] ?? 1;
                  final price = e['Price'] ?? e['PriceAtPurchase'] ?? e['price'] ?? 0;
                  return 'ProductID: $pid, ProductName: $name, Quantity: $qty, PriceAtPurchase: $price';
                }
                return e.toString();
              })
              .toList() ??
          [],
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'Cash',
      status: json['status']?.toString() ?? 'Completed',
      customerName: json['customer_name']?.toString() ?? 'Guest',
    );
  }
}

// ─── Compact Date Range Popup ──────────────────────────────────────────────

class _CompactDateRangeDialog extends StatefulWidget {
  final DateTimeRange? initial;

  const _CompactDateRangeDialog({this.initial});

  @override
  State<_CompactDateRangeDialog> createState() =>
      _CompactDateRangeDialogState();
}

class _CompactDateRangeDialogState extends State<_CompactDateRangeDialog> {
  late DateTime _viewMonth;
  DateTime? _start;
  DateTime? _end;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.start;
    _end = widget.initial?.end;
    _viewMonth = DateTime(
      (_start ?? DateTime.now()).year,
      (_start ?? DateTime.now()).month,
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_shortMonths[d.month - 1]} ${d.year}';

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
      }
    });
  }

  void _applyShortcut(DateTime start, DateTime end) {
    setState(() {
      _start = start;
      _end = end;
      _viewMonth = DateTime(start.year, start.month);
    });
  }

  void _prevMonth() => setState(() =>
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));

  void _nextMonth() => setState(() =>
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  bool _inRange(DateTime d) {
    if (_start == null || _end == null) return false;
    return d.isAfter(_start!.subtract(const Duration(days: 1))) &&
        d.isBefore(_end!.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build calendar days
    final firstOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    // Monday = 0 offset
    int startWeekday = firstOfMonth.weekday - 1; // Mon=0

    final calRows = <List<DateTime?>>[];
    List<DateTime?> row = List.filled(7, null);
    int col = startWeekday;
    for (int d = 1; d <= daysInMonth; d++) {
      row[col] = DateTime(_viewMonth.year, _viewMonth.month, d);
      col++;
      if (col == 7) {
        calRows.add(row);
        row = List.filled(7, null);
        col = 0;
      }
    }
    if (col > 0) calRows.add(row);

    final primaryColor = WOFLTheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                    // ── Selected range display ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _start == null
                                ? 'Select start date'
                                : _end == null
                                    ? '${_fmt(_start!)} – End date'
                                    : '${_fmt(_start!)} – ${_fmt(_end!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _start == null
                                  ? Colors.grey
                                  : WOFLTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Shortcuts ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _shortcut('Last week', () {
                            final mon = today
                                .subtract(Duration(days: today.weekday - 1 + 7));
                            _applyShortcut(mon,
                                mon.add(const Duration(days: 6)));
                          }),
                          const SizedBox(width: 8),
                          _shortcut('Last month', () {
                            final first = DateTime(now.year, now.month - 1, 1);
                            final last =
                                DateTime(now.year, now.month, 0);
                            _applyShortcut(first, last);
                          }),
                          const SizedBox(width: 8),
                          _shortcut('Last year', () {
                            _applyShortcut(
                              DateTime(now.year - 1, 1, 1),
                              DateTime(now.year - 1, 12, 31),
                            );
                          }),
                        ],
                      ),
                    ),

                    // ── Month nav ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 18),
                            onPressed: _prevMonth,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Expanded(
                            child: Text(
                              '${_months[_viewMonth.month - 1]} ${_viewMonth.year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 18),
                            onPressed: _nextMonth,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // ── Day-of-week headers ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: const ['Mo','Tu','We','Th','Fr','Sa','Su']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── Calendar grid ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: calRows.map((week) {
                          return Row(
                            children: week.map((day) {
                              if (day == null) {
                                return const Expanded(child: SizedBox(height: 36));
                              }
                              final isStart = _start != null &&
                                  day.isAtSameMomentAs(_start!);
                              final isEnd =
                                  _end != null && day.isAtSameMomentAs(_end!);
                              final inRange = _inRange(day);
                              final isToday = day.isAtSameMomentAs(today);
                              final isFuture = day.isAfter(today);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: isFuture ? null : () => _onDayTap(day),
                                  child: Container(
                                    height: 36,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isStart || isEnd)
                                          ? primaryColor
                                          : inRange
                                              ? primaryColor
                                                    .withValues(alpha: 0.12)
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: (isStart || isEnd)
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: (isStart || isEnd)
                                              ? Colors.white
                                              : isFuture
                                                  ? Colors.grey.shade300
                                                  : isToday
                                                      ? primaryColor
                                                      : WOFLTheme.textDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Cancel / Apply ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: WOFLTheme.textDark,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_start != null && _end != null)
                                  ? () => Navigator.of(context).pop(
                                        DateTimeRange(
                                            start: _start!, end: _end!),
                                      )
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Apply'),
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

  Widget _shortcut(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: WOFLTheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: WOFLTheme.primary,
        ),
      ),
    );
  }
}
