import '../models/materials_models.dart';
import 'base_api_service.dart';

/// Handles all HTTP communication for the Materials Tracking feature.
/// Maps directly to the Django Materials app endpoints.
class MaterialsService {
  // ---------------------------------------------------------------------------
  // Raw Material catalog
  // ---------------------------------------------------------------------------

  /// Fetch all active raw materials from the catalog.
  static Future<List<RawMaterial>> getRawMaterials() async {
    final response = await BaseApiService.get('/materials/');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(RawMaterial.fromJson)
          .toList();
    }
    return [];
  }

  /// Create a new raw material in the catalog.
  static Future<RawMaterial> createRawMaterial({
    required String name,
    required String unit,
    required double basePrice,
  }) async {
    final response = await BaseApiService.post('/materials/', {
      'name': name,
      'unit': unit,
      'base_price': basePrice,
      'is_active': true,
    });
    return RawMaterial.fromJson(response);
  }

  /// Update an existing raw material (partial update via PUT with partial=True on backend).
  static Future<RawMaterial> updateRawMaterial({
    required int id,
    required String name,
    required String unit,
    required double basePrice,
  }) async {
    final response = await BaseApiService.put('/materials/$id/', {
      'name': name,
      'unit': unit,
      'base_price': basePrice,
    });
    return RawMaterial.fromJson(response);
  }

  /// Soft-delete a raw material (sets is_active=False on backend).
  static Future<void> deleteRawMaterial(int id) async {
    await BaseApiService.delete('/materials/$id/');
  }

  // ---------------------------------------------------------------------------
  // Purchase Records
  // ---------------------------------------------------------------------------

  /// Fetch the purchase record for a specific date (YYYY-MM-DD).
  /// Returns null if no record exists yet for that date (404).
  static Future<PurchaseRecord?> getPurchaseRecord(String date) async {
    try {
      final response = await BaseApiService.get('/materials/purchases/?date=$date');
      if (response is Map<String, dynamic>) {
        return PurchaseRecord.fromJson(response);
      }
    } catch (e) {
      // 404 = no record for this date yet, which is a valid state
      return null;
    }
    return null;
  }

  /// Fetch the list of dates that have saved records within the last 7 days.
  static Future<List<String>> getLast7DaysDates() async {
    try {
      final response = await BaseApiService.get('/materials/purchases/');
      if (response is Map<String, dynamic>) {
        final dates = response['available_dates'] as List<dynamic>? ?? [];
        return dates.map((d) => d.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Atomically save (create or replace) a purchase record.
  /// Always returns the full, locked record on success.
  static Future<PurchaseRecord> savePurchaseRecord({
    required String targetDate,
    required String notes,
    required List<PurchaseLineItem> items,
  }) async {
    final response = await BaseApiService.post('/materials/purchases/', {
      'target_date': targetDate,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    });
    return PurchaseRecord.fromJson(response);
  }
}
