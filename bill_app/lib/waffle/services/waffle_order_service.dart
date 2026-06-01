import '../models/waffle_order_model.dart';
import 'waffle_api_service.dart';

class WaffleOrderService {
  Future<WaffleOrder> createOrder() {
    return WaffleApiService.createOrder();
  }

  Future<WaffleOrder> getOrder(int orderId) {
    return WaffleApiService.getOrder(orderId);
  }

  Future<WaffleOrder> updateOrderItems(
    int orderId,
    List<WaffleOrderItem> items,
  ) {
    return WaffleApiService.updateOrderItems(orderId, items);
  }

  Future<WaffleOrder> completeOrder(
    int orderId, {
    required double cash,
    required double upi,
  }) {
    return WaffleApiService.completeOrder(orderId, cash: cash, upi: upi);
  }

  Future<WaffleOrder> markOrderIncomplete(int orderId) {
    return WaffleApiService.markOrderIncomplete(orderId);
  }

  Future<void> deleteOrder(int orderId) {
    return WaffleApiService.deleteOrder(orderId);
  }
}
