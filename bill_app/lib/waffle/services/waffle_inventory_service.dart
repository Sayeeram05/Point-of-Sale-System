import '../models/WOFL_product_model.dart';
import 'WOFL_api_service.dart';

class WOFLInventoryService {
  Future<List<WOFLCategory>> loadCategories() {
    return WOFLApiService.getCategories();
  }

  Future<List<WOFLProduct>> loadProductsForCategory(int categoryId) {
    if (categoryId <= 0) {
      return WOFLApiService.getAllProducts();
    }
    return WOFLApiService.getProductsByCategory(categoryId);
  }
}
