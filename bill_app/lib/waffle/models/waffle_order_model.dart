class WaffleOrderItem {
  final int id;
  final int productId;
  final String productName;
  final double price;
  final int quantity;

  WaffleOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  factory WaffleOrderItem.fromJson(Map<String, dynamic> json) {
    return WaffleOrderItem(
      id: json['ID'] as int,
      productId: json['ProductID'] is int
          ? json['ProductID'] as int
          : int.tryParse(json['ProductID']?.toString() ?? '0') ?? 0,
      productName:
          json['ProductName']?.toString() ??
          json['ProductID']?.toString() ??
          '',
      price: (json['PriceAtPurchase'] is num)
          ? (json['PriceAtPurchase'] as num).toDouble()
          : double.tryParse(json['PriceAtPurchase']?.toString() ?? '0') ?? 0.0,
      quantity: json['Quantity'] is int
          ? json['Quantity'] as int
          : int.tryParse(json['Quantity']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson(int orderId) {
    return {
      'OrderId': orderId,
      'ProductID': productId,
      'Quantity': quantity,
      'PriceAtPurchase': price,
    };
  }

  double get totalPrice => price * quantity;
}

class WaffleOrder {
  final int id;
  final bool completed;
  final double totalAmount;
  final double cashAmount;
  final double upiAmount;
  final int totalQuantity;
  final DateTime? createdAt;
  final List<WaffleOrderItem> items;

  WaffleOrder({
    required this.id,
    required this.completed,
    required this.totalAmount,
    required this.cashAmount,
    required this.upiAmount,
    required this.totalQuantity,
    required this.items,
    this.createdAt,
  });

  factory WaffleOrder.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final digits = RegExp(r'\d+').firstMatch(value);
        if (digits != null) return int.tryParse(digits.group(0) ?? '') ?? 0;
      }
      return 0;
    }

    final rawItems =
        json['OrderItems'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        [];
    final items = rawItems.map<WaffleOrderItem>((item) {
      if (item is Map<String, dynamic>) {
        return WaffleOrderItem.fromJson(item);
      }
      final text = item?.toString() ?? '';
      final match = RegExp(r'^(.*) \((\d+)\)\$').firstMatch(text);
      if (match != null) {
        return WaffleOrderItem(
          id: 0,
          productId: 0,
          productName: match.group(1)!.trim(),
          price: 0.0,
          quantity: int.tryParse(match.group(2) ?? '0') ?? 0,
        );
      }
      return WaffleOrderItem(
        id: 0,
        productId: 0,
        productName: text,
        price: 0.0,
        quantity: 1,
      );
    }).toList();

    final status = json['status']?.toString().toLowerCase();
    final totalAmount = (json['total_amount'] is num)
        ? (json['total_amount'] as num).toDouble()
        : double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0;

    final cashAmount = (json['CashAmount'] is num)
        ? (json['CashAmount'] as num).toDouble()
        : double.tryParse(json['CashAmount']?.toString() ?? '0') ?? 0.0;
    final upiAmount = (json['UpiAmount'] is num)
        ? (json['UpiAmount'] as num).toDouble()
        : double.tryParse(json['UpiAmount']?.toString() ?? '0') ?? 0.0;

    return WaffleOrder(
      id: parseId(json['ID'] ?? json['id']),
      completed: json['Completed'] == true || status == 'completed',
      cashAmount: cashAmount,
      upiAmount: upiAmount,
      totalAmount: totalAmount,
      totalQuantity: json['TotalQuantity'] is int
          ? json['TotalQuantity'] as int
          : int.tryParse(json['TotalQuantity']?.toString() ?? '0') ??
                items.fold<int>(0, (sum, item) => sum + item.quantity),
      items: items,
      createdAt: json['CreatedAt'] != null
          ? DateTime.tryParse(json['CreatedAt'].toString())
          : null,
    );
  }

  double get totalPrice {
    if (items.isEmpty) {
      return cashAmount + upiAmount;
    }
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String get paymentMethod {
    if (completed) {
      if (cashAmount > 0 && upiAmount > 0) return 'Cash + UPI';
      if (upiAmount > 0) return 'UPI';
      return 'Cash';
    }
    return 'Pending';
  }
}
