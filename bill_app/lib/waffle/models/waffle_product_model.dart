class WOFLCategory {
  final int id;
  final String name;

  WOFLCategory({required this.id, required this.name});

  factory WOFLCategory.fromJson(Map<String, dynamic> json) {
    return WOFLCategory(
      id: json['ID'] as int,
      name: json['Name']?.toString() ?? '',
    );
  }
}

class WOFLProduct {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final bool deleted;

  WOFLProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.deleted,
  });

  factory WOFLProduct.fromJson(Map<String, dynamic> json) {
    return WOFLProduct(
      id: json['ID'] as int,
      name: json['Name']?.toString() ?? '',
      price: (json['Price'] is num)
          ? (json['Price'] as num).toDouble()
          : double.tryParse(json['Price']?.toString() ?? '0') ?? 0.0,
      categoryId: json['ProductCategory'] is int
          ? json['ProductCategory'] as int
          : int.tryParse(json['ProductCategory']?.toString() ?? '0') ?? 0,
      deleted: json['Deleted'] == true || json['Deleted'] == 1,
    );
  }
}
