/// Product model representing waffle products
/// Connects to Django Product API backend
class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Product from JSON (Django API response)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price']?.toDouble()) ?? 0.0,
      categoryId: json['category_id']?.toString() ?? json['category']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      isAvailable: json['is_available']?.toBool() ?? json['available']?.toBool() ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert Product to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'description': description,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Product with updated fields
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? categoryId,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted price string in Indian Rupee
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  /// Get display name with availability status
  String get displayName => isAvailable ? name : '$name (Unavailable)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, categoryId: $categoryId, isAvailable: $isAvailable)';
  }
}

/// Request model for creating/updating products
class ProductRequest {
  final String name;
  final double price;
  final String categoryId;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;

  const ProductRequest({
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category_id': categoryId,
      'description': description,
      'image_url': imageUrl,
      'is_available': isAvailable,
    };
  }

  /// Create from form data
  factory ProductRequest.fromForm({
    required String name,
    required double price,
    required String categoryId,
    String? description,
    String? imageUrl,
    bool isAvailable = true,
  }) {
    return ProductRequest(
      name: name.trim(),
      price: price,
      categoryId: categoryId,
      description: description?.trim(),
      imageUrl: imageUrl?.trim(),
      isAvailable: isAvailable,
    );
  }
}

/// Extension to add toBool method to dynamic values
extension DynamicToBool on dynamic {
  bool? toBool() {
    if (this == null) return null;
    if (this is bool) return this as bool;
    if (this is String) {
      final str = (this as String).toLowerCase();
      return str == 'true' || str == '1';
    }
    if (this is int) return (this as int) != 0;
    return null;
  }
}