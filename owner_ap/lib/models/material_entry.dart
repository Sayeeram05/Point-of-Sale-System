/// MaterialEntry model representing raw material entries
/// Connects to Django Materials API backend
class MaterialEntry {
  final String id;
  final DateTime entryDate;
  final String rawMaterialProduct;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialEntry({
    required this.id,
    required this.entryDate,
    required this.rawMaterialProduct,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  /// Create MaterialEntry from JSON (Django API response)
  factory MaterialEntry.fromJson(Map<String, dynamic> json) {
    return MaterialEntry(
      id: json['id']?.toString() ?? '',
      entryDate: DateTime.tryParse(json['entry_date']?.toString() ?? '') ?? DateTime.now(),
      rawMaterialProduct: json['raw_material_product']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Convert MaterialEntry to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_date': entryDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'raw_material_product': rawMaterialProduct,
      'price': price,
    };
  }

  /// Create a copy of MaterialEntry with updated fields
  MaterialEntry copyWith({
    String? id,
    DateTime? entryDate,
    String? rawMaterialProduct,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialEntry(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      rawMaterialProduct: rawMaterialProduct ?? this.rawMaterialProduct,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted price string in Indian Rupee
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MaterialEntry(id: $id, rawMaterialProduct: $rawMaterialProduct, price: $price, entryDate: $entryDate)';
  }
}

/// Request model for creating/updating material entries
class MaterialEntryRequest {
  final DateTime entryDate;
  final String rawMaterialProduct;
  final double price;

  const MaterialEntryRequest({
    required this.entryDate,
    required this.rawMaterialProduct,
    required this.price,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'entry_date': entryDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'raw_material_product': rawMaterialProduct.trim(),
      'price': price,
    };
  }

  /// Create from form data
  factory MaterialEntryRequest.fromForm({
    required DateTime entryDate,
    required String rawMaterialProduct,
    required double price,
  }) {
    return MaterialEntryRequest(
      entryDate: entryDate,
      rawMaterialProduct: rawMaterialProduct.trim(),
      price: price,
    );
  }

  /// Validation
  bool get isValid {
    return rawMaterialProduct.trim().isNotEmpty && price >= 0;
  }

  String? get validationError {
    if (rawMaterialProduct.trim().isEmpty) {
      return 'Raw material product name is required';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }
}
