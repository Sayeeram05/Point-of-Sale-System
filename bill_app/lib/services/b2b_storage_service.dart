import 'package:flutter/foundation.dart';
import '../models/b2b_invoice.dart';
import '../models/b2b_settings.dart';
import '../models/b2b_product_override.dart';
import '../models/menu.dart' show TubCategory;
import 'api_service.dart';

/// All B2B data is now persisted on the Django backend.
/// This service acts as the single abstraction layer — callers (pages) are
/// unchanged because all public method signatures are identical to the old
/// SharedPreferences-based version.
class B2BStorageService {
  // ─── Settings ─────────────────────────────────────────────────────────────

  static Future<B2BSettings> loadSettings() async {
    try {
      final data = await ApiService.getB2BSettings();
      return B2BSettings.fromJson(data);
    } catch (e) {
      debugPrint('[B2B] loadSettings error: $e');
      return B2BSettings();
    }
  }

  static Future<void> saveSettings(B2BSettings settings) async {
    await ApiService.saveB2BSettings({
      'gstin': settings.gstin,
      'company_name': settings.companyName,
      'company_type': settings.companyType,
      'address_line1': settings.addressLine1,
      'address_line2': settings.addressLine2,
      'city': settings.city,
      'state': settings.state,
      'state_code': settings.stateCode,
      'phone1': settings.phone1,
      'phone2': settings.phone2,
      'default_hsn_code': settings.defaultHsnCode,
      'default_gst_percent': settings.defaultGstPercent,
      'invoice_prefix': settings.invoicePrefix,
      'next_invoice_number': settings.nextInvoiceNumber,
      'pdf_save_path': settings.pdfSavePath,
    });
  }

  // ─── Invoices ─────────────────────────────────────────────────────────────

