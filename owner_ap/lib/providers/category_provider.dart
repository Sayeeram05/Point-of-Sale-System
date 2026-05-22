import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../services/services.dart';

/// Provider for managing category state and operations
class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;
  
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider({CategoryService? categoryService})
      : _categoryService = categoryService ?? ServiceFactory.createCategoryService();

  // Getters
  List<models.Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _categories.isEmpty && !_isLoading;

  /// Load all categories from the service
  Future<void> loadCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final categories = await _categoryService.getCategories();
      _categories = categories;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new category
  Future<bool> createCategory(models.CategoryRequest request) async {
    _clearError();

    try {
      final category = await _categoryService.createCategory(request);
      _categories.add(category);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory(String id, models.CategoryRequest request) async {
    _clearError();

    try {
      final updatedCategory = await _categoryService.updateCategory(id, request);
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String id) async {
    _clearError();

    try {
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get category by ID
  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh categories (reload from service)
  Future<void> refresh() async {
    await loadCategories();
  }

  /// Clear any existing error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}