import '../services/waffle_inventory_service.dart';
import '../services/waffle_order_service.dart';
import '../services/waffle_sales_service.dart';

class WaffleRepository {
  final WaffleOrderService orderService;
  final WaffleInventoryService inventoryService;
  final WaffleSalesService salesService;

  WaffleRepository({
    WaffleOrderService? orderService,
    WaffleInventoryService? inventoryService,
    WaffleSalesService? salesService,
  }) : orderService = orderService ?? WaffleOrderService(),
       inventoryService = inventoryService ?? WaffleInventoryService(),
       salesService = salesService ?? WaffleSalesService();

  Future<void> initialize() async {
    // Placeholder for repository-level startup tasks if needed.
  }
}
