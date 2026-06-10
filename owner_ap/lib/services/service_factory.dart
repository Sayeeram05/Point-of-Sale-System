import '../config/app_config.dart';
import 'category_service.dart';
import 'product_service.dart';
import 'django_category_service.dart';
import 'django_product_service.dart';

/// Factory class to create appropriate service instances
/// Switches between mock and real Django API services based on configuration
class ServiceFactory {
  /// Create CategoryService instance
  static CategoryService createCategoryService() {
    if (AppConfig.useMockServices) {
      return MockCategoryService();
    } else {
      return DjangoCategoryService();
    }
  }

  /// Create ProductService instance
  static ProductService createProductService() {
    if (AppConfig.useMockServices) {
      return MockProductService();
    } else {
      return DjangoProductService();
    }
  }
}