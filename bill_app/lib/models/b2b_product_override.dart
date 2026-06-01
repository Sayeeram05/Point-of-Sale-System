import 'dart:convert';

/// Stores the B2B-specific overrides for a single B2C product.
/// If a field is null it means "use app default" (from B2BSettings).
class B2BProductOverride {
  final String
  productId; // matches Product.productId (sticks) or 'tub_catId_prodId' (tubs)
  final String productName; // display name (kept in sync from API)
  final String b2cPrice; // original B2C price (read-only reference)

  /// 'stick' → regular ice-stick product
  /// 'tub'   → tub product in a specific category (e.g. Vanilla in 200 ml)
  /// 'scoop' → scoop item (treated as non-stick for Stk/Box)
  final String productType;

  /// For tubs: the category display name, e.g. "Tub - 200 ml".
  /// Null for sticks.
  final String? categoryName;

  double? b2bRateInclTax; // B2B selling rate inclusive of tax
  String? hsnCode; // null / empty = no HSN printed
  double? gstPercent; // null = use B2BSettings.defaultGstPercent
  bool enabled; // false = don't show in B2B product picker

  /// Live stock available at the time the picker was opened.
  /// Null means the stock API was unreachable (no limit enforced).
  int? availableStock;

  /// For sticks: how many sticks per box (from Stock.box_pieces). Null for tubs.
  int? boxPieces;

  B2BProductOverride({
    required this.productId,
    required this.productName,
    required this.b2cPrice,
    this.productType = 'stick',
    this.categoryName,
    this.b2bRateInclTax,
    this.hsnCode,
    this.gstPercent,
    this.enabled = true,
    this.availableStock,
  });

  String get normalizedProductType {
    final type = productType.trim().toLowerCase();
    if (type.isEmpty || type == 'stick' || type == 'sticks') return 'stick';
    if (type == 'tub' || type == 'tubs') return 'tub';
    if (type == 'scoop' || type == 'scoops') return 'scoop';
    return type;
  }

  bool get isStick => normalizedProductType == 'stick';
  bool get isTub => normalizedProductType == 'tub';
  bool get isNonStick => isTub || normalizedProductType == 'scoop';
  bool get hasCustomRate => b2bRateInclTax != null && b2bRateInclTax! > 0;
  bool get hasHsn => hsnCode != null && hsnCode!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'b2cPrice': b2cPrice,
    'productType': productType,
    if (categoryName != null) 'categoryName': categoryName,
    if (b2bRateInclTax != null) 'b2bRateInclTax': b2bRateInclTax,
    if (hsnCode != null) 'hsnCode': hsnCode,
    if (gstPercent != null) 'gstPercent': gstPercent,
    'enabled': enabled,
  };

  /// Safely converts a dynamic value (num or String) to double.
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory B2BProductOverride.fromJson(
    Map<String, dynamic> json,
  ) => B2BProductOverride(
    // Accept both camelCase (local) and snake_case (server)
    productId: (json['productId'] ?? json['product_id'])?.toString() ?? '',
    productName:
        (json['productName'] ?? json['product_name'])?.toString() ?? '',
    b2cPrice: (json['b2cPrice'] ?? json['b2c_price'])?.toString() ?? '0',
    productType:
        (json['productType'] ?? json['product_type'])?.toString() ?? 'stick',
    categoryName: (json['categoryName'] ?? json['category_name'])?.toString(),
    b2bRateInclTax: _toDouble(
      json['b2bRateInclTax'] ?? json['b2b_rate_incl_tax'],
    ),
    hsnCode: (json['hsnCode'] ?? json['hsn_code'])?.toString(),
    gstPercent: _toDouble(json['gstPercent'] ?? json['gst_percent']),
    enabled: json['enabled'] as bool? ?? true,
  );

  static String encodeList(List<B2BProductOverride> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<B2BProductOverride> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => B2BProductOverride.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
