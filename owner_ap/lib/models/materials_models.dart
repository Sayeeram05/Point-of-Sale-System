/// Data models for the Materials Tracking & Procurement feature.
/// Mirrors the Django RawMaterial / PurchaseRecord / PurchaseItem backend models.
library;

// ---------------------------------------------------------------------------
// RawMaterial — master catalog entry
// ---------------------------------------------------------------------------

class RawMaterial {
  final int id;
  final String name;
  final String unit;
  final double basePrice;
  final bool isActive;

  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.basePrice,
    required this.isActive,
  });

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'kg',
      basePrice: double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'base_price': basePrice,
        'is_active': isActive,
      };

  RawMaterial copyWith({String? name, String? unit, double? basePrice}) {
    return RawMaterial(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      basePrice: basePrice ?? this.basePrice,
      isActive: isActive,
    );
  }

  String get formattedPrice => '₹${basePrice.toStringAsFixed(2)} / $unit';
}

// ---------------------------------------------------------------------------
// PurchaseLineItem — a mutable draft row living only in the UI grid
// ---------------------------------------------------------------------------

class PurchaseLineItem {
  final int? rawMaterialId;
  final String materialName;
  final double basePrice;
  double quantity;

  PurchaseLineItem({
    this.rawMaterialId,
    required this.materialName,
    required this.basePrice,
    this.quantity = 1.0,
  });

  double get subtotal => basePrice * quantity;

  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedBasePrice => '₹${basePrice.toStringAsFixed(2)}';

  String get displayQty =>
      quantity == quantity.truncateToDouble() ? quantity.toStringAsFixed(0) : quantity.toStringAsFixed(2);

  Map<String, dynamic> toJson() => {
        'raw_material_id': rawMaterialId,
        'material_name': materialName,
        'base_price_snapshot': basePrice,
        'quantity': quantity,
      };
}

// ---------------------------------------------------------------------------
// PurchaseItem — a saved line item from the backend (immutable snapshot)
// ---------------------------------------------------------------------------

class PurchaseItem {
  final int id;
  final int? rawMaterialId;
  final String materialName;
  final double basePriceSnapshot;
  final double quantity;
  final double subtotal;

  const PurchaseItem({
    required this.id,
    this.rawMaterialId,
    required this.materialName,
    required this.basePriceSnapshot,
    required this.quantity,
    required this.subtotal,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as int? ?? 0,
      rawMaterialId: json['raw_material'] as int?,
      materialName: json['material_name']?.toString() ?? '',
      basePriceSnapshot:
          double.tryParse(json['base_price_snapshot']?.toString() ?? '0') ?? 0.0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

// ---------------------------------------------------------------------------
// PurchaseRecord — full date-keyed record returned by the backend
// ---------------------------------------------------------------------------

class PurchaseRecord {
  final int id;
  final DateTime targetDate;
  final double totalCost;
  final bool isLocked;
  final String notes;
  final List<PurchaseItem> items;

  const PurchaseRecord({
    required this.id,
    required this.targetDate,
    required this.totalCost,
    required this.isLocked,
    required this.notes,
    required this.items,
  });

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      id: json['id'] as int? ?? 0,
      targetDate:
          DateTime.tryParse(json['target_date']?.toString() ?? '') ?? DateTime.now(),
      totalCost: double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0.0,
      isLocked: json['is_locked'] as bool? ?? true,
      notes: json['notes']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
