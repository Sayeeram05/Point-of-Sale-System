import '../models/product.dart';
import 'base_api_service.dart';
import 'product_service.dart';

/// Django API implementation for ProductService
/// Connects to your existing Django Product API endpoints
class DjangoProductService implements ProductService {
  static const String _endpoint = '/products';

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await BaseApiService.get('$_endpoint/');
      
      if (response is List) {
        return (response as List<dynamic>)
            .map((json) => _mapDjangoProduct(json as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('message')) {
          // No products found
          return [];
        } else if (response.containsKey('error')) {
          throw ApiException(response['error'].toString());
        } else {
          // Handle single product response
          return [_mapDjangoProduct(response)];
        }
      } else {
        throw ApiException('Unexpected response format: ${response.runtimeType}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch products: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await BaseApiService.get('/products/category/$categoryId/');
      
      if (response is List) {
        return (response as List<dynamic>)
            .map((json) => _mapDjangoProduct(json as Map<String, dynamic>))
            .toList();
      } else if (response.containsKey('message')) {
        // No products found for this category
        return [];
      } else {
        // Handle single product response
        return [_mapDjangoProduct(response)];
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch products for category: ${e.toString()}');
    }
  }

  @override
  Future<Product> createProduct(ProductRequest request) async {
    try {
      final djangoData = {
        'Name': request.name,
        'Price': request.price,
        'category': request.categoryId, // Django expects 'category' field
      };
      
      final response = await BaseApiService.post('/products/create/', djangoData);
      return _mapDjangoProduct(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create product: ${e.toString()}');
    }
  }

  @override
  Future<Product> updateProduct(String id, ProductRequest request) async {
    try {
      final djangoData = {
        'Name': request.name,
        'Price': request.price,
        'ProductCategory': request.categoryId, // Django expects 'ProductCategory' for updates
      };
      
      final response = await BaseApiService.put('/products/$id/update/', djangoData);
      return _mapDjangoProduct(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update product: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await BaseApiService.delete('/products/$id/delete/');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete product: ${e.toString()}');
    }
  }

  /// Map Django Product model to Flutter Product model
  Product _mapDjangoProduct(Map<String, dynamic> json) {
    return Product(
      id: json['ID']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      price: _parsePrice(json['Price']),
      categoryId: json['ProductCategory']?.toString() ?? '',
      description: null, // Django model doesn't have description
      imageUrl: null, // Django model doesn't have image
      isAvailable: !(json['Deleted'] ?? false), // Invert Deleted flag
      createdAt: DateTime.now(), // Django model doesn't have timestamps
      updatedAt: DateTime.now(),
    );
  }

  /// Parse price from Django decimal field
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}