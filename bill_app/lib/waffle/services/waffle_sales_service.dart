import '../models/WOFL_sales_model.dart';
import 'WOFL_api_service.dart';

class WOFLSalesService {
  Future<WOFLSalesSummary> loadDailySummary({String date = 'today'}) {
    return WOFLApiService.getDailySummary(date: date);
  }
}
