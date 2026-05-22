import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/services.dart';

/// Provider for managing product state and operations
class ProductProvider extends ChangeNotifier {
  final ProductService _productService;
  
  List<Product> _products = [];
  Map<String, List<Product>> _productsByCategory = {};
  bool _isLoading = false;
  String? _error;

  ProductProvider({ProductService? productService})
      : _productService = productService ?? ServiceFactory.createProductService();

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  Map<String, List<Product>> get productsByCategory => Map.unmodifiable(_productsByCategory);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _products.isEmpty && !_isLoading;

  /// Load all products from the service
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final products = await _productService.getProducts();
      _products = products;
      _groupProductsByCategory();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Load products for a specific category
  Future<void> loadProductsByCategory(String categoryId) async {
    _clearError();

    try {
      final products = await _productService.getProductsByCategory(categoryId);
      _productsByCategory[categoryId] = products;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Create a new product
  Future<bool> createProduct(ProductRequest request) async {
    _clearError();

    try {
      final product = await _productService.createProduct(request);
      _products.add(product);
      _groupProductsByCategory();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update an existing product
  Future<bool> updateProduct(String id, ProductRequest request) async {
    _clearError();

    try {
      final updatedProduct = await _productService.updateProduct(id, request);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _groupProductsByCategory();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(String id) async {
    _clearError();

    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _groupProductsByCategory();
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get products for a specific category
  List<Product> getProductsForCategory(String categoryId) {
    return _productsByCategory[categoryId] ?? [];
  }

  /// Get product count for a category
  int getProductCountForCategory(String categoryId) {
    return _productsByCategory[categoryId]?.length ?? 0;
  }

  /// Refresh products (reload from service)
  Future<void> refresh() async {
    await loadProducts();
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

  void _groupProductsByCategory() {
    _productsByCategory.clear();
    for (final product in _products) {
      if (!_productsByCategory.containsKey(product.categoryId)) {
        _productsByCategory[product.categoryId] = [];
      }
      _productsByCategory[product.categoryId]!.add(product);
    }
  }
}