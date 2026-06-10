import '../models/models.dart';
import 'base_api_service.dart';

/// Abstract interface for category operations
abstract class CategoryService {
  Future<List<Category>> getCategories();
  Future<Category> createCategory(CategoryRequest request);
  Future<Category> updateCategory(String id, CategoryRequest request);
  Future<void> deleteCategory(String id);
}

/// Implementation of CategoryService using Django REST API
class CategoryServiceImpl implements CategoryService {
  static const String _endpoint = '/categories';

  @override
  Future<List<Category>> getCategories() async {
    try {
      final response = await BaseApiService.get('$_endpoint/');
      
      // Handle both list response and paginated response
      List<dynamic> categoriesJson;
      if (response.containsKey('results')) {
        // Paginated response from Django REST framework
        categoriesJson = response['results'] as List<dynamic>;
      } else if (response is List) {
        // Direct list response
        categoriesJson = response as List<dynamic>;
      } else {
        // Assume the response itself contains the list
        categoriesJson = [];
      }
      
      return categoriesJson
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch categories: ${e.toString()}');
    }
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    try {
      final response = await BaseApiService.post('$_endpoint/', request.toJson());
      return Category.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create category: ${e.toString()}');
    }
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    try {
      final response = await BaseApiService.put('$_endpoint/$id/', request.toJson());
      return Category.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update category: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await BaseApiService.delete('$_endpoint/$id/');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete category: ${e.toString()}');
    }
  }
}

/// Mock implementation for testing and development
class MockCategoryService implements CategoryService {
  static final List<Category> _categories = [
    Category(
      id: '1',
      name: 'Classic Waffles',
      icon: 'restaurant',
      productCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Category(
      id: '2',
      name: 'Chocolate Waffles',
      icon: 'cake',
      productCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Category(
      id: '3',
      name: 'Fruit Waffles',
      icon: 'apple',
      productCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Category(
      id: '4',
      name: 'Premium Specials',
      icon: 'star',
      productCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Category>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_categories);
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      icon: request.icon,
      productCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _categories.add(category);
    return category;
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw ApiException('Category not found');
    }
    
    final updatedCategory = _categories[index].copyWith(
      name: request.name,
      icon: request.icon,
      updatedAt: DateTime.now(),
    );
    
    _categories[index] = updatedCategory;
    return updatedCategory;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw ApiException('Category not found');
    }
    
    _categories.removeAt(index);
  }
}