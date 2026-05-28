import 'package:flutter/material.dart';
import '../services/base_api_service.dart';
import '../theme/waffle_theme.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedRange = 'today';
  bool _isLoading = true;
  String? _errorMessage;
  bool _isConnectedToBackend = false; // Track backend connection status

  double _totalRevenue = 0;
  int _orderCount = 0;
  double _upiAmount = 0;
  double _cashAmount = 0;
  List<_TrendPoint> _trendPoints = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the existing orders API endpoint instead of dashboard
      final response = await BaseApiService.get('/orders/?date=$_selectedRange');

      if (response is Map<String, dynamic>) {
        final summary = response['summary'] as Map<String, dynamic>? ?? {};
        final analytics = response['analytics'] as List<dynamic>? ?? [];

        final revenue = _toDouble(summary['total_amount']);
        final upi = _toDouble(summary['total_upi']);
        final cash = _toDouble(summary['total_cash']);
        final orders = _toInt(summary['orders_count']);

        final trend = analytics
            .map((item) {
              if (item is! Map<String, dynamic>) return null;
              final total = _toDouble(item['total_upi']) + _toDouble(item['total_cash']);
              final label = _formatTrendLabel(item['period']);
              return _TrendPoint(label, total);
            })
            .whereType<_TrendPoint>()
            .toList();

        if (!mounted) return;

        setState(() {
          _totalRevenue = revenue;
          _upiAmount = upi;
          _cashAmount = cash;
          _orderCount = orders;
          _trendPoints = trend;
          _isLoading = false;
          _isConnectedToBackend = true; // Mark as connected
        });

        // Show success message briefly
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Dashboard connected to backend - Live data loaded'),
                ],
              ),
              backgroundColor: WaffleTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw ApiException('Invalid response format from orders API');
      }
    } catch (e) {
      // If orders API fails, use mock data for demo
      if (!mounted) return;
      
      setState(() {
        _totalRevenue = 2450.0;
        _upiAmount = 1680.0;
        _cashAmount = 770.0;
        _orderCount = 12;
        _trendPoints = _generateMockTrend();
        _isLoading = false;
        _errorMessage = null; // Don't show error, use mock data
        _isConnectedToBackend = false; // Mark as not connected
      });

      // Show fallback message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Backend unavailable - showing demo data'),
              ],
            ),
            backgroundColor: WaffleTheme.accent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  List<_TrendPoint> _generateMockTrend() {
    switch (_selectedRange) {
      case 'today':
        return [
          const _TrendPoint('9 AM', 120),
          const _TrendPoint('10 AM', 280),
          const _TrendPoint('11 AM', 450),
          const _TrendPoint('12 PM', 680),
          const _TrendPoint('1 PM', 520),
          const _TrendPoint('2 PM', 400),
        ];
      case 'this_week':
        return [
          const _TrendPoint('Mon', 1200),
          const _TrendPoint('Tue', 1450),
          const _TrendPoint('Wed', 1680),
          const _TrendPoint('Thu', 2100),
          const _TrendPoint('Fri', 2450),
          const _TrendPoint('Sat', 1890),
          const _TrendPoint('Sun', 1560),
        ];
      default:
        return [
          const _TrendPoint('Week 1', 8500),
          const _TrendPoint('Week 2', 9200),
          const _TrendPoint('Week 3', 10100),
          const _TrendPoint('Week 4', 11200),
        ];
    }
  }

  void _changeRange(String range) {
    if (_selectedRange == range) return;

    setState(() {
      _selectedRange = range;
    });

    _loadDashboardData();
  }

  String _rangeTitle() {
    switch (_selectedRange) {
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'this_year':
        return 'This Year';
      case 'today':
      default:
        return 'Today';
    }
  }

  String _rangeDateLabel() {
    final now = DateTime.now();
    final day = now.day;
    final month = _monthName(now.month);
    return '$day $month ${now.year}';
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  String _formatTrendLabel(dynamic period) {
    final raw = period?.toString() ?? '';
    if (raw.isEmpty) return 'No data';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    if (local.hour == 0 && local.minute == 0 && local.second == 0) {
      return '${local.day} ${_monthName(local.month)}';
    }
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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

  double _averageOrderValue() {
    if (_orderCount == 0) return 0;
    return _totalRevenue / _orderCount;
  }

  String _popularPaymentLabel() {
    if (_upiAmount >= _cashAmount) return 'UPI';
    return 'Cash';
  }

  String _bestPerformingTime() {
    if (_trendPoints.isEmpty) return 'No data yet';
    _trendPoints.sort((a, b) => b.value.compareTo(a.value));
    return _trendPoints.first.label;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaffleTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: WaffleTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(WaffleTheme.primary),
                ),
              )
            : _errorMessage != null
            ? _buildErrorState(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(WaffleTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: WaffleTheme.spacingXL),
                    _buildKpiRow(),
                    const SizedBox(height: WaffleTheme.spacingXL),
                    _buildMainGrid(context),
                    const SizedBox(height: WaffleTheme.spacingXL),
                    _buildBottomGrid(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: WaffleCard(
        padding: const EdgeInsets.all(WaffleTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: WaffleTheme.error, size: 48),
            const SizedBox(height: WaffleTheme.spacingM),
            Text(
              'Unable to load dashboard data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: WaffleTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WaffleTheme.spacingS),
            Text(
              _errorMessage ?? 'Something went wrong while fetching the dashboard.',
              style: TextStyle(color: WaffleTheme.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WaffleTheme.spacingL),
            WaffleButton(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: _loadDashboardData,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return WaffleCard(
      padding: const EdgeInsets.all(WaffleTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: WaffleTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Connection status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WaffleTheme.spacingS,
                            vertical: WaffleTheme.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: _isConnectedToBackend 
                                ? WaffleTheme.success.withValues(alpha: 0.1)
                                : WaffleTheme.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isConnectedToBackend 
                                  ? WaffleTheme.success
                                  : WaffleTheme.accent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isConnectedToBackend 
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_off_rounded,
                                color: _isConnectedToBackend 
                                    ? WaffleTheme.success
                                    : WaffleTheme.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isConnectedToBackend ? 'Live' : 'Demo',
                                style: TextStyle(
                                  color: _isConnectedToBackend 
                                      ? WaffleTheme.success
                                      : WaffleTheme.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WaffleTheme.spacingS),
                    Text(
                      _isConnectedToBackend 
                          ? 'Real-time data from Django backend'
                          : 'Demo data - backend unavailable',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: WaffleTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WaffleTheme.spacingL),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WaffleTheme.spacingL,
                  vertical: WaffleTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  color: WaffleTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(WaffleTheme.buttonRadius),
                  border: Border.all(
                    color: WaffleTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: WaffleTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: WaffleTheme.spacingS),
                    Text(
                      '${_rangeTitle()} • ${_rangeDateLabel()}',
                      style: TextStyle(
                        color: WaffleTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WaffleTheme.spacingL),
          Wrap(
            spacing: WaffleTheme.spacingM,
            runSpacing: WaffleTheme.spacingS,
            children: [
              _buildFilterChip('Today', 'today'),
              _buildFilterChip('Week', 'this_week'),
              _buildFilterChip('Month', 'this_month'),
              _buildFilterChip('Year', 'this_year'),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChip(String label, String backendValue) {
    final isActive = _selectedRange == backendValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changeRange(backendValue),
        borderRadius: BorderRadius.circular(WaffleTheme.badgeRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WaffleTheme.spacingL,
            vertical: WaffleTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isActive ? WaffleTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(WaffleTheme.badgeRadius),
            border: Border.all(
              color: isActive ? WaffleTheme.primary : WaffleTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : WaffleTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;
        
        if (screenWidth < 600) {
          crossAxisCount = 1;
          childAspectRatio = 3.5;
        } else if (screenWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 2.2;
        } else if (screenWidth < 1200) {
          crossAxisCount = 3;
          childAspectRatio = 1.8;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.6;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: WaffleTheme.spacingM,
          crossAxisSpacing: WaffleTheme.spacingM,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Total Revenue',
              '₹${_totalRevenue.toStringAsFixed(0)}',
              _isConnectedToBackend ? 'Live' : 'Demo',
              Icons.currency_rupee,
              WaffleTheme.primary,
            ),
            _buildStatCard(
              'Orders',
              '$_orderCount',
              _isConnectedToBackend ? 'Live' : 'Demo',
              Icons.receipt_long,
              WaffleTheme.secondary,
            ),
            _buildStatCard(
              'Avg. Order Value',
              '₹${_averageOrderValue().toStringAsFixed(0)}',
              _isConnectedToBackend ? 'Live' : 'Demo',
              Icons.shopping_bag,
              WaffleTheme.accent,
            ),
            _buildStatCard(
              'Low Stock Items',
              '12',
              'Needs attention',
              Icons.inventory_2,
              WaffleTheme.error,
            ),
          ],
        );
      },
    );
  }
  Widget _buildStatCard(
    String title,
    String value,
    String badge,
    IconData icon,
    Color accentColor,
  ) {
    return WaffleCard(
      child: Padding(
        padding: const EdgeInsets.all(WaffleTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                ),
                const SizedBox(width: WaffleTheme.spacingS),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: WaffleTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(WaffleTheme.badgeRadius),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: WaffleTheme.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WaffleTheme.spacingS),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: WaffleTheme.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: WaffleTheme.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
  Widget _buildMainGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 900;
        
        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isCompact ? 1 : 2,
                  mainAxisSpacing: WaffleTheme.spacingM,
                  crossAxisSpacing: WaffleTheme.spacingM,
                  childAspectRatio: isCompact ? 1.4 : 1.0,
                  children: [
                    _buildRevenueTrendCard(context),
                    _buildPaymentSplitCard(context),
                  ],
                );
              },
            ),
            const SizedBox(height: WaffleTheme.spacingL),
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isCompact ? 1 : 2,
                  mainAxisSpacing: WaffleTheme.spacingM,
                  crossAxisSpacing: WaffleTheme.spacingM,
                  childAspectRatio: isCompact ? 1.6 : 1.1,
                  children: [
                    _buildOrdersSummaryCard(context),
                    _buildStockHealthCard(context),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildRevenueTrendCard(BuildContext context) {
    final maxValue = _trendPoints.isEmpty
        ? 1.0
        : _trendPoints
              .map((point) => point.value)
              .reduce((a, b) => a > b ? a : b);

    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Revenue Trend',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: WaffleTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WaffleTheme.spacingM,
                  vertical: WaffleTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: WaffleTheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(WaffleTheme.badgeRadius),
                ),
                child: Text(
                  'B2C only',
                  style: TextStyle(
                    color: WaffleTheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Sales performance for ${_rangeTitle().toLowerCase()}.',
            style: TextStyle(color: WaffleTheme.textLight),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          if (_trendPoints.isEmpty)
            SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No analytics available for this range.',
                  style: TextStyle(color: WaffleTheme.textLight),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_trendPoints.length, (index) {
                  final point = _trendPoints[index];
                  final normalizedValue = point.value == 0
                      ? 0
                      : (point.value / maxValue) * 160;
                  final isPeak = point.value == maxValue;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '₹${point.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: WaffleTheme.textLight,
                              fontWeight: isPeak
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: WaffleTheme.spacingS),
                          Flexible(
                            child: Container(
                              height: normalizedValue + 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isPeak
                                      ? [
                                          WaffleTheme.primary,
                                          WaffleTheme.secondary,
                                        ]
                                      : [
                                          WaffleTheme.secondary,
                                          WaffleTheme.primary,
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: WaffleTheme.spacingS),
                          Text(
                            point.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: WaffleTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildPaymentSplitCard(BuildContext context) {
    final total = _totalRevenue;
    final upiPercent = total == 0 ? 0 : (_upiAmount / total) * 100;
    final cashPercent = total == 0 ? 0 : (_cashAmount / total) * 100;

    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Mix',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: WaffleTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Track how customers are paying across your selected range.',
            style: TextStyle(color: WaffleTheme.textLight),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  center: Alignment.center,
                  colors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF22C55E),
                    const Color(0xFF3B82F6),
                  ],
                  stops: [0.0, upiPercent / 100, 1.0],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'UPI ${upiPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: WaffleTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: WaffleTheme.spacingXS),
                      Text(
                        'Cash ${cashPercent.toStringAsFixed(0)}%',
                        style: TextStyle(color: WaffleTheme.textLight),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          _buildLegendRow(
            color: const Color(0xFF3B82F6),
            label: 'UPI',
            value: '₹${_upiAmount.toStringAsFixed(0)}',
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          _buildLegendRow(
            color: const Color(0xFF22C55E),
            label: 'Cash',
            value: '₹${_cashAmount.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: WaffleTheme.spacingS),
        Text(
          label,
          style: TextStyle(
            color: WaffleTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: WaffleTheme.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _buildOrdersSummaryCard(BuildContext context) {
    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Snapshot',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: WaffleTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Live update for ${_rangeTitle().toLowerCase()}.',
            style: TextStyle(color: WaffleTheme.textLight),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          _buildSummaryMetric('Completed Orders', '$_orderCount'),
          const SizedBox(height: WaffleTheme.spacingM),
          _buildSummaryMetric(
            'UPI Revenue',
            '₹${_upiAmount.toStringAsFixed(0)}',
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          _buildSummaryMetric(
            'Cash Revenue',
            '₹${_cashAmount.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(WaffleTheme.spacingM),
      decoration: BoxDecoration(
        color: WaffleTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStockHealthCard(BuildContext context) {
    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Health',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: WaffleTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Quick view of inventory status for fast restocking decisions.',
            style: TextStyle(color: WaffleTheme.textLight),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          Row(
            children: [
              Expanded(
                child: _buildStockCard(
                  'In Stock',
                  '184',
                  WaffleTheme.success,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: WaffleTheme.spacingM),
              Expanded(
                child: _buildStockCard(
                  'Low Stock',
                  '12',
                  WaffleTheme.warning,
                  Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: WaffleTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStockCard(
                  'Out of Stock',
                  '3',
                  WaffleTheme.error,
                  Icons.remove_circle_outline,
                ),
              ),
              const SizedBox(width: WaffleTheme.spacingM),
              Expanded(
                child: WaffleCard(
                  enableHover: false,
                  padding: const EdgeInsets.all(WaffleTheme.spacingL),
                  customColor: WaffleTheme.cardBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: WaffleTheme.primary,
                        size: 26,
                      ),
                      const SizedBox(height: WaffleTheme.spacingS),
                      Text(
                        'All healthy',
                        style: TextStyle(
                          color: WaffleTheme.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: WaffleTheme.spacingXS),
                      Text(
                        'No critical stock issues pending.',
                        style: TextStyle(
                          color: WaffleTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return WaffleCard(
      enableHover: false,
      padding: const EdgeInsets.all(WaffleTheme.spacingL),
      customColor: WaffleTheme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            value,
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingXS),
          Text(
            title,
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBottomGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: WaffleTheme.spacingL,
      crossAxisSpacing: WaffleTheme.spacingL,
      childAspectRatio: 1.65,
      children: [
        _buildQuickActionsCard(context),
        _buildHighlightsCard(context),
      ],
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: WaffleTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'Jump into your core operations.',
            style: TextStyle(color: WaffleTheme.textLight),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          Wrap(
            spacing: WaffleTheme.spacingM,
            runSpacing: WaffleTheme.spacingM,
            children: [
              WaffleButton(
                text: 'View Products',
                icon: Icons.restaurant_menu,
                onPressed: () {
                  // Navigate to products page
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
              WaffleButton(
                text: 'View Orders',
                icon: Icons.receipt_long,
                type: WaffleButtonType.outline,
                onPressed: () {
                  // Navigate to orders page
                  DefaultTabController.of(context).animateTo(2);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard(BuildContext context) {
    return WaffleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today at a Glance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: WaffleTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: WaffleTheme.spacingS),
          Text(
            'A compact summary of how the store is performing right now.',
            style: TextStyle(color: WaffleTheme.textLight),
          ),
          const SizedBox(height: WaffleTheme.spacingXL),
          _buildGlanceItem('Best performing time', _bestPerformingTime()),
          const SizedBox(height: WaffleTheme.spacingM),
          _buildGlanceItem('Popular payment', _popularPaymentLabel()),
          const SizedBox(height: WaffleTheme.spacingM),
          _buildGlanceItem('Selected range', _rangeTitle()),
        ],
      ),
    );
  }

  Widget _buildGlanceItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(WaffleTheme.spacingM),
      decoration: BoxDecoration(
        color: WaffleTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: WaffleTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: WaffleTheme.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final String label;
  final double value;

  const _TrendPoint(this.label, this.value);
}