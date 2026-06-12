import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../theme/WOFL_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime? _lastLoadedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastLoadedDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final today = DateTime.now();
      if (_lastLoadedDate == null ||
          _lastLoadedDate!.day != today.day ||
          _lastLoadedDate!.month != today.month ||
          _lastLoadedDate!.year != today.year) {
        context.read<DashboardProvider>().fetchDashboard();
        _lastLoadedDate = today;
      }
    }
  }

  String _rangeTitle(String range) {
    switch (range) {
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'this_year':
        return 'This Year';
      case 'custom':
        return 'Custom';
      default:
        return 'Today';
    }
  }

  Future<void> _pickCustomRange(BuildContext context, DashboardProvider provider) async {
    final now = DateTime.now();
    DateTime tempStart = provider.customStart ?? now.subtract(const Duration(days: 6));
    DateTime tempEnd = provider.customEnd ?? now;

    String fmt(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isStart ? tempStart : tempEnd,
              firstDate: DateTime(now.year - 2),
              lastDate: now,
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: WOFLTheme.primary,
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setSheetState(() {
                if (isStart) {
                  tempStart = picked;
                  if (tempEnd.isBefore(tempStart)) tempEnd = tempStart;
                } else {
                  tempEnd = picked;
                  if (tempStart.isAfter(tempEnd)) tempStart = tempEnd;
                }
              });
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: WOFLTheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WOFLTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Date Range',
                  style: TextStyle(
                    color: WOFLTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _dateRow('From', fmt(tempStart), () => pickDate(true)),
                const SizedBox(height: 10),
                _dateRow('To', fmt(tempEnd), () => pickDate(false)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: WOFLTheme.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: WOFLTheme.textLight, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          provider.changeCustomRange(tempStart, tempEnd);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: WOFLTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dateRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WOFLTheme.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 15, color: WOFLTheme.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: WOFLTheme.textLight, fontSize: 12),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: WOFLTheme.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 16, color: WOFLTheme.textLight),
          ],
        ),
      ),
    );
  }

  String _rangeDateLabel() {
    final now = DateTime.now();
    return '${now.day} ${_monthName(now.month)} ${now.year}';
  }

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  String _formatChartDate(String isoDate) {
    if (isoDate.length == 7) {
      final parts = isoDate.split('-');
      final month = int.tryParse(parts[1]) ?? 0;
      return _monthName(month).substring(0, 3);
    }
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return '${parsed.day} ${_monthName(parsed.month).substring(0, 3)}';
  }

  // ─── BUILD ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WOFLTheme.background,
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(WOFLTheme.primary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchDashboard,
            color: WOFLTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(provider),
                  const SizedBox(height: 10),
                  _buildSalesKpiGrid(provider),
                  const SizedBox(height: 10),
                  _buildMiddleRow(provider),
                  const SizedBox(height: 18),
                  _buildPnlSectionHeader(),
                  const SizedBox(height: 10),
                  _buildAnalyticsRow(provider),
                  const SizedBox(height: 10),
                  _buildLedgerTable(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────

  Widget _buildHeader(DashboardProvider provider) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  color: WOFLTheme.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _rangeDateLabel(),
                style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _filterChip('Today', 'today', provider),
                _filterChip('Week', 'this_week', provider),
                _filterChip('Month', 'this_month', provider),
                _filterChip('Year', 'this_year', provider),
                _customChip(provider),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusPill(provider),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: provider.isLoading ? null : provider.fetchDashboard,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: WOFLTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: WOFLTheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: provider.isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(WOFLTheme.primary),
                      ),
                    )
                  : Icon(Icons.refresh_rounded, size: 16, color: WOFLTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(DashboardProvider provider) {
    final color = provider.isLive ? WOFLTheme.success : WOFLTheme.accent;
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
            provider.isLive ? 'Live' : 'Demo',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, DashboardProvider provider) {
    final active = provider.selectedRange == value;
    return GestureDetector(
      onTap: () => provider.changeRange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? WOFLTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? WOFLTheme.primary : WOFLTheme.border,
            width: active ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : WOFLTheme.textLight,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _customChip(DashboardProvider provider) {
    final active = provider.selectedRange == 'custom';
    String label = 'Custom';
    if (active && provider.customStart != null && provider.customEnd != null) {
      final s = provider.customStart!;
      final e = provider.customEnd!;
      label = '${s.day} ${_monthName(s.month)} – ${e.day} ${_monthName(e.month)}';
    }
    return GestureDetector(
      onTap: () => _pickCustomRange(context, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? WOFLTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? WOFLTheme.primary : WOFLTheme.border,
            width: active ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 12,
              color: active ? Colors.white : WOFLTheme.textLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : WOFLTheme.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Row B: Sales KPI Cards ──────────────────────────────

  Widget _buildSalesKpiGrid(DashboardProvider provider) {
    const gap = 10.0;
    final cards = [
      _kpiCard(
        title: 'Total Revenue',
        value: '₹${provider.totalRevenue.toStringAsFixed(0)}',
        badge: provider.isLive ? 'Live' : 'Demo',
        icon: Icons.trending_up_rounded,
        accentColor: WOFLTheme.primary,
      ),
      _kpiCard(
        title: 'Total Orders',
        value: '${provider.orderCount}',
        badge: _rangeTitle(provider.selectedRange),
        icon: Icons.receipt_long_rounded,
        accentColor: WOFLTheme.secondary,
      ),
      _kpiCard(
        title: 'Avg Order',
        value: '₹${provider.avgOrderValue.toStringAsFixed(0)}',
        badge: 'per order',
        icon: Icons.bar_chart_rounded,
        accentColor: WOFLTheme.accent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
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
                      SizedBox(width: cardWidth, height: 110, child: e.value),
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
                  child: SizedBox(height: 110, width: width, child: c),
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
    required Color accentColor,
  }) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: WOFLTheme.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Row C: Revenue Trend + Payment Mix ──────────────────

  Widget _buildMiddleRow(DashboardProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 65, child: _buildTrendChartCard(provider)),
              const SizedBox(width: 10),
              Expanded(flex: 35, child: _buildPaymentMixCard(provider)),
            ],
          );
        }
        return Column(
          children: [
            _buildTrendChartCard(provider),
            const SizedBox(height: 10),
            _buildPaymentMixCard(provider),
          ],
        );
      },
    );
  }

  Widget _buildTrendChartCard(DashboardProvider provider) {
    final pts = provider.trendPoints;
    final maxY = pts.isEmpty
        ? 100.0
        : (pts.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.3).clamp(1.0, double.infinity);
    final peakIdx = pts.isEmpty
        ? -1
        : pts.indexWhere(
            (p) =>
                p.value ==
                pts.map((x) => x.value).reduce((a, b) => a > b ? a : b),
          );

    return _card(
      padding: const EdgeInsets.all(16),
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
                      'Revenue Trend',
                      style: TextStyle(
                        color: WOFLTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_rangeTitle(provider.selectedRange)} sales performance',
                      style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WOFLTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pts.length} periods',
                  style: TextStyle(
                    color: WOFLTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (pts.isEmpty)
            SizedBox(
              height: 130,
              child: Center(
                child: Text(
                  'No data available.',
                  style: TextStyle(color: WOFLTheme.textLight, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: WOFLTheme.border.withValues(alpha: 0.4),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: maxY > 0 ? maxY / 4 : 1,
                        getTitlesWidget: (val, _) => Text(
                          val >= 1000
                              ? '₹${(val / 1000).toStringAsFixed(1)}k'
                              : '₹${val.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 8,
                            color: WOFLTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= pts.length) {
                            return const SizedBox.shrink();
                          }
                          final isPeak = idx == peakIdx;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              pts[idx].label,
                              style: TextStyle(
                                fontSize: 8,
                                color: isPeak
                                    ? WOFLTheme.primary
                                    : WOFLTheme.textLight,
                                fontWeight: isPeak
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: pts.asMap().entries.map((e) {
                    final isPeak = e.key == peakIdx;
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value,
                          color: isPeak
                              ? WOFLTheme.primary
                              : WOFLTheme.primary.withValues(alpha: 0.45),
                          width: pts.length <= 7 ? 18 : (pts.length <= 14 ? 12 : 8),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          WOFLTheme.textDark.withValues(alpha: 0.9),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMixCard(DashboardProvider provider) {
    final total = provider.totalRevenue;
    final upiPct = total == 0 ? 0.0 : provider.upiAmount / total;
    final cashPct = 1 - upiPct;

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Mix',
            style: TextStyle(
              color: WOFLTheme.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'How customers pay',
            style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
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
                      primaryColor: WOFLTheme.primary,
                      secondaryColor: WOFLTheme.secondary,
                      bgColor: WOFLTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(upiPct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: WOFLTheme.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'UPI',
                          style: TextStyle(
                            color: WOFLTheme.textLight,
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
            color: WOFLTheme.primary,
            label: 'UPI',
            value: '₹${provider.upiAmount.toStringAsFixed(0)}',
            fraction: upiPct,
          ),
          const SizedBox(height: 12),
          _legendRow(
            color: WOFLTheme.secondary,
            label: 'Cash',
            value: '₹${provider.cashAmount.toStringAsFixed(0)}',
            fraction: cashPct,
          ),
        ],
      ),
    );
  }

  // ─── P&L Section Divider ──────────────────────────────────

  Widget _buildPnlSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: WOFLTheme.border,
            thickness: 0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Profit & Loss Analysis',
            style: TextStyle(
              color: WOFLTheme.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: WOFLTheme.border,
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  // ─── Row E: P&L Analytics (65% chart + 35% margin ring) ──

  Widget _buildAnalyticsRow(DashboardProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 65, child: _buildPnlChartCard(provider)),
              const SizedBox(width: 10),
              Expanded(flex: 35, child: _buildMarginRingCard(provider)),
            ],
          );
        }
        return Column(
          children: [
            _buildPnlChartCard(provider),
            const SizedBox(height: 10),
            _buildMarginRingCard(provider),
          ],
        );
      },
    );
  }

  Widget _buildPnlChartCard(DashboardProvider provider) {
    final displayData = provider.chartData;
    final maxY = displayData.isEmpty
        ? 100.0
        : (displayData
                    .map((p) => p.revenue > p.expense ? p.revenue : p.expense)
                    .reduce((a, b) => a > b ? a : b) *
                1.25)
            .clamp(1.0, double.infinity);

    return _card(
      padding: const EdgeInsets.all(16),
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
                      'Revenue vs Expenses',
                      style: TextStyle(
                        color: WOFLTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily P&L · ${_rangeTitle(provider.selectedRange)}',
                      style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _chartLegendDot(WOFLTheme.success, 'Revenue'),
              const SizedBox(width: 12),
              _chartLegendDot(WOFLTheme.error, 'Expense'),
            ],
          ),
          const SizedBox(height: 20),
          if (displayData.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No data available.',
                  style: TextStyle(color: WOFLTheme.textLight, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  groupsSpace: 6,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: WOFLTheme.border.withValues(alpha: 0.4),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: maxY > 0 ? maxY / 4 : 1,
                        getTitlesWidget: (val, _) => Text(
                          val >= 1000
                              ? '₹${(val / 1000).toStringAsFixed(1)}k'
                              : '₹${val.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 8,
                            color: WOFLTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= displayData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatChartDate(displayData[idx].date),
                              style: TextStyle(
                                fontSize: 8,
                                color: WOFLTheme.textLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: displayData.asMap().entries.map((e) {
                    final pt = e.value;
                    return BarChartGroupData(
                      x: e.key,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: pt.revenue,
                          color: WOFLTheme.success,
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: pt.expense,
                          color: WOFLTheme.error.withValues(alpha: 0.75),
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          WOFLTheme.textDark.withValues(alpha: 0.9),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Rev' : 'Exp';
                        return BarTooltipItem(
                          '$label: ₹${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chartLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: WOFLTheme.textLight, fontSize: 10)),
      ],
    );
  }

  Widget _buildMarginRingCard(DashboardProvider provider) {
    final marginFraction = (provider.profitMarginPct / 100).clamp(0.0, 1.0);
    final total = provider.totalRevenue + provider.totalExpense;
    final revFraction = total == 0 ? 0.0 : provider.totalRevenue / total;
    final expFraction = total == 0 ? 0.0 : provider.totalExpense / total;
    final profitColor =
        provider.netProfit >= 0 ? WOFLTheme.success : WOFLTheme.error;

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit Margin',
            style: TextStyle(
              color: WOFLTheme.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Net profit as % of revenue',
            style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
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
                      upiFraction: marginFraction.abs(),
                      primaryColor: profitColor,
                      secondaryColor: WOFLTheme.border,
                      bgColor: WOFLTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${provider.profitMarginPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: profitColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Margin',
                          style: TextStyle(
                            color: WOFLTheme.textLight,
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
            color: WOFLTheme.success,
            label: 'Revenue',
            value: '₹${provider.totalRevenue.toStringAsFixed(0)}',
            fraction: revFraction,
          ),
          const SizedBox(height: 12),
          _legendRow(
            color: WOFLTheme.error,
            label: 'Expenses',
            value: '₹${provider.totalExpense.toStringAsFixed(0)}',
            fraction: expFraction,
          ),
          const SizedBox(height: 14),
          Divider(color: WOFLTheme.border, thickness: 0.5, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Profit',
                style: TextStyle(
                  color: WOFLTheme.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${provider.netProfit >= 0 ? '+' : ''}₹${provider.netProfit.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: profitColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
            Text(label, style: TextStyle(color: WOFLTheme.textLight, fontSize: 12)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: WOFLTheme.textDark,
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
            backgroundColor: WOFLTheme.primary.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ─── Row F: Financial Ledger (horizontal cards) ──────────

  Widget _buildLedgerTable(DashboardProvider provider) {
    final rows = [...provider.chartData].reversed.toList();

    return _card(
      padding: const EdgeInsets.all(16),
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
                      'Daily Financial Ledger',
                      style: TextStyle(
                        color: WOFLTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chronological P&L audit log',
                      style: TextStyle(color: WOFLTheme.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WOFLTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${rows.length} entries',
                  style: TextStyle(
                    color: WOFLTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No data for selected range.',
                  style: TextStyle(color: WOFLTheme.textLight, fontSize: 12),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows.map((pt) {
                  final isProfit = pt.netProfit >= 0;
                  final profitColor =
                      isProfit ? WOFLTheme.success : WOFLTheme.error;
                  final parsed = DateTime.tryParse(pt.date);
                  final dateLabel = parsed != null
                      ? '${parsed.day} ${_monthName(parsed.month)}'
                      : pt.date;
                  return Container(
                    width: 112,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WOFLTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: WOFLTheme.border.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: TextStyle(
                            color: WOFLTheme.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ledgerMetricRow(
                          label: 'Revenue',
                          value: '₹${pt.revenue.toStringAsFixed(0)}',
                          color: WOFLTheme.success,
                        ),
                        const SizedBox(height: 6),
                        _ledgerMetricRow(
                          label: 'Cost',
                          value: '₹${pt.expense.toStringAsFixed(0)}',
                          color: WOFLTheme.error,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: profitColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isProfit ? '+' : ''}₹${pt.netProfit.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: profitColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ledgerMetricRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: WOFLTheme.textLight, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Shared card shell ───────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WOFLTheme.border.withValues(alpha: 0.5),
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
    const startAngle = -1.5708;
    final primarySweep = 2 * 3.14159 * upiFraction.clamp(0.02, 0.98);
    canvas.drawArc(
      rect,
      startAngle,
      primarySweep,
      false,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
    final secondarySweep = 2 * 3.14159 * (1 - upiFraction).clamp(0.02, 0.98);
    canvas.drawArc(
      rect,
      startAngle + primarySweep,
      secondarySweep,
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
