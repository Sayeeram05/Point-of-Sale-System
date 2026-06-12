import '../models/WOFL_order_model.dart';
import 'WOFL_api_service.dart';

class WOFLOrderService {
  Future<WOFLOrder> createOrder() {
    return WOFLApiService.createOrder();
  }

  Future<WOFLOrder> getOrder(int orderId) {
    return WOFLApiService.getOrder(orderId);
  }

  Future<WOFLOrder> updateOrderItems(
    int orderId,
    List<WOFLOrderItem> items,
  ) {
    return WOFLApiService.updateOrderItems(orderId, items);
  }

  Future<WOFLOrder> completeOrder(
    int orderId, {
    required double cash,
    required double upi,
  }) {
    return WOFLApiService.completeOrder(orderId, cash: cash, upi: upi);
  }

  Future<WOFLOrder> markOrderIncomplete(int orderId) {
    return WOFLApiService.markOrderIncomplete(orderId);
  }

  Future<void> deleteOrder(int orderId) {
    return WOFLApiService.deleteOrder(orderId);
  }
}
