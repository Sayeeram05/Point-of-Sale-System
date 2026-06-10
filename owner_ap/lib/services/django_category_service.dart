import '../models/category.dart' as models;
import 'base_api_service.dart';
import 'category_service.dart';

/// Django API implementation for CategoryService
/// Connects to your existing Django Category API endpoints
class DjangoCategoryService implements CategoryService {
  static const String _endpoint = '/category';

  @override
  Future<List<models.Category>> getCategories() async {
    try {
      final response = await BaseApiService.get('$_endpoint/');
      
      if (response is List) {
        return (response as List<dynamic>)
            .map((json) => _mapDjangoCategory(json as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        // Handle single category response or error response
        if (response.containsKey('error') || response.containsKey('message')) {
          throw ApiException(response['error']?.toString() ?? response['message']?.toString() ?? 'Unknown error');
        }
        return [_mapDjangoCategory(response)];
      } else {
        throw ApiException('Unexpected response format: ${response.runtimeType}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch categories: ${e.toString()}');
    }
  }

  @override
  Future<models.Category> createCategory(models.CategoryRequest request) async {
    try {
      final djangoData = {
        'Name': request.name,
      };
      
      final response = await BaseApiService.post('/category/create/', djangoData);
      return _mapDjangoCategory(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create category: ${e.toString()}');
    }
  }

  @override
  Future<models.Category> updateCategory(String id, models.CategoryRequest request) async {
    try {
      final djangoData = {
        'Name': request.name,
      };
      
      final response = await BaseApiService.put('/category/$id/update/', djangoData);
      return _mapDjangoCategory(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update category: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await BaseApiService.delete('/category/$id/delete/');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete category: ${e.toString()}');
    }
  }

  /// Map Django Category model to Flutter Category model
  models.Category _mapDjangoCategory(Map<String, dynamic> json) {
    return models.Category(
      id: json['ID']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      icon: _getIconForCategory(json['Name']?.toString() ?? ''),
      productCount: 0, // Will be calculated separately
      createdAt: DateTime.now(), // Django model doesn't have timestamps
      updatedAt: DateTime.now(),
    );
  }

  /// Map category name to appropriate icon
  String _getIconForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('classic')) return 'restaurant';
    if (name.contains('chocolate')) return 'cake';
    if (name.contains('fruit')) return 'apple';
    if (name.contains('premium') || name.contains('special')) return 'star';
    return 'restaurant'; // default
  }
}