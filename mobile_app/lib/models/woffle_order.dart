class Order {
  final int orderId;
  final String orderLabel;
  final int? displayIndex; // Optional, for UI display only
  final int? itemsCount; // From API, for display
  final String orderDate;
  final DateTime? parsedOrderDate; // Pre-parsed for sort performance
  final String price;
  final String totalAmount;
  final String upiAmount;
  final String cashAmount;
  final String paymentMethod;
  final String customerName;
  final String status;
  final bool completed;
  final List<OrderItem> items;
  String emoji;
  String color;

  Order({
    required this.orderId,
    required this.orderLabel,
    this.displayIndex,
    this.itemsCount,
    required this.orderDate,
    this.parsedOrderDate,
    required this.price,
    required this.totalAmount,
    required this.upiAmount,
    required this.cashAmount,
    required this.paymentMethod,
    required this.customerName,
    required this.status,
    required this.completed,
    required this.items,
    this.emoji = '🍦',
    this.color = '#FF6B6B',
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 0;
    }

    final rawLabel = json['id']?.toString() ?? '';
    final orderId = parseInt(json['order_id'] ?? rawLabel);
    final orderLabel = rawLabel.isNotEmpty
        ? rawLabel
        : orderId > 0
            ? '#ORD-$orderId'
            : '#ORD-0';

    final dateStr = json['order_date'] ?? json['date'] ?? '';
    final statusString = json['status']?.toString() ??
        (json['completed'] == true ? 'Completed' : 'Pending');
    final completed = statusString.toString().toLowerCase() == 'completed' ||
        json['completed'] == true;
    final totalAmountValue = json['total_amount']?.toString() ?? json['price']?.toString() ?? '0.00';

    return Order(
      orderId: orderId,
      orderLabel: orderLabel,
      displayIndex: json['index'],
      itemsCount: json['items_count'],
      orderDate: dateStr,
      parsedOrderDate: dateStr.isNotEmpty
          ? DateTime.tryParse(dateStr)?.toLocal()
          : null,
      price: json['price']?.toString() ?? totalAmountValue,
      totalAmount: totalAmountValue,
      upiAmount: json['upi_amount']?.toString() ?? '0.0',
      cashAmount: json['cash_amount']?.toString() ?? '0.0',
      paymentMethod: json['payment_method']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      status: statusString,
      completed: completed,
      items: (json['items'] as List<dynamic>?)
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
      'id': orderLabel,
      'index': displayIndex,
      'items_count': itemsCount,
      'order_date': orderDate,
      'price': price,
      'total_amount': totalAmount,
      'upi_amount': upiAmount,
      'cash_amount': cashAmount,
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'status': status,
      'completed': completed,
      'items': items.map((item) => item.toJson()).toList(),
      'emoji': emoji,
      'color': color,
    };
  }

  double get totalPrice {
    return double.tryParse(totalAmount) ?? double.tryParse(price) ?? 0.0;
  }

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
  final String? productType; // product type (ice_sticks)

  OrderItem({
    required this.itemId,
    this.orderItemId,
    required this.product,
    required this.price,
    required this.pieces,
    this.productType,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 0;
    }

    final itemId = parseInt(json['item_id'] ?? json['ProductID'] ?? json['product_id']);
    return OrderItem(
      itemId: itemId,
      orderItemId: json['order_item_id'] != null ? parseInt(json['order_item_id']) : null,
      product: json['product']?.toString() ?? json['ProductName']?.toString() ?? '',
      price: json['price']?.toString() ?? json['Price']?.toString() ?? '0',
      pieces: json['pieces'] ?? json['Quantity'] ?? 0,
      productType: json['product_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      if (orderItemId != null) 'order_item_id': orderItemId,
      'product': product,
      'price': price,
      'pieces': pieces,
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
    final payload = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : json;
    final ordersJson = (json['orders'] ?? payload['orders']) as List<dynamic>?;

    return DailySummary(
      totalOrders: payload['orders_count'] ?? payload['total_orders'] ?? 0,
      totalRevenue: (payload['total_amount'] ?? payload['total_revenue'] ?? 0.0)
          .toDouble(),
      totalUpi: (payload['total_upi'] ?? 0.0).toDouble(),
      totalCash: (payload['total_cash'] ?? 0.0).toDouble(),
      completedOrders: payload['completed_orders'],
      pendingOrders: payload['pending_orders'],
      orders: ordersJson
              ?.map((order) => Order.fromJson(order as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
