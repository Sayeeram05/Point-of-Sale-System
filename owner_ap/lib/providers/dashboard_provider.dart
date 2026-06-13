import 'package:flutter/material.dart';
import '../services/base_api_service.dart';

class PnlDayPoint {
  final String date;
  final double revenue;
  final double expense;
  final double netProfit;

  const PnlDayPoint({
    required this.date,
    required this.revenue,
    required this.expense,
    required this.netProfit,
  });

  factory PnlDayPoint.fromJson(Map<String, dynamic> json) {
    return PnlDayPoint(
      date: json['date'] as String? ?? '',
      revenue: _toDouble(json['revenue']),
      expense: _toDouble(json['expense']),
      netProfit: _toDouble(json['net_profit']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class TrendPoint {
  final String label;
  final double value;
  const TrendPoint(this.label, this.value);
}

class DashboardProvider extends ChangeNotifier {
  bool isLoading = true;
  String? errorMessage;
  bool isLive = false;
  String selectedRange = 'today';

  double totalRevenue = 0;
  double totalExpense = 0;
  double netProfit = 0;
  double profitMarginPct = 0;

  int orderCount = 0;
  double upiAmount = 0;
  double cashAmount = 0;
  double avgOrderValue = 0;
  double revenueChangePct = 0;

  String grouping = 'day';
  List<PnlDayPoint> chartData = [];
  List<TrendPoint> trendPoints = [];

  DateTime? customStart;
  DateTime? customEnd;

  Future<void> fetchDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      String url = '/dashboard/?filter=$selectedRange';
      if (selectedRange == 'custom' && customStart != null && customEnd != null) {
        final s = customStart!.toIso8601String().substring(0, 10);
        final e = customEnd!.toIso8601String().substring(0, 10);
        url += '&start=$s&end=$e';
      }
      final response = await BaseApiService.get(url);

      if (response is Map<String, dynamic>) {
        final sales = response['sales'] as Map<String, dynamic>? ?? {};
        final summary = response['summary'] as Map<String, dynamic>? ?? {};
        final comparison = response['comparison'] as Map<String, dynamic>? ?? {};
        final rawChartData = response['chart_data'] as List<dynamic>? ?? [];

        grouping = response['grouping'] as String? ?? 'day';

        totalRevenue = _toDouble(summary['total_revenue']);
        totalExpense = _toDouble(summary['total_expense']);
        netProfit = _toDouble(summary['net_profit']);
        profitMarginPct = _toDouble(summary['profit_margin_percentage']);

        upiAmount = _toDouble(sales['upi_revenue']);
        cashAmount = _toDouble(sales['cash_revenue']);
        orderCount = _toInt(sales['total_orders']);
        avgOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0;

        revenueChangePct = _toDouble(comparison['revenue_change_pct']);

        chartData = rawChartData
            .whereType<Map<String, dynamic>>()
            .map(PnlDayPoint.fromJson)
            .toList();

        trendPoints = _parseTrendPoints(response, grouping);

        isLive = true;
        isLoading = false;
        errorMessage = null;
      } else {
        throw Exception('Invalid response format');
      }
    } catch (_) {
      _loadMockData();
      isLive = false;
      isLoading = false;
    }
    notifyListeners();
  }

  List<TrendPoint> _parseTrendPoints(Map<String, dynamic> response, String g) {
    final List<dynamic> breakdown;
    switch (g) {
      case 'week':
        breakdown = response['weekly_breakdown'] as List<dynamic>? ?? [];
        break;
      case 'month':
        breakdown = response['monthly_breakdown'] as List<dynamic>? ?? [];
        break;
      case 'year':
        breakdown = response['yearly_breakdown'] as List<dynamic>? ?? [];
        break;
      default:
        breakdown = response['daily_breakdown'] as List<dynamic>? ?? [];
    }
    return breakdown.whereType<Map<String, dynamic>>().map((item) {
      final label = item['label']?.toString() ?? '';
      final value = _toDouble(item['value']);
      return TrendPoint(label, value);
    }).toList();
  }

  void changeRange(String range) {
    if (selectedRange == range) return;
    selectedRange = range;
    fetchDashboard();
  }

  void changeCustomRange(DateTime start, DateTime end) {
    customStart = start;
    customEnd = end;
    selectedRange = 'custom';
    fetchDashboard();
  }

  void _loadMockData() {
    totalRevenue = 1450.0;
    totalExpense = 680.0;
    netProfit = 770.0;
    profitMarginPct = 53.1;
    upiAmount = 980.0;
    cashAmount = 470.0;
    orderCount = 8;
    avgOrderValue = 181.25;
    revenueChangePct = 0.0;
    chartData = [
      const PnlDayPoint(date: '2026-06-09', revenue: 1200, expense: 0, netProfit: 1200),
      const PnlDayPoint(date: '2026-06-10', revenue: 1450, expense: 680, netProfit: 770),
    ];
    trendPoints = [
      const TrendPoint('Jun 9', 1200),
      const TrendPoint('Jun 10', 1450),
    ];
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
