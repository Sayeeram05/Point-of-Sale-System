import 'dart:convert';

class B2BInvoiceItem {
  String description;
  String hsnCode;
  double rateInclTax; // Rate inclusive of tax
  double quantity; // Always stored in STICKS (pieces) for stock logic
  String unit; // e.g., "Nos", "Kg", etc.
  double discountPercent; // Discount percentage per item
  double gstPercent;
  String productId; // Product reference for stock tracking
  String productType; // 'stick' | 'tub' | 'scoop'
  int? boxPieces; // Sticks per box (null for tubs / manual entries)

  B2BInvoiceItem({
    required this.description,
    this.hsnCode = '21050000',
    required this.rateInclTax,
    required this.quantity,
    this.unit = 'Nos',
    this.discountPercent = 0.0,
    this.gstPercent = 0.0,
    this.productId = '',
    this.productType = 'stick',
    this.boxPieces,
  });

  String get normalizedProductType {
    final type = productType.trim().toLowerCase();
    if (type.isEmpty || type == 'stick' || type == 'sticks') return 'stick';
    if (type == 'tub' || type == 'tubs') return 'tub';
    if (type == 'scoop' || type == 'scoops') return 'scoop';
    return type;
  }

  bool get isStickProduct => normalizedProductType == 'stick';
  bool get isNonStickProduct =>
      normalizedProductType == 'tub' || normalizedProductType == 'scoop';

  String get stkPerBoxLabel =>
      boxPieces != null && boxPieces! > 0 ? '$boxPieces' : '1';

  /// Quantity displayed in BOXES (sticks ÷ boxPieces). Falls back to sticks if boxPieces is null/0.
  double get quantityInBoxes =>
      (boxPieces != null && boxPieces! > 0 && isStickProduct)
      ? quantity / boxPieces!
      : quantity;

  // Rate is the selling rate (no GST split needed)
  double get taxableRate => rateInclTax;

  // Taxable Value = rate * quantity
  double get taxableValue => rateInclTax * quantity;

  // GST Amount — always 0 (GST disabled)
  double get gstAmount => 0.0;

  // Discount amount computed from percentage
  double get discountAmount => discountPercent > 0
      ? (rateInclTax * quantity) * discountPercent / 100
      : 0.0;

  // Net Amount = rate * quantity - discountAmount
  double get netAmount => (rateInclTax * quantity) - discountAmount;

  Map<String, dynamic> toJson() => {
    'description': description,
    'hsnCode': hsnCode,
    'rateInclTax': rateInclTax,
    'quantity': quantity,
    'unit': unit,
    'discountPercent': discountPercent,
    'discountAmount': discountAmount,
    'gstPercent': gstPercent,
    'productId': productId,
    'productType': productType,
    if (boxPieces != null) 'boxPieces': boxPieces,
  };

  /// Safely converts a dynamic value (num or String) to double.
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory B2BInvoiceItem.fromJson(Map<String, dynamic> json) => B2BInvoiceItem(
    description: json['description'] ?? '',
    // Accept both camelCase (local) and snake_case (server)
    hsnCode: json['hsnCode'] ?? json['hsn_code'] ?? '21050000',
    rateInclTax: _toDouble(json['rateInclTax'] ?? json['rate_incl_tax']) ?? 0.0,
    quantity: _toDouble(json['quantity']) ?? 0.0,
    unit: json['unit'] ?? 'Nos',
    discountPercent:
        _toDouble(json['discountPercent'] ?? json['discount_percent']) ?? 0.0,
    gstPercent: _toDouble(json['gstPercent'] ?? json['gst_percent']) ?? 0.0,
    productId: (json['productId'] ?? json['product_id'] ?? '').toString(),
    productType: (json['productType'] ?? json['product_type'] ?? 'stick')
        .toString(),
    boxPieces: (json['boxPieces'] ?? json['box_pieces']) != null
        ? ((json['boxPieces'] ?? json['box_pieces']) as num).toInt()
        : null,
  );

  B2BInvoiceItem copyWith({
    String? description,
    String? hsnCode,
    double? rateInclTax,
    double? quantity,
    String? unit,
    double? discountPercent,
    double? gstPercent,
    String? productId,
    String? productType,
    int? boxPieces,
  }) => B2BInvoiceItem(
    description: description ?? this.description,
    hsnCode: hsnCode ?? this.hsnCode,
    rateInclTax: rateInclTax ?? this.rateInclTax,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    discountPercent: discountPercent ?? this.discountPercent,
    gstPercent: gstPercent ?? this.gstPercent,
    productId: productId ?? this.productId,
    productType: productType ?? this.productType,
    boxPieces: boxPieces ?? this.boxPieces,
  );
}