  static Future<List<B2BInvoice>> loadInvoices() async {
    try {
      final list = await ApiService.getB2BInvoices();
      return list
          .map((e) => B2BInvoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[B2B] loadInvoices error: $e');
      rethrow;
    }
  }

  /// Creates or updates an invoice. Returns the updated list.
  static Future<List<B2BInvoice>> saveInvoice(B2BInvoice invoice) async {
    final payload = _invoiceToPayload(invoice);

    // Real-time shared-stock validation (tubs + scoops) before mutating data.
    await ApiService.validateB2BInvoiceStock(payload);

    final isNew = invoice.id.isEmpty || invoice.id == '0';
    if (isNew) {
      await ApiService.createB2BInvoice(payload);
    } else {
      await ApiService.updateB2BInvoice(int.parse(invoice.id), payload);
    }
    return loadInvoices();
  }

  static Future<List<B2BInvoice>> deleteInvoice(String id) async {
    await ApiService.deleteB2BInvoice(int.parse(id));
    return loadInvoices();
  }

  /// Updates only the status of an invoice on the backend.
  static Future<void> updateInvoiceStatus(String id, String status) async {
    await ApiService.updateB2BInvoiceStatus(int.parse(id), status);
  }

  /// Calls the backend to atomically get + increment the invoice number.
  /// The [settings] parameter is kept for API compatibility but is no longer
  /// mutated locally — the backend owns the counter.
  static Future<String> consumeNextInvoiceNumber(B2BSettings settings) async {
    return ApiService.consumeNextInvoiceNumber();
  }

  /// No longer needed (server assigns integer PKs), but kept for compatibility.
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  // ─── Product Catalog (B2B rate overrides) ────────────────────────────────

  static Future<List<B2BProductOverride>> loadCatalog() async {
    try {
      final list = await ApiService.getB2BCatalog();
      return list
          .map((e) => B2BProductOverride.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[B2B] loadCatalog error: $e');
      return [];
    }
  }

  static Future<void> saveCatalog(List<B2BProductOverride> catalog) async {
    await ApiService.saveB2BCatalog(
      catalog.map((e) => _catalogToPayload(e)).toList(),
    );
  }

  /// Merges fresh stick & tub product lists from the API with server-stored
  /// overrides. New products are upserted; existing overrides are preserved.
  static Future<List<B2BProductOverride>> mergeWithApiProducts(
    List<({String productId, String name, String price})> stickProducts, {
    List<TubCategory> tubCategories = const [],
  }) async {
    final existing = await loadCatalog();
    final existingMap = {for (final e in existing) e.productId: e};

    final merged = <B2BProductOverride>[];

    // ── Sticks ────────────────────────────────────────────────────────────
    for (final p in stickProducts) {
      if (existingMap.containsKey(p.productId)) {
        final e = existingMap[p.productId]!;
        merged.add(
          B2BProductOverride(
            productId: e.productId,
            productName: p.name,
            b2cPrice: p.price,
            productType: 'stick',
            b2bRateInclTax: e.b2bRateInclTax,
            hsnCode: e.hsnCode,
            gstPercent: e.gstPercent,
            enabled: e.enabled,
          ),
        );
      } else {
        merged.add(
          B2BProductOverride(
            productId: p.productId,
            productName: p.name,
            b2cPrice: p.price,
            productType: 'stick',
          ),
        );
      }
    }

    // ── Tubs ──────────────────────────────────────────────────────────────
    for (final cat in tubCategories) {
      final catDisplayName = cat.quantityInMl.isNotEmpty
          ? '${cat.name} - ${cat.quantityInMl} ml'
          : cat.name;
      for (final prod in cat.products) {
        final compositeId = 'tub_${cat.tubCategoryId}_${prod.tubProductId}';
        if (existingMap.containsKey(compositeId)) {
          final e = existingMap[compositeId]!;
          merged.add(
            B2BProductOverride(
              productId: compositeId,
              productName: prod.name,
              b2cPrice: prod.price,
              productType: 'tub',
              categoryName: catDisplayName,
              b2bRateInclTax: e.b2bRateInclTax,
              hsnCode: e.hsnCode,
              gstPercent: e.gstPercent,
              enabled: e.enabled,
            ),
          );
        } else {
          merged.add(
            B2BProductOverride(
              productId: compositeId,
              productName: prod.name,
              b2cPrice: prod.price,
              productType: 'tub',
              categoryName: catDisplayName,
            ),
          );
        }
      }
    }

    await saveCatalog(merged);
    return merged;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static Map<String, dynamic> _invoiceToPayload(B2BInvoice invoice) => {
    'invoice_number': invoice.invoiceNumber,
    'date': invoice.date.toIso8601String().split('T').first,
    'receiver_name': invoice.receiverName,
    'receiver_address': invoice.receiverAddress,
    'receiver_state': invoice.receiverState,
    'global_discount_percent': invoice.globalDiscountPercent,
    'global_discount': invoice.globalDiscount,
    'status': invoice.status,
    'items': invoice.items
        .map(
          (item) => {
            'description': item.description,
            'hsn_code': item.hsnCode,
            'rate_incl_tax': item.rateInclTax,
            'quantity': item.quantity,
            'unit': item.unit,
            'discount_percent': item.discountPercent,
            'discount_amount': item.discountAmount,
            'gst_percent': item.gstPercent,
            'product_id': item.productId,
            'product_type': item.productType,
            if (item.boxPieces != null) 'box_pieces': item.boxPieces,
          },
        )
        .toList(),
  };

  static Map<String, dynamic> _catalogToPayload(B2BProductOverride e) => {
    'product_id': e.productId,
    'product_name': e.productName,
    'b2c_price': e.b2cPrice,
    'product_type': e.productType,
    'category_name': e.categoryName ?? '',
    if (e.b2bRateInclTax != null) 'b2b_rate_incl_tax': e.b2bRateInclTax,
    if (e.hsnCode != null) 'hsn_code': e.hsnCode,
    if (e.gstPercent != null) 'gst_percent': e.gstPercent,
    'enabled': e.enabled,
  };
}
