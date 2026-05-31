class Product {
  final String productId;
  final String name;
  final String price;
  final String? image;
  final bool? active;
  final int? pieces;
  final int reorderLevel;

  Product({
    required this.productId,
    required this.name,
    required this.price,
    this.image,
    this.active,
    this.pieces,
    this.reorderLevel = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final productId = json['product_id']?.toString() ?? json['ID']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['name'] ?? json['Name'] ?? '';
    final price = json['price']?.toString() ?? json['Price']?.toString() ?? '0';
    final deleted = json['Deleted'];

    return Product(
      productId: productId,
      name: name,
      price: price,
      image: json['image']?.toString(),
      active: json.containsKey('active')
          ? (json['active'] is bool ? json['active'] : json['active'] == 1)
          : (deleted == null ? true : deleted == false),
      pieces: json['pieces'] is int
          ? json['pieces']
          : int.tryParse(json['pieces']?.toString() ?? ''),
      reorderLevel: (json['reorder_level'] is num)
          ? (json['reorder_level'] as num).toInt()
          : int.tryParse(json['reorder_level']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      if (image != null) 'image': image,
      if (active != null) 'active': active,
      if (pieces != null) 'pieces': pieces,
      'reorder_level': reorderLevel,
    };
  }

  double get priceDouble => double.tryParse(price) ?? 0.0;

  bool get isOutOfStock => (pieces ?? 0) <= 0;
  bool get isLowStock => !isOutOfStock && (pieces ?? 0) <= reorderLevel;
}



// Removed Tubs and Scoops related classes — app now only supports Ice Sticks

class Category {
  final int categoryId;
  final String name;
  final int productCount;
  final List<Product> products;

  Category({
    required this.categoryId,
    required this.name,
    required this.productCount,
    required this.products,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      productCount: json['product_count'] ?? 0,
      products:
          (json['products'] as List<dynamic>?)
              ?.map((product) => Product.fromJson(product))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'product_count': productCount,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}

class Menu {
  final Map<String, List<Category>> iceSticks;
  final List<Product> products;

  Menu({
    required this.iceSticks,
    required this.products,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final menuData = json['menu'] as Map<String, dynamic>?;

    if (menuData != null) {
      return Menu._fromOldFormat(menuData);
    }

    // New API format: top-level categories map to product lists.
    final Map<String, List<Category>> iceSticks = {};
    final List<Product> allProducts = [];

    for (final entry in json.entries) {
      if (entry.value is List<dynamic>) {
        final categoryName = entry.key;
        final products = (entry.value as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((productJson) => Product.fromJson(productJson))
            .toList();

        if (products.isEmpty) {
          continue;
        }

        final category = Category(
          categoryId: categoryName.hashCode,
          name: categoryName,
          productCount: products.length,
          products: products,
        );

        iceSticks[categoryName] = [category];
        allProducts.addAll(products);
      }
    }

    return Menu(
      iceSticks: iceSticks,
      products: allProducts,
    );
  }

  factory Menu._fromOldFormat(Map<String, dynamic> menuData) {
    final Map<String, List<Category>> iceSticks = {};
    final List<Product> allProducts = [];

    if (menuData.containsKey('IceSticks')) {
      final iceStickData = menuData['IceSticks'] as List<dynamic>;

      for (int index = 0; index < iceStickData.length; index++) {
        final categoryJson = iceStickData[index] as Map<String, dynamic>;
        final categoryName = categoryJson['name'] ?? 'Category ${index + 1}';

        final category = Category(
          categoryId: index + 1,
          name: categoryName,
          productCount: (categoryJson['products'] as List?)?.length ?? 0,
          products:
              (categoryJson['products'] as List<dynamic>?)
                  ?.map((product) => Product.fromJson(product))
                  .toList() ??
              [],
        );

        allProducts.addAll(category.products);

        if (iceSticks.containsKey(categoryName)) {
          iceSticks[categoryName]!.add(category);
        } else {
          iceSticks[categoryName] = [category];
        }
      }
    }

    return Menu(
      iceSticks: iceSticks,
      products: allProducts,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> iceStickJson = {};
    for (final entry in iceSticks.entries) {
      iceStickJson[entry.key] = entry.value
          .map((category) => category.toJson())
          .toList();
    }

    return {
      'menu': {
        'IceSticks': iceStickJson,
      },
      'products': products.map((product) => product.toJson()).toList(),
    };
  }

  // Helper method to get all ice stick categories
  List<Category> get allIceStickCategories {
    return iceSticks.values.expand((categories) => categories).toList();
  }
}
