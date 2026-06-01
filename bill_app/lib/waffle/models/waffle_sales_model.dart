import 'waffle_order_model.dart';

class WaffleSalesSummary {
  final int totalOrders;
  final double totalAmount;
  final double totalCash;
  final double totalUpi;
  final List<WaffleOrder> orders;

  WaffleSalesSummary({
    required this.totalOrders,
    required this.totalAmount,
    required this.totalCash,
    required this.totalUpi,
    required this.orders,
  });

  factory WaffleSalesSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>?;
    final ordersJson = json['orders'] as List<dynamic>?;

    return WaffleSalesSummary(
      totalOrders: summary?['orders_count'] is int
          ? summary!['orders_count'] as int
          : int.tryParse(summary?['orders_count']?.toString() ?? '0') ?? 0,
      totalAmount: (summary?['total_amount'] is num)
          ? (summary!['total_amount'] as num).toDouble()
          : double.tryParse(summary?['total_amount']?.toString() ?? '0') ?? 0.0,
      totalCash: (summary?['total_cash'] is num)
          ? (summary!['total_cash'] as num).toDouble()
          : double.tryParse(summary?['total_cash']?.toString() ?? '0') ?? 0.0,
      totalUpi: (summary?['total_upi'] is num)
          ? (summary!['total_upi'] as num).toDouble()
          : double.tryParse(summary?['total_upi']?.toString() ?? '0') ?? 0.0,
      orders:
          ordersJson
              ?.map(
                (orderJson) =>
                    WaffleOrder.fromJson(orderJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
