class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['ID'] as int, name: json['Name'] as String);
  }
}

class ProductModel {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final bool deleted;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.deleted,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final priceValue = json['Price'];
    return ProductModel(
      id: json['ID'] as int,
      name: json['Name'] as String,
      price: priceValue is String
          ? double.tryParse(priceValue) ?? 0
          : (priceValue as num).toDouble(),
      categoryId: json['ProductCategory'] as int,
      deleted: json['Deleted'] as bool,
    );
  }
}

class CartItemModel {
  final int id;
  final String name;
  final double price;
  int quantity;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  String get priceLabel => '₹${price.toStringAsFixed(0)}';
}

class OrderModel {
  final String id;
  final String date;
  final List<String> items;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String customerName;

  OrderModel({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.customerName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['ID'];
    final totalAmountValue = json['total_amount'] ?? json['TotalAmount'];
    final itemsValue = json['items'] ?? json['OrderItems'];
    return OrderModel(
      id: idValue?.toString() ?? '',
      date: json['date'] as String,
      items: (itemsValue as List<dynamic>)
          .map((item) => item.toString())
          .toList(),
      totalAmount: totalAmountValue is String
          ? double.tryParse(totalAmountValue) ?? 0
          : (totalAmountValue as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      customerName: json['customer_name'] as String,
    );
  }
}
