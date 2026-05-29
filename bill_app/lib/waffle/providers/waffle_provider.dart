import 'package:flutter/foundation.dart';
import '../models/waffle_sales_model.dart';
import '../models/waffle_order_model.dart';
import '../repositories/waffle_repository.dart';

class WaffleProvider extends ChangeNotifier {
  final WaffleRepository repository;

  WaffleSalesSummary? summary;
  bool isLoading = false;
  String error = '';
  int selectedTabIndex = 0;

  WaffleProvider({WaffleRepository? repository})
    : repository = repository ?? WaffleRepository();

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

  List<WaffleOrder> get allOrders => summary?.orders ?? [];
  List<WaffleOrder> get pendingOrders =>
      summary?.orders.where((order) => !order.completed).toList() ?? [];
  List<WaffleOrder> get completedOrders =>
      summary?.orders.where((order) => order.completed).toList() ?? [];

  List<WaffleOrder> get visibleOrders {
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
