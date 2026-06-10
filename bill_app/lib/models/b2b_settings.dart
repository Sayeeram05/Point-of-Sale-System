/// Holds the constant business information used in all B2B invoices.
/// Persisted via the Django backend.
class B2BSettings {
  // Supplier / Company fields
  String gstin; // e.g. 32ACIFA8866E1ZB
  String companyName; // e.g. ARAMAIN INTERNATIONAL LLP
  String companyType; // e.g. LLP / Pvt Ltd (printed below name)
  String addressLine1;
  String addressLine2;
  String city;
  String state;
  int stateCode;
  String phone1;
  String phone2;

  // Invoice defaults
  String defaultHsnCode;
  double defaultGstPercent;
  String invoicePrefix; // e.g. "C"
  int nextInvoiceNumber;

  // PDF save path (empty = app documents dir)
  String pdfSavePath;

  // Whether a B2B access password has been set (set by server, read-only on client)
  bool passwordSet;

  B2BSettings({
    this.gstin = '',
    this.companyName = 'ARAMAIN INTERNATIONAL LLP',
    this.companyType = '',
    this.addressLine1 = 'STANDARD DESIGN FACTORY, KINFRA INDUSTRIAL PARK',
    this.addressLine2 = 'STATE - 32, MATTANNUR - 670702, KANNUR KERALA',
    this.city = 'KANNUR',
    this.state = 'Kerala',
    this.stateCode = 32,
    this.phone1 = '04902998281',
    this.phone2 = '9995619281',
    this.defaultHsnCode = '21050000',
    this.defaultGstPercent = 0.0,
    this.invoicePrefix = 'C',
    this.nextInvoiceNumber = 1,
    this.pdfSavePath = '',
    this.passwordSet = false,
  });

  String get nextInvoiceCode =>
      '$invoicePrefix${nextInvoiceNumber.toString().padLeft(3, '0')}';

  Map<String, dynamic> toJson() => {
    'gstin': gstin,
    'companyName': companyName,
    'companyType': companyType,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'stateCode': stateCode,
    'phone1': phone1,
    'phone2': phone2,
    'defaultHsnCode': defaultHsnCode,
    'defaultGstPercent': defaultGstPercent,
    'invoicePrefix': invoicePrefix,
    'nextInvoiceNumber': nextInvoiceNumber,
    'pdfSavePath': pdfSavePath,
  };

  /// Safely converts a dynamic value (num or String) to double.
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Safely converts a dynamic value (num or String) to int.
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory B2BSettings.fromJson(Map<String, dynamic> json) => B2BSettings(
    gstin: json['gstin'] ?? '',
    // Accept both camelCase (legacy local) and snake_case (server)
    companyName:
        json['companyName'] ??
        json['company_name'] ??
        'ARAMAIN INTERNATIONAL LLP',
    companyType: json['companyType'] ?? json['company_type'] ?? '',
    addressLine1:
        json['addressLine1'] ??
        json['address_line1'] ??
        'STANDARD DESIGN FACTORY, KINFRA INDUSTRIAL PARK',
    addressLine2:
        json['addressLine2'] ??
        json['address_line2'] ??
        'STATE - 32, MATTANNUR - 670702, KANNUR KERALA',
    city: json['city'] ?? 'KANNUR',
    state: json['state'] ?? 'Kerala',
    stateCode: _toInt(json['stateCode'] ?? json['state_code']) ?? 32,
    phone1: json['phone1'] ?? '04902998281',
    phone2: json['phone2'] ?? '9995619281',
    defaultHsnCode:
        json['defaultHsnCode'] ?? json['default_hsn_code'] ?? '21050000',
    defaultGstPercent:
        _toDouble(json['defaultGstPercent'] ?? json['default_gst_percent']) ??
        0.0,
    invoicePrefix: json['invoicePrefix'] ?? json['invoice_prefix'] ?? 'C',
    nextInvoiceNumber:
        _toInt(json['nextInvoiceNumber'] ?? json['next_invoice_number']) ?? 1,
    pdfSavePath: json['pdfSavePath'] ?? json['pdf_save_path'] ?? '',
    passwordSet: json['password_set'] ?? json['passwordSet'] ?? false,
  );
}
