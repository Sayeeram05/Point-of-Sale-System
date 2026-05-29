class Order {
  final int orderId;
  final int? displayIndex; // Optional, for UI display only
  final int? itemsCount; // From API, for display
  final String orderDate;
  final DateTime? parsedOrderDate; // Pre-parsed for sort performance
  final String price;
  final String upiAmount;
  final String cashAmount;
  final bool completed;
  final List<OrderItem> items;
  String emoji;
  String color;

  Order({
    required this.orderId,
    this.displayIndex,
    this.itemsCount,
    required this.orderDate,
    this.parsedOrderDate,
    required this.price,
    required this.upiAmount,
    required this.cashAmount,
    required this.completed,
    required this.items,
    this.emoji = '🍦',
    this.color = '#FF6B6B',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final dateStr = json['order_date'] ?? '';
    return Order(
      orderId: json['order_id'] ?? 0,
      displayIndex: json['index'],
      itemsCount: json['items_count'],
      orderDate: dateStr,
      parsedOrderDate: dateStr.isNotEmpty
          ? DateTime.tryParse(dateStr)?.toLocal()
          : null,
      price: json['price']?.toString() ?? '0.00',
      upiAmount: json['upi_amount']?.toString() ?? '0.0',
      cashAmount: json['cash_amount']?.toString() ?? '0.0',
      completed: json['completed'] ?? false,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      emoji: json['emoji'] ?? '🍦',
      color: json['color'] ?? '#FF6B6B',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'index': displayIndex,
      'items_count': itemsCount,
      'order_date': orderDate,
      'price': price,
      'upi_amount': upiAmount,
      'cash_amount': cashAmount,
      'completed': completed,
      'items': items.map((item) => item.toJson()).toList(),
      'emoji': emoji,
      'color': color,
    };
  }

  double get totalPrice => double.tryParse(price) ?? 0.0;
  double get upiAmountDouble => double.tryParse(upiAmount) ?? 0.0;
  double get cashAmountDouble => double.tryParse(cashAmount) ?? 0.0;
  int get totalItems => items.fold(0, (sum, item) => sum + item.pieces);
}

class OrderItem {
  final int itemId;
  final int? orderItemId;
  final String product;
  final String price;
  final int pieces;
  final int? tubCategory; // New field for tub category
  final int? scoopPriceId; // New field for scoop price
  final String?
  productType; // New field for product type (ice_sticks, tubs, scoops)

  OrderItem({
    required this.itemId,
    this.orderItemId,
    required this.product,
    required this.price,
    required this.pieces,
    this.tubCategory,
    this.scoopPriceId,
    this.productType,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'] ?? 0,
      orderItemId: json['order_item_id'],
      product: json['product'] ?? '',
      price: json['price']?.toString() ?? '0',
      pieces: json['pieces'] ?? 0,
      tubCategory: json['tub_category'],
      scoopPriceId: json['scoop_price_id'],
      productType: json['product_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      if (orderItemId != null) 'order_item_id': orderItemId,
      'product': product,
      'price': price,
      'pieces': pieces,
      if (tubCategory != null) 'tub_category': tubCategory,
      if (scoopPriceId != null) 'scoop_price_id': scoopPriceId,
      if (productType != null) 'product_type': productType,
    };
  }

  double get priceDouble => double.tryParse(price) ?? 0.0;
  double get totalPrice => priceDouble * pieces;
}

class DailySummary {
  final int totalOrders;
  final double totalRevenue;
  final double totalUpi;
  final double totalCash;
  final int? completedOrders;
  final int? pendingOrders;
  final List<Order> orders;

  DailySummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalUpi,
    required this.totalCash,
    this.completedOrders,
    this.pendingOrders,
    required this.orders,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      totalUpi: (json['total_upi'] ?? 0.0).toDouble(),
      totalCash: (json['total_cash'] ?? 0.0).toDouble(),
      completedOrders: json['completed_orders'],
      pendingOrders: json['pending_orders'],
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((order) => Order.fromJson(order))
              .toList() ??
          [],
    );
  }
}
