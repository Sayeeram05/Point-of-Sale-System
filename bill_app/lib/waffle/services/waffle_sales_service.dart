import '../models/waffle_sales_model.dart';
import 'waffle_api_service.dart';

class WaffleSalesService {
  Future<WaffleSalesSummary> loadDailySummary({String date = 'today'}) {
    return WaffleApiService.getDailySummary(date: date);
  }
}
