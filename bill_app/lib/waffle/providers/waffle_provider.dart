import 'package:flutter/foundation.dart';
import '../models/WOFL_sales_model.dart';
import '../models/WOFL_order_model.dart';
import '../repositories/WOFL_repository.dart';

class WOFLProvider extends ChangeNotifier {
  final WOFLRepository repository;

  WOFLSalesSummary? summary;
  bool isLoading = false;
  String error = '';
  int selectedTabIndex = 0;

  WOFLProvider({WOFLRepository? repository})
    : repository = repository ?? WOFLRepository();

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      summary = await repository.salesService.loadDailySummary();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  List<WOFLOrder> get allOrders => summary?.orders ?? [];
  List<WOFLOrder> get pendingOrders =>
      summary?.orders.where((order) => !order.completed).toList() ?? [];
  List<WOFLOrder> get completedOrders =>
      summary?.orders.where((order) => order.completed).toList() ?? [];

  List<WOFLOrder> get visibleOrders {
    switch (selectedTabIndex) {
      case 1:
        return pendingOrders;
      case 2:
        return completedOrders;
      default:
        return allOrders;
    }
  }

  void setTab(int index) {
    selectedTabIndex = index;
    notifyListeners();
  }
}
