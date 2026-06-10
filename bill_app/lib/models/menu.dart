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
    return Product(
      productId: json['product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      image: json['image']?.toString(),
      active: json['active'] is bool ? json['active'] : json['active'] == 1,
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

class ScoopCategory {
  final String tubCategoryId;
  final String name;
  final int quantityInMl;
  final int availableScoops;
  final double liter;
  final int tubsInStock;

  ScoopCategory({
    required this.tubCategoryId,
    required this.name,
    required this.quantityInMl,
    required this.availableScoops,
    required this.liter,
    required this.tubsInStock,
  });

  factory ScoopCategory.fromJson(Map<String, dynamic> json) {
    return ScoopCategory(
      tubCategoryId: json['tub_category_id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantityInMl: (json['quantity_in_ml'] is num)
          ? (json['quantity_in_ml'] as num).toInt()
          : int.tryParse(json['quantity_in_ml']?.toString() ?? '0') ?? 0,
      availableScoops: (json['available_scoops'] is num)
          ? (json['available_scoops'] as num).toInt()
          : 0,
      liter: (json['liter'] is num) ? (json['liter'] as num).toDouble() : 0.0,
      tubsInStock: (json['tubs_in_stock'] is num)
          ? (json['tubs_in_stock'] as num).toInt()
          : 0,
    );
  }
}

class ScoopPrice {
  final String scoopPriceId;
  final String tubProductId;
  final String tubProductName;
  final String price;
  final String quantityInMl;
  final int? availableScoops;
  final int? totalMlAvailable;
  final int? tubsInStock;
  final bool? active;
  final List<ScoopCategory> categories;

  ScoopPrice({
    required this.scoopPriceId,
    required this.tubProductId,
    required this.tubProductName,
    required this.price,
    required this.quantityInMl,
    this.availableScoops,
    this.totalMlAvailable,
    this.tubsInStock,
    this.active,
    this.categories = const [],
  });

  factory ScoopPrice.fromJson(Map<String, dynamic> json) {
    return ScoopPrice(
      scoopPriceId: json['scoop_price_id']?.toString() ?? '',
      tubProductId: json['tub_product_id']?.toString() ?? '',
      tubProductName: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      quantityInMl: json['quantity_in_ml']?.toString() ?? '100',
      availableScoops: (json['available_scoops'] is num)
          ? (json['available_scoops'] as num).toInt()
          : null,
      totalMlAvailable: (json['total_ml_available'] is num)
          ? (json['total_ml_available'] as num).toInt()
          : null,
      tubsInStock: (json['tubs_in_stock'] is num)
          ? (json['tubs_in_stock'] as num).toInt()
          : null,
      active: json['active'] as bool?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((item) => ScoopCategory.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scoop_price_id': scoopPriceId,
      'tub_product_id': tubProductId,
      'tub_product_name': tubProductName,
      'price': price,
      'quantity_in_ml': quantityInMl,
      if (availableScoops != null) 'available_scoops': availableScoops,
      if (totalMlAvailable != null) 'total_ml_available': totalMlAvailable,
      if (tubsInStock != null) 'tubs_in_stock': tubsInStock,
      if (active != null) 'active': active,
    };
  }

  double get priceDouble => double.tryParse(price) ?? 0.0;
}

class ScoopProductInCategory {
  final String scoopPriceId;
  final String tubProductId;
  final String name;
  final String price;
  final String quantityInMl;
  final int availableScoops;
  final bool active;

  ScoopProductInCategory({
    required this.scoopPriceId,
    required this.tubProductId,
    required this.name,
    required this.price,
    required this.quantityInMl,
    required this.availableScoops,
    required this.active,
  });

  factory ScoopProductInCategory.fromJson(Map<String, dynamic> json) {
    return ScoopProductInCategory(
      scoopPriceId: json['scoop_price_id']?.toString() ?? '',
      tubProductId: json['tub_product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      quantityInMl: json['quantity_in_ml']?.toString() ?? '100',
      availableScoops: (json['available_scoops'] is num)
          ? (json['available_scoops'] as num).toInt()
          : 0,
      active: json['active'] as bool? ?? false,
    );
  }

  double get priceDouble => double.tryParse(price) ?? 0.0;
}

class ScoopCategoryRow {
  final String tubCategoryId;
  final String name;
  final int quantityInMl;
  final List<ScoopProductInCategory> scoopProducts;

  ScoopCategoryRow({
    required this.tubCategoryId,
    required this.name,
    required this.quantityInMl,
    required this.scoopProducts,
  });

  factory ScoopCategoryRow.fromJson(Map<String, dynamic> json) {
    return ScoopCategoryRow(
      tubCategoryId: json['tub_category_id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantityInMl: (json['quantity_in_ml'] is num)
          ? (json['quantity_in_ml'] as num).toInt()
          : int.tryParse(json['quantity_in_ml']?.toString() ?? '0') ?? 0,
      scoopProducts:
          (json['scoop_products'] as List<dynamic>?)
              ?.map((p) => ScoopProductInCategory.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class Scoops {
  final List<ScoopPrice> scoopPrices;
  final List<ScoopCategoryRow> byCategory;

  Scoops({required this.scoopPrices, this.byCategory = const []});

  factory Scoops.fromJson(Map<String, dynamic> json) {
    return Scoops(
      scoopPrices:
          (json['products'] as List<dynamic>?)
              ?.map((item) => ScoopPrice.fromJson(item))
              .toList() ??
          [],
      byCategory:
          (json['by_category'] as List<dynamic>?)
              ?.map((cat) => ScoopCategoryRow.fromJson(cat))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'products': scoopPrices.map((scoop) => scoop.toJson()).toList()};
  }
}

class TubProduct {
  final String tubProductId;
  final String name;
  final String price;
  final int tubStock;
  final double liter;
  final int reorderLevel;

  TubProduct({
    required this.tubProductId,
    required this.name,
    required this.price,
    this.tubStock = 0,
    this.liter = 0,
    this.reorderLevel = 0,
  });

  factory TubProduct.fromJson(Map<String, dynamic> json) {
    return TubProduct(
      tubProductId: json['tub_product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      tubStock: (json['tub_stock'] is num)
          ? (json['tub_stock'] as num).toInt()
          : int.tryParse(json['tub_stock']?.toString() ?? '0') ?? 0,
      liter: (json['liter'] is num)
          ? (json['liter'] as num).toDouble()
          : double.tryParse(json['liter']?.toString() ?? '0') ?? 0,
      reorderLevel: (json['reorder_level'] is num)
          ? (json['reorder_level'] as num).toInt()
          : int.tryParse(json['reorder_level']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tub_product_id': tubProductId,
      'name': name,
      'price': price,
      'tub_stock': tubStock,
      'liter': liter,
      'reorder_level': reorderLevel,
    };
  }

  double get priceDouble => double.tryParse(price) ?? 0.0;

  bool get isOutOfStock => tubStock <= 0;
  bool get isLowStock => !isOutOfStock && tubStock <= reorderLevel;
}

class TubCategory {
  final String tubCategoryId;
  final String name;
  final String quantityInMl;
  final List<TubProduct> products;

  TubCategory({
    required this.tubCategoryId,
    required this.name,
    required this.quantityInMl,
    required this.products,
  });

  factory TubCategory.fromJson(Map<String, dynamic> json) {
    return TubCategory(
      tubCategoryId: json['tub_category_id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantityInMl: json['quantity_in_ml']?.toString() ?? '',
      products:
          (json['products'] as List<dynamic>?)
              ?.map((product) => TubProduct.fromJson(product))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tub_category_id': tubCategoryId,
      'name': name,
      'quantity_in_ml': quantityInMl,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}

class Tubs {
  final List<TubCategory> categories;

  Tubs({required this.categories});

  factory Tubs.fromJson(Map<String, dynamic> json) {
    return Tubs(
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((category) => TubCategory.fromJson(category))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }
}

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
  final Tubs? tubs;
  final Scoops? scoops;
  final List<Product> products;

  Menu({
    required this.iceSticks,
    this.tubs,
    this.scoops,
    required this.products,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final menuData = json['menu'] as Map<String, dynamic>?;

    if (menuData == null) {
      return Menu(iceSticks: {}, products: []);
    }

    // Parse IceSticks
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

        // Group categories by name for the iceSticks map
        if (iceSticks.containsKey(categoryName)) {
          iceSticks[categoryName]!.add(category);
        } else {
          iceSticks[categoryName] = [category];
        }
      }
    }

    // Parse Tubs
    Tubs? tubs;
    if (menuData.containsKey('Tubs')) {
      tubs = Tubs.fromJson(menuData['Tubs'] as Map<String, dynamic>);
    }

    // Parse Scoops
    Scoops? scoops;
    if (menuData.containsKey('Scoops')) {
      scoops = Scoops.fromJson(menuData['Scoops'] as Map<String, dynamic>);
    }

    return Menu(
      iceSticks: iceSticks,
      tubs: tubs,
      scoops: scoops,
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
        if (tubs != null) 'Tubs': tubs!.toJson(),
        if (scoops != null) 'Scoops': scoops!.toJson(),
      },
      'products': products.map((product) => product.toJson()).toList(),
    };
  }

  // Helper method to get all ice stick categories
  List<Category> get allIceStickCategories {
    return iceSticks.values.expand((categories) => categories).toList();
  }
}
