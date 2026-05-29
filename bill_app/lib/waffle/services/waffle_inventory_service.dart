import '../models/waffle_product_model.dart';
import 'waffle_api_service.dart';

class WaffleInventoryService {
  Future<List<WaffleCategory>> loadCategories() {
    return WaffleApiService.getCategories();
  }

  Future<List<WaffleProduct>> loadProductsForCategory(int categoryId) {
    if (categoryId <= 0) {
      return WaffleApiService.getAllProducts();
    }
    return WaffleApiService.getProductsByCategory(categoryId);
  }
}
