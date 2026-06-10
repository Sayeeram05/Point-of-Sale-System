import '../models/models.dart';
import 'base_api_service.dart';

/// Abstract interface for materials operations
abstract class MaterialsService {
  Future<List<MaterialEntry>> getMaterials({String? date});
  Future<MaterialEntry> createMaterial(MaterialEntryRequest request);
  Future<MaterialEntry> updateMaterial(String id, MaterialEntryRequest request);
  Future<void> deleteMaterial(String id);
  Future<double> getTotal({String? date});
}

/// Implementation of MaterialsService using Django REST API
class MaterialsServiceImpl implements MaterialsService {
  static const String _endpoint = '/materials';

  @override
  Future<List<MaterialEntry>> getMaterials({String? date}) async {
    try {
      final queryParams = date != null ? '?date=$date' : '';
      final response = await BaseApiService.get('$_endpoint/$queryParams');
      
      // Handle the response structure: {entries: [...], count: N, total: X}
      List<dynamic> entriesJson;
      if (response.containsKey('entries')) {
        entriesJson = response['entries'] as List<dynamic>;
      } else if (response is List) {
        entriesJson = response as List<dynamic>;
      } else {
        entriesJson = [];
      }
      
      return entriesJson
          .map((json) => MaterialEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch materials: ${e.toString()}');
    }
  }

  @override
  Future<MaterialEntry> createMaterial(MaterialEntryRequest request) async {
    try {
      final response = await BaseApiService.post('$_endpoint/', request.toJson());
      return MaterialEntry.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create material entry: ${e.toString()}');
    }
  }

  @override
  Future<MaterialEntry> updateMaterial(String id, MaterialEntryRequest request) async {
    try {
      final response = await BaseApiService.put('$_endpoint/$id/', request.toJson());
      return MaterialEntry.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update material entry: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMaterial(String id) async {
    try {
      await BaseApiService.delete('$_endpoint/$id/');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete material entry: ${e.toString()}');
    }
  }

  @override
  Future<double> getTotal({String? date}) async {
    try {
      final queryParams = date != null ? '?date=$date' : '';
      final response = await BaseApiService.get('$_endpoint/total/$queryParams');
      
      if (response.containsKey('total')) {
        return double.tryParse(response['total'].toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch materials total: ${e.toString()}');
    }
  }
}

/// Mock implementation for testing and development
class MockMaterialsService implements MaterialsService {
  static final List<MaterialEntry> _entries = [
    MaterialEntry(
      id: '1',
      entryDate: DateTime.now(),
      rawMaterialProduct: 'Flour (Wheat)',
      price: 450.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MaterialEntry(
      id: '2',
      entryDate: DateTime.now(),
      rawMaterialProduct: 'Butter (500g)',
      price: 280.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MaterialEntry(
      id: '3',
      entryDate: DateTime.now(),
      rawMaterialProduct: 'Eggs (30pcs)',
      price: 180.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    MaterialEntry(
      id: '4',
      entryDate: DateTime.now(),
      rawMaterialProduct: 'Milk (2L)',
      price: 120.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    MaterialEntry(
      id: '5',
      entryDate: DateTime.now().subtract(const Duration(days: 1)),
      rawMaterialProduct: 'Chocolate Syrup',
      price: 250.0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MaterialEntry(
      id: '6',
      entryDate: DateTime.now().subtract(const Duration(days: 1)),
      rawMaterialProduct: 'Strawberries (1kg)',
      price: 350.0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<MaterialEntry>> getMaterials({String? date}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (date == null || date == 'today') {
      final today = DateTime.now();
      return _entries.where((e) => 
        e.entryDate.year == today.year && 
        e.entryDate.month == today.month && 
        e.entryDate.day == today.day
      ).toList();
    }
    
    try {
      final filterDate = DateTime.parse(date);
      return _entries.where((e) => 
        e.entryDate.year == filterDate.year && 
        e.entryDate.month == filterDate.month && 
        e.entryDate.day == filterDate.day
      ).toList();
    } catch (e) {
      return List.from(_entries);
    }
  }

  @override
  Future<MaterialEntry> createMaterial(MaterialEntryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final entry = MaterialEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entryDate: request.entryDate,
      rawMaterialProduct: request.rawMaterialProduct,
      price: request.price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _entries.add(entry);
    return entry;
  }

  @override
  Future<MaterialEntry> updateMaterial(String id, MaterialEntryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw ApiException('Material entry not found');
    }
    
    final updatedEntry = _entries[index].copyWith(
      entryDate: request.entryDate,
      rawMaterialProduct: request.rawMaterialProduct,
      price: request.price,
      updatedAt: DateTime.now(),
    );
    
    _entries[index] = updatedEntry;
    return updatedEntry;
  }

  @override
  Future<void> deleteMaterial(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw ApiException('Material entry not found');
    }
    
    _entries.removeAt(index);
  }

  @override
  Future<double> getTotal({String? date}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final entries = await getMaterials(date: date);
    return entries.fold<double>(0.0, (sum, e) => sum + e.price);
  }
}
