class WaffleCategory {
  final int id;
  final String name;

  WaffleCategory({required this.id, required this.name});

  factory WaffleCategory.fromJson(Map<String, dynamic> json) {
    return WaffleCategory(
      id: json['ID'] as int,
      name: json['Name']?.toString() ?? '',
    );
  }
}

class WaffleProduct {
  final int id;
  final String name;
  final double price;
  final int categoryId;
  final bool deleted;

  WaffleProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.deleted,
  });

  factory WaffleProduct.fromJson(Map<String, dynamic> json) {
    return WaffleProduct(
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
