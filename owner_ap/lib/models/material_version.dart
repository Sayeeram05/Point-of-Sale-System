/// MaterialVersion model representing material configuration versions
/// Connects to Django MaterialVersion API backend
class MaterialVersion {
  final String id;
  final String name;
  final DateTime effectiveFromDate;
  final bool isActive;
  final List<MaterialVersionItem> materialItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialVersion({
    required this.id,
    required this.name,
    required this.effectiveFromDate,
    required this.isActive,
    required this.materialItems,
    this.createdAt,
    this.updatedAt,
  });

  /// Create MaterialVersion from JSON (Django API response)
  factory MaterialVersion.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['material_items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((item) => MaterialVersionItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return MaterialVersion(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      effectiveFromDate: DateTime.tryParse(json['effective_from_date']?.toString() ?? '') ?? DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      materialItems: items,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Convert MaterialVersion to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'effective_from_date': effectiveFromDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'is_active': isActive,
      'material_items': materialItems.map((item) => item.toJson()).toList(),
    };
  }

  /// Create a copy of MaterialVersion with updated fields
  MaterialVersion copyWith({
    String? id,
    String? name,
    DateTime? effectiveFromDate,
    bool? isActive,
    List<MaterialVersionItem>? materialItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialVersion(
      id: id ?? this.id,
      name: name ?? this.name,
      effectiveFromDate: effectiveFromDate ?? this.effectiveFromDate,
      isActive: isActive ?? this.isActive,
      materialItems: materialItems ?? this.materialItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get total cost of all materials in this version
  double get totalCost {
    return materialItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get formatted total cost string in Indian Rupee
  String get formattedTotalCost => '₹${totalCost.toStringAsFixed(0)}';

  /// Get count of materials in this version
  int get itemsCount => materialItems.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialVersion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MaterialVersion(id: $id, name: $name, effectiveFromDate: $effectiveFromDate, itemsCount: $itemsCount)';
  }
}

/// MaterialVersionItem model representing individual materials within a version
class MaterialVersionItem {
  final String id;
  final String materialName;
  final double price;
  final int quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialVersionItem({
    required this.id,
    required this.materialName,
    required this.price,
    this.quantity = 1,
    this.createdAt,
    this.updatedAt,
  });

  /// Create MaterialVersionItem from JSON (Django API response)
  factory MaterialVersionItem.fromJson(Map<String, dynamic> json) {
    return MaterialVersionItem(
      id: json['id']?.toString() ?? '',
      materialName: json['material_name']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  /// Convert MaterialVersionItem to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_name': materialName,
      'price': price,
      'quantity': quantity,
    };
  }

  /// Create a copy of MaterialVersionItem with updated fields
  MaterialVersionItem copyWith({
    String? id,
    String? materialName,
    double? price,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialVersionItem(
      id: id ?? this.id,
      materialName: materialName ?? this.materialName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get total price for this material (price * quantity)
  double get totalPrice => price * quantity;

  /// Increase quantity by 1
  MaterialVersionItem incrementQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  /// Decrease quantity by 1 (minimum 1)
  MaterialVersionItem decrementQuantity() {
    return copyWith(quantity: quantity > 1 ? quantity - 1 : 1);
  }

  /// Get formatted price string in Indian Rupee
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialVersionItem && 
           other.id == id && 
           other.materialName == materialName;
  }

  @override
  int get hashCode => Object.hash(id, materialName);

  @override
  String toString() {
    return 'MaterialVersionItem(id: $id, materialName: $materialName, price: $price)';
  }
}

/// AvailableMaterial model representing materials that can be added to versions
class AvailableMaterial {
  final String name;
  final double price;
  final String versionName;
  final DateTime effectiveFrom;

  const AvailableMaterial({
    required this.name,
    required this.price,
    required this.versionName,
    required this.effectiveFrom,
  });

  /// Create AvailableMaterial from JSON (Django API response)
  factory AvailableMaterial.fromJson(Map<String, dynamic> json) {
    return AvailableMaterial(
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      versionName: json['version_name']?.toString() ?? '',
      effectiveFrom: DateTime.tryParse(json['effective_from']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Get formatted price string in Indian Rupee
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailableMaterial && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'AvailableMaterial(name: $name, price: $price, versionName: $versionName)';
  }
}

/// Request model for creating material versions
class MaterialVersionRequest {
  final String name;
  final DateTime effectiveFromDate;
  final List<MaterialVersionItemRequest> materialItems;

  const MaterialVersionRequest({
    required this.name,
    required this.effectiveFromDate,
    required this.materialItems,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'effective_from_date': effectiveFromDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'material_items': materialItems.map((item) => item.toJson()).toList(),
    };
  }

  /// Validation
  bool get isValid {
    return name.trim().isNotEmpty && 
           materialItems.isNotEmpty && 
           materialItems.every((item) => item.isValid);
  }

  String? get validationError {
    if (name.trim().isEmpty) {
      return 'Version name is required';
    }
    if (materialItems.isEmpty) {
      return 'At least one material item is required';
    }
    
    for (int i = 0; i < materialItems.length; i++) {
      final error = materialItems[i].validationError;
      if (error != null) {
        return 'Material item ${i + 1}: $error';
      }
    }
    
    return null;
  }
}

/// Request model for material version items
class MaterialVersionItemRequest {
  final String materialName;
  final double price;

  const MaterialVersionItemRequest({
    required this.materialName,
    required this.price,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'material_name': materialName.trim(),
      'price': price,
    };
  }

  /// Validation
  bool get isValid {
    return materialName.trim().isNotEmpty && price >= 0;
  }

  String? get validationError {
    if (materialName.trim().isEmpty) {
      return 'Material name is required';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }
}
