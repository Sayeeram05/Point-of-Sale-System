import '../models/models.dart';
import 'base_api_service.dart';

/// Abstract interface for product operations
abstract class ProductService {
  Future<List<Product>> getProducts();
  Future<List<Product>> getProductsByCategory(String categoryId);
  Future<Product> createProduct(ProductRequest request);
  Future<Product> updateProduct(String id, ProductRequest request);
  Future<void> deleteProduct(String id);
}

/// Implementation of ProductService using Django REST API
class ProductServiceImpl implements ProductService {
  static const String _endpoint = '/products';

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await BaseApiService.get('$_endpoint/');
      
      // Handle both list response and paginated response
      List<dynamic> productsJson;
      if (response.containsKey('results')) {
        // Paginated response from Django REST framework
        productsJson = response['results'] as List<dynamic>;
      } else if (response is List) {
        // Direct list response
        productsJson = response as List<dynamic>;
      } else {
        // Assume the response itself contains the list
        productsJson = [];
      }
      
      return productsJson
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch products: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await BaseApiService.get('$_endpoint/?category=$categoryId');
      
      List<dynamic> productsJson;
      if (response.containsKey('results')) {
        productsJson = response['results'] as List<dynamic>;
      } else if (response is List) {
        productsJson = response as List<dynamic>;
      } else {
        productsJson = [];
      }
      
      return productsJson
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch products for category: ${e.toString()}');
    }
  }

  @override
  Future<Product> createProduct(ProductRequest request) async {
    try {
      final response = await BaseApiService.post('$_endpoint/', request.toJson());
      return Product.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create product: ${e.toString()}');
    }
  }

  @override
  Future<Product> updateProduct(String id, ProductRequest request) async {
    try {
      final response = await BaseApiService.put('$_endpoint/$id/', request.toJson());
      return Product.fromJson(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update product: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await BaseApiService.delete('$_endpoint/$id/');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete product: ${e.toString()}');
    }
  }
}

/// Mock implementation for testing and development
class MockProductService implements ProductService {
  static final List<Product> _products = [
    // Classic Waffles (category id: 1)
    Product(
      id: '1',
      name: 'Belgian Classic',
      price: 120.0,
      categoryId: '1',
      description: 'Traditional Belgian waffle with crispy exterior and fluffy interior',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: '2',
      name: 'Butter Delight',
      price: 100.0,
      categoryId: '1',
      description: 'Classic waffle with rich butter flavor',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Product(
      id: '3',
      name: 'Honey Crisp',
      price: 110.0,
      categoryId: '1',
      description: 'Golden waffle drizzled with natural honey',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    
    // Chocolate Waffles (category id: 2)
    Product(
      id: '4',
      name: 'Choco Lava',
      price: 180.0,
      categoryId: '2',
      description: 'Decadent chocolate waffle with molten chocolate center',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: '5',
      name: 'Dark Chocolate Supreme',
      price: 200.0,
      categoryId: '2',
      description: 'Rich dark chocolate waffle for chocolate lovers',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    
    // Fruit Waffles (category id: 3)
    Product(
      id: '6',
      name: 'Strawberry Cream',
      price: 160.0,
      categoryId: '3',
      description: 'Fresh strawberries with whipped cream on golden waffle',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: '7',
      name: 'Mixed Berry Bliss',
      price: 170.0,
      categoryId: '3',
      description: 'Assorted berries with vanilla cream',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    
    // Premium Specials (category id: 4)
    Product(
      id: '8',
      name: 'Caramel Pecan Royale',
      price: 250.0,
      categoryId: '4',
      description: 'Premium waffle with caramel sauce and toasted pecans',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Product>> getProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_products);
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<Product> createProduct(ProductRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      price: request.price,
      categoryId: request.categoryId,
      description: request.description,
      imageUrl: request.imageUrl,
      isAvailable: request.isAvailable,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _products.add(product);
    return product;
  }

  @override
  Future<Product> updateProduct(String id, ProductRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw ApiException('Product not found');
    }
    
    final updatedProduct = _products[index].copyWith(
      name: request.name,
      price: request.price,
      categoryId: request.categoryId,
      description: request.description,
      imageUrl: request.imageUrl,
      isAvailable: request.isAvailable,
      updatedAt: DateTime.now(),
    );
    
    _products[index] = updatedProduct;
    return updatedProduct;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw ApiException('Product not found');
    }
    
    _products.removeAt(index);
  }
}