class B2BInvoice {
  // Status constants for the credit tracking workflow
  static const String statusBilled = 'billed';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusPaid = 'paid';

  static const List<String> allStatuses = [
    statusBilled,
    statusShipped,
    statusDelivered,
    statusPaid,
  ];

  static String statusLabel(String status) {
    switch (status) {
      case statusBilled:
        return 'Billed';
      case statusShipped:
        return 'Shipped';
      case statusDelivered:
        return 'Delivered';
      case statusPaid:
        return 'Paid';
      default:
        return status;
    }
  }

  String id; // Unique local ID
  String invoiceNumber;
  DateTime date;
  String receiverName;
  String receiverAddress;
  String receiverState;
  double globalDiscountPercent; // Overall discount percentage
  String status; // billed | shipped | delivered | paid
  List<B2BInvoiceItem> items;
  DateTime createdAt;

  B2BInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.receiverName,
    required this.receiverAddress,
    this.receiverState = '',
    this.globalDiscountPercent = 0.0,
    this.status = 'billed',
    required this.items,
    required this.createdAt,
  });

  // Totals
  double get totalQuantity =>
      items.fold(0.0, (sum, item) => sum + item.quantity);
  double get totalNetAmount =>
      items.fold(0.0, (sum, item) => sum + item.netAmount);
  double get totalItemDiscount =>
      items.fold(0.0, (sum, item) => sum + item.discountAmount);
  // Global discount computed from percentage on total net amount
  double get globalDiscount => globalDiscountPercent > 0
      ? totalNetAmount * globalDiscountPercent / 100
      : 0.0;
  double get totalDiscount => totalItemDiscount + globalDiscount;
  double get totalTaxableValue =>
      items.fold(0.0, (sum, item) => sum + item.taxableValue);
  double get totalGstAmount =>
      items.fold(0.0, (sum, item) => sum + item.gstAmount);
  double get grandTotal => totalNetAmount - globalDiscount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'date': date.toIso8601String(),
    'receiverName': receiverName,
    'receiverAddress': receiverAddress,
    'receiverState': receiverState,
    'globalDiscountPercent': globalDiscountPercent,
    'globalDiscount': globalDiscount,
    'status': status,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  /// Safely converts a dynamic value (num or String) to double.
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory B2BInvoice.fromJson(Map<String, dynamic> json) {
    final parsedItems =
        (json['items'] as List<dynamic>?)
            ?.map((e) => B2BInvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final parsedDiscountPercent =
        _toDouble(
          json['globalDiscountPercent'] ?? json['global_discount_percent'],
        ) ??
        0.0;
    final parsedDiscountAmount =
        _toDouble(json['globalDiscount'] ?? json['global_discount']) ?? 0.0;

    final totalNetAmount = parsedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.netAmount,
    );

    // Backward compatibility: old invoices may have saved discount amount
    // without saving the percentage. Recover percentage from amount.
    final resolvedDiscountPercent = parsedDiscountPercent > 0
        ? parsedDiscountPercent
        : (parsedDiscountAmount > 0 && totalNetAmount > 0)
        ? (parsedDiscountAmount * 100.0) / totalNetAmount
        : 0.0;

    return B2BInvoice(
      // Accept int from server or String from local storage
      id: json['id']?.toString() ?? '',
      // Accept both camelCase (local) and snake_case (server)
      invoiceNumber: json['invoiceNumber'] ?? json['invoice_number'] ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      receiverName: json['receiverName'] ?? json['receiver_name'] ?? '',
      receiverAddress:
          json['receiverAddress'] ?? json['receiver_address'] ?? '',
      receiverState: json['receiverState'] ?? json['receiver_state'] ?? '',
      globalDiscountPercent: resolvedDiscountPercent,
      status: json['status'] ?? 'billed',
      items: parsedItems,
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  static String encodeList(List<B2BInvoice> invoices) =>
      jsonEncode(invoices.map((e) => e.toJson()).toList());

  static List<B2BInvoice> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => B2BInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
