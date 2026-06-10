import '../models/material_version.dart';
import 'base_api_service.dart';

/// Abstract interface for material versions operations
abstract class MaterialVersionsService {
  Future<List<MaterialVersion>> getVersions();
  Future<MaterialVersion> getVersion(String id);
  Future<MaterialVersion> getVersionForDate(DateTime date);
  Future<MaterialVersion> createVersion(MaterialVersionRequest request);
  Future<MaterialVersion> updateVersion(String id, MaterialVersionRequest request);
  Future<void> deleteVersion(String id);
  Future<List<AvailableMaterial>> getAvailableMaterials();
}

/// Implementation of MaterialVersionsService using Django REST API
class MaterialVersionsServiceImpl implements MaterialVersionsService {
  static const String _endpoint = '/material-versions';

  @override
  Future<List<MaterialVersion>> getVersions() async {
    try {
      final response = await BaseApiService.get('$_endpoint/');
      
      List<dynamic> versionsJson;
      if (response is List) {
        versionsJson = response as List<dynamic>;
      } else {
        versionsJson = [];
      }
      
      return versionsJson
          .map((json) => MaterialVersion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch material versions: ${e.toString()}');
    }
  }

  @override
  Future<MaterialVersion> getVersion(String id) async {
    try {
      final response = await BaseApiService.get('$_endpoint/$id/');
      return MaterialVersion.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch material version: ${e.toString()}');
    }
  }

  @override
  Future<MaterialVersion> getVersionForDate(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      final response = await BaseApiService.get('$_endpoint/for-date/?date=$dateStr');
      return MaterialVersion.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch material version for date: ${e.toString()}');
    }
  }

  @override
  Future<MaterialVersion> createVersion(MaterialVersionRequest request) async {
    try {
      final response = await BaseApiService.post('$_endpoint/', request.toJson());
      return MaterialVersion.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create material version: ${e.toString()}');
    }
  }

  @override
  Future<MaterialVersion> updateVersion(String id, MaterialVersionRequest request) async {
    try {
      final response = await BaseApiService.put('$_endpoint/$id/', request.toJson());
      return MaterialVersion.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update material version: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteVersion(String id) async {
    try {
      await BaseApiService.delete('$_endpoint/$id/');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete material version: ${e.toString()}');
    }
  }

  @override
  Future<List<AvailableMaterial>> getAvailableMaterials() async {
    try {
      final response = await BaseApiService.get('/materials/available/');
      
      List<dynamic> materialsJson;
      if (response.containsKey('materials')) {
        materialsJson = response['materials'] as List<dynamic>;
      } else if (response is List) {
        materialsJson = response as List<dynamic>;
      } else {
        materialsJson = [];
      }
      
      return materialsJson
          .map((json) => AvailableMaterial.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch available materials: ${e.toString()}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Mock implementation for testing and development
class MockMaterialVersionsService implements MaterialVersionsService {
  static final List<MaterialVersion> _versions = [
    MaterialVersion(
      id: '1',
      name: 'Version 1.0',
      effectiveFromDate: DateTime.now().subtract(const Duration(days: 10)),
      isActive: true,
      materialItems: [
        MaterialVersionItem(
          id: '1',
          materialName: 'Flour (Wheat)',
          price: 450.0,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        MaterialVersionItem(
          id: '2',
          materialName: 'Butter (500g)',
          price: 280.0,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        MaterialVersionItem(
          id: '3',
          materialName: 'Eggs (30pcs)',
          price: 180.0,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    MaterialVersion(
      id: '2',
      name: 'Version 2.0',
      effectiveFromDate: DateTime.now().subtract(const Duration(days: 5)),
      isActive: true,
      materialItems: [
        MaterialVersionItem(
          id: '4',
          materialName: 'Flour (Wheat)',
          price: 480.0,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        MaterialVersionItem(
          id: '5',
          materialName: 'Butter (500g)',
          price: 300.0,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        MaterialVersionItem(
          id: '6',
          materialName: 'Eggs (30pcs)',
          price: 200.0,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        MaterialVersionItem(
          id: '7',
          materialName: 'Milk (2L)',
          price: 120.0,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<AvailableMaterial> _availableMaterials = [
    AvailableMaterial(
      name: 'Flour (Wheat)',
      price: 480.0,
      versionName: 'Version 2.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 5)),
    ),
    AvailableMaterial(
      name: 'Butter (500g)',
      price: 300.0,
      versionName: 'Version 2.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 5)),
    ),
    AvailableMaterial(
      name: 'Eggs (30pcs)',
      price: 200.0,
      versionName: 'Version 2.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 5)),
    ),
    AvailableMaterial(
      name: 'Milk (2L)',
      price: 120.0,
      versionName: 'Version 2.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 5)),
    ),
    AvailableMaterial(
      name: 'Chocolate Syrup',
      price: 250.0,
      versionName: 'Version 1.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 10)),
    ),
    AvailableMaterial(
      name: 'Strawberries (1kg)',
      price: 350.0,
      versionName: 'Version 1.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 10)),
    ),
    AvailableMaterial(
      name: 'Sugar (1kg)',
      price: 80.0,
      versionName: 'Version 1.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 10)),
    ),
    AvailableMaterial(
      name: 'Vanilla Extract',
      price: 150.0,
      versionName: 'Version 1.0',
      effectiveFrom: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  @override
  Future<List<MaterialVersion>> getVersions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_versions);
  }

  @override
  Future<MaterialVersion> getVersion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final version = _versions.where((v) => v.id == id).firstOrNull;
    if (version == null) {
      throw ApiException('Material version not found');
    }
    return version;
  }

  @override
  Future<MaterialVersion> getVersionForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Find the latest version effective on or before the given date
    final effectiveVersions = _versions
        .where((v) => v.effectiveFromDate.isBefore(date) || v.effectiveFromDate.isAtSameMomentAs(date))
        .where((v) => v.isActive)
        .toList();
    
    if (effectiveVersions.isEmpty) {
      throw ApiException('No material version found for the given date');
    }
    
    effectiveVersions.sort((a, b) => b.effectiveFromDate.compareTo(a.effectiveFromDate));
    return effectiveVersions.first;
  }

  @override
  Future<MaterialVersion> createVersion(MaterialVersionRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final version = MaterialVersion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      effectiveFromDate: request.effectiveFromDate,
      isActive: true,
      materialItems: request.materialItems.map((item) => MaterialVersionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_${request.materialItems.indexOf(item)}',
        materialName: item.materialName,
        price: item.price,
        createdAt: DateTime.now(),
      )).toList(),
      createdAt: DateTime.now(),
    );
    
    _versions.add(version);
    return version;
  }

  @override
  Future<MaterialVersion> updateVersion(String id, MaterialVersionRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _versions.indexWhere((v) => v.id == id);
    if (index == -1) {
      throw ApiException('Material version not found');
    }
    
    final updatedVersion = _versions[index].copyWith(
      name: request.name,
      materialItems: request.materialItems.map((item) => MaterialVersionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_${request.materialItems.indexOf(item)}',
        materialName: item.materialName,
        price: item.price,
        createdAt: DateTime.now(),
      )).toList(),
      updatedAt: DateTime.now(),
    );
    
    _versions[index] = updatedVersion;
    return updatedVersion;
  }

  @override
  Future<void> deleteVersion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _versions.indexWhere((v) => v.id == id);
    if (index == -1) {
      throw ApiException('Material version not found');
    }
    
    _versions.removeAt(index);
  }

  @override
  Future<List<AvailableMaterial>> getAvailableMaterials() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_availableMaterials);
  }
}
