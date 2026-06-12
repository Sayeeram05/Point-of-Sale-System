import '../services/WOFL_inventory_service.dart';
import '../services/WOFL_order_service.dart';
import '../services/WOFL_sales_service.dart';

class WOFLRepository {
  final WOFLOrderService orderService;
  final WOFLInventoryService inventoryService;
  final WOFLSalesService salesService;

  WOFLRepository({
    WOFLOrderService? orderService,
    WOFLInventoryService? inventoryService,
    WOFLSalesService? salesService,
  }) : orderService = orderService ?? WOFLOrderService(),
       inventoryService = inventoryService ?? WOFLInventoryService(),
       salesService = salesService ?? WOFLSalesService();

  Future<void> initialize() async {
    // Placeholder for repository-level startup tasks if needed.
  }
}
