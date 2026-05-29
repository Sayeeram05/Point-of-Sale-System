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
  bool _isConnectedToBackend = false;

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
      final response = await BaseApiService.get(
        '/orders/?date=$_selectedRange',
      );

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
              final total =
                  _toDouble(item['total_upi']) + _toDouble(item['total_cash']);
              return _TrendPoint(_formatTrendLabel(item['period']), total);
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
          _isConnectedToBackend = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Live data loaded'),
                ],
              ),
              backgroundColor: WaffleTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw ApiException('Invalid response format');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _totalRevenue = 2450.0;
        _upiAmount = 1680.0;
        _cashAmount = 770.0;
        _orderCount = 12;
        _trendPoints = _generateMockTrend();
        _isLoading = false;
        _isConnectedToBackend = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text('Backend unavailable – showing demo data'),
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
          const _TrendPoint('Wk 1', 8500),
          const _TrendPoint('Wk 2', 9200),
          const _TrendPoint('Wk 3', 10100),
          const _TrendPoint('Wk 4', 11200),
        ];
    }
  }

  void _changeRange(String range) {
    if (_selectedRange == range) return;
    setState(() => _selectedRange = range);
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
      default:
        return 'Today';
    }
  }

  String _rangeDateLabel() {
    final now = DateTime.now();
    return '${now.day} ${_monthName(now.month)} ${now.year}';
  }

  String _monthName(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _formatTrendLabel(dynamic period) {
    final raw = period?.toString() ?? '';
    if (raw.isEmpty) return '–';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    if (local.hour == 0 && local.minute == 0 && local.second == 0) {
      return '${local.day} ${_monthName(local.month)}';
    }
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _avgOrderValue() => _orderCount == 0 ? 0 : _totalRevenue / _orderCount;

  // ─── BUILD ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaffleTheme.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(WaffleTheme.primary),
              ),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  _buildKpiGrid(),
                  const SizedBox(height: 10),
                  _buildMiddleRow(),
                  const SizedBox(height: 10),
                  _buildInsightRow(),
                ],
              ),
            ),
    );
  }

  // ─── Error ─────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: WaffleCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: WaffleTheme.error,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load dashboard',
                style: TextStyle(
                  color: WaffleTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Something went wrong.',
                style: TextStyle(color: WaffleTheme.textLight, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              WaffleButton(
                text: 'Retry',
                icon: Icons.refresh,
                onPressed: _loadDashboardData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────

  Widget _buildHeader() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: WaffleTheme.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_rangeTitle()} · ${_rangeDateLabel()}',
                      style: TextStyle(
                        color: WaffleTheme.textLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _filterChip('Today', 'today'),
              _filterChip('Week', 'this_week'),
              _filterChip('Month', 'this_month'),
              _filterChip('Year', 'this_year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final isLive = _isConnectedToBackend;
    final color = isLive ? WaffleTheme.success : WaffleTheme.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? 'Live' : 'Demo',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _selectedRange == value;
    return GestureDetector(
      onTap: () => _changeRange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? WaffleTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? WaffleTheme.primary : WaffleTheme.border,
            width: active ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : WaffleTheme.textLight,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── KPI Grid ──────────────────────────────────────────

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const gap = 10.0;

        final cards = [
          _kpiCard(
            title: 'Total revenue',
            value: '₹${_totalRevenue.toStringAsFixed(0)}',
            badge: _isConnectedToBackend ? '↑ Live' : 'Demo',
            icon: Icons.currency_rupee_rounded,
            iconBg: WaffleTheme.primary.withValues(alpha: 0.10),
            iconColor: WaffleTheme.primary,
            badgeBg: WaffleTheme.primary.withValues(alpha: 0.08),
            badgeColor: WaffleTheme.primary,
          ),
          _kpiCard(
            title: 'Orders',
            value: '$_orderCount',
            badge: _isConnectedToBackend ? '↑ Live' : 'Demo',
            icon: Icons.receipt_long_rounded,
            iconBg: WaffleTheme.secondary.withValues(alpha: 0.12),
            iconColor: WaffleTheme.secondary,
            badgeBg: WaffleTheme.secondary.withValues(alpha: 0.08),
            badgeColor: WaffleTheme.secondary,
          ),
          _kpiCard(
            title: 'Avg. order',
            value: '₹${_avgOrderValue().toStringAsFixed(0)}',
            badge: 'Avg',
            icon: Icons.shopping_bag_rounded,
            iconBg: WaffleTheme.accent.withValues(alpha: 0.10),
            iconColor: WaffleTheme.accent,
            badgeBg: WaffleTheme.accent.withValues(alpha: 0.08),
            badgeColor: WaffleTheme.accent,
          ),
        ];

        // 3 cards: always a single row on wide screens, stack on mobile
        if (width >= 500) {
          final cardWidth = (width - gap * 2) / 3;
          return Row(
            children: cards
                .asMap()
                .entries
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (e.key > 0) const SizedBox(width: gap),
                      SizedBox(width: cardWidth, height: 116, child: e.value),
                    ],
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: cards
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: gap),
                  child: SizedBox(height: 116, width: width, child: c),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String badge,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Value
          Text(
            value,
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Label
          Text(
            title,
            style: TextStyle(color: WaffleTheme.textLight, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Middle Row (Trend + Payment side by side) ─────────

  Widget _buildMiddleRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildTrendCard()),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _buildPaymentCard()),
            ],
          );
        }
        return Column(
          children: [
            _buildTrendCard(),
            const SizedBox(height: 10),
            _buildPaymentCard(),
          ],
        );
      },
    );
  }

  // ─── Trend Card ────────────────────────────────────────

  Widget _buildTrendCard() {
    final pts = _trendPoints;
    final maxVal = pts.isEmpty
        ? 1.0
        : pts.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final peakIndex = pts.isEmpty
        ? -1
        : pts.indexWhere((p) => p.value == maxVal);

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue trend',
                      style: TextStyle(
                        color: WaffleTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sales for ${_rangeTitle().toLowerCase()}',
                      style: TextStyle(
                        color: WaffleTheme.textLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WaffleTheme.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'B2C only',
                  style: TextStyle(
                    color: WaffleTheme.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pts.isEmpty)
            SizedBox(
              height: 130,
              child: Center(
                child: Text(
                  'No data available.',
                  style: TextStyle(color: WaffleTheme.textLight, fontSize: 12),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const chartHeight = 130.0;
                const labelHeight = 28.0; // value label + x label
                const gridLines = 3;
                final barAreaHeight = chartHeight - labelHeight;

                return SizedBox(
                  height: chartHeight + labelHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Y-axis gridline labels
                      SizedBox(
                        width: 36,
                        height: chartHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(gridLines + 1, (i) {
                            final val = maxVal * (gridLines - i) / gridLines;
                            return Text(
                              val >= 1000
                                  ? '₹${(val / 1000).toStringAsFixed(1)}k'
                                  : '₹${val.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: WaffleTheme.textLight,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Chart area
                      Expanded(
                        child: Stack(
                          children: [
                            // Horizontal grid lines
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(gridLines + 1, (i) {
                                  return Container(
                                    height: 0.5,
                                    color: WaffleTheme.border.withValues(
                                      alpha: 0.4,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            // Bars + labels
                            Positioned.fill(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: pts.asMap().entries.map((e) {
                                        final i = e.key;
                                        final pt = e.value;
                                        final isPeak = i == peakIndex;
                                        final fraction = pt.value == 0
                                            ? 0.03
                                            : (pt.value / maxVal);
                                        final barH = fraction * barAreaHeight;

                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                // Value label above bar
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  margin: const EdgeInsets.only(
                                                    bottom: 4,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: isPeak
                                                      ? BoxDecoration(
                                                          color: WaffleTheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.10,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        )
                                                      : null,
                                                  child: Text(
                                                    pt.value >= 1000
                                                        ? '${(pt.value / 1000).toStringAsFixed(1)}k'
                                                        : '${pt.value.toStringAsFixed(0)}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: isPeak
                                                          ? FontWeight.w500
                                                          : FontWeight.w400,
                                                      color: isPeak
                                                          ? WaffleTheme.primary
                                                          : WaffleTheme
                                                                .textLight,
                                                    ),
                                                  ),
                                                ),
                                                // Bar
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 400,
                                                  ),
                                                  height: barH,
                                                  decoration: BoxDecoration(
                                                    color: isPeak
                                                        ? WaffleTheme.primary
                                                        : WaffleTheme.primary
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            5,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  // X-axis labels
                                  const SizedBox(height: 6),
                                  Row(
                                    children: pts.asMap().entries.map((e) {
                                      final isPeak = e.key == peakIndex;
                                      return Expanded(
                                        child: Text(
                                          e.value.label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isPeak
                                                ? WaffleTheme.primary
                                                : WaffleTheme.textLight,
                                            fontWeight: isPeak
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }).toList(),
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
              },
            ),
        ],
      ),
    );
  }

  // ─── Payment Card ──────────────────────────────────────

  Widget _buildPaymentCard() {
    final total = _totalRevenue;
    final upiPct = total == 0 ? 0.0 : _upiAmount / total;
    final cashPct = 1 - upiPct;

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment mix',
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'How customers are paying',
            style: TextStyle(color: WaffleTheme.textLight, fontSize: 11),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(90, 90),
                    painter: _DonutPainter(
                      upiFraction: upiPct,
                      primaryColor: WaffleTheme.primary,
                      secondaryColor: WaffleTheme.secondary,
                      bgColor: WaffleTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(upiPct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: WaffleTheme.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'UPI',
                          style: TextStyle(
                            color: WaffleTheme.textLight,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _legendRow(
            color: WaffleTheme.primary,
            label: 'UPI',
            value: '₹${_upiAmount.toStringAsFixed(0)}',
            fraction: upiPct,
          ),
          const SizedBox(height: 12),
          _legendRow(
            color: WaffleTheme.secondary,
            label: 'Cash',
            value: '₹${_cashAmount.toStringAsFixed(0)}',
            fraction: cashPct,
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String label,
    required String value,
    required double fraction,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: WaffleTheme.textLight, fontSize: 12),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: WaffleTheme.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: WaffleTheme.primary.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ─── Insight Row ───────────────────────────────────────

  Widget _buildInsightRow() {
    String peakTime = '–';
    if (_trendPoints.isNotEmpty) {
      final peak = [..._trendPoints]
        ..sort((a, b) => b.value.compareTo(a.value));
      peakTime = peak.first.label;
    }

    return Row(
      children: [
        Expanded(
          child: _insightCard(
            icon: Icons.schedule_rounded,
            iconColor: WaffleTheme.primary,
            iconBg: WaffleTheme.primary.withValues(alpha: 0.10),
            value: peakTime,
            label: 'Peak hour',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _insightCard(
            icon: Icons.phone_android_rounded,
            iconColor: WaffleTheme.secondary,
            iconBg: WaffleTheme.secondary.withValues(alpha: 0.10),
            value: _upiAmount >= _cashAmount ? 'UPI' : 'Cash',
            label: 'Top payment',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _insightCard(
            icon: Icons.trending_up_rounded,
            iconColor: WaffleTheme.success,
            iconBg: WaffleTheme.success.withValues(alpha: 0.10),
            value: '+18%',
            label: 'vs yesterday',
          ),
        ),
      ],
    );
  }

  Widget _insightCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: WaffleTheme.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: WaffleTheme.textLight, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Shared card shell ─────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WaffleTheme.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

// ─── Donut painter ─────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double upiFraction;
  final Color primaryColor;
  final Color secondaryColor;
  final Color bgColor;

  const _DonutPainter({
    required this.upiFraction,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 10.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeW / 2,
    );

    // Background ring
    canvas.drawArc(
      rect,
      0,
      2 * 3.14159,
      false,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    const startAngle = -1.5708; // -π/2 (top)
    final upiSweep = 2 * 3.14159 * upiFraction.clamp(0.02, 0.98);

    // UPI arc
    canvas.drawArc(
      rect,
      startAngle,
      upiSweep,
      false,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Cash arc
    final cashSweep = 2 * 3.14159 * (1 - upiFraction).clamp(0.02, 0.98);
    canvas.drawArc(
      rect,
      startAngle + upiSweep,
      cashSweep,
      false,
      Paint()
        ..color = secondaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.upiFraction != upiFraction;
}

// ─── Data class ────────────────────────────────────────────

class _TrendPoint {
  final String label;
  final double value;
  const _TrendPoint(this.label, this.value);
}
