import 'package:flutter/foundation.dart';
import '../models/waffle_order_model.dart';
import '../models/waffle_product_model.dart';
import '../services/waffle_inventory_service.dart';
import '../services/waffle_order_service.dart';

enum WafflePaymentMode { cash, upi, both }

class WaffleOrderProvider extends ChangeNotifier {
  final WaffleOrderService orderService;
  final WaffleInventoryService inventoryService;

  WaffleOrder? order;
  List<WaffleCategory> categories = [];
  List<WaffleProduct> products = [];
  List<WaffleOrderItem> orderItems = [];
  bool isLoading = true;
  bool isSaving = false;
  String error = '';
  int selectedCategoryId = 0;
  WafflePaymentMode paymentMode = WafflePaymentMode.cash;
  double cashAmount = 0.0;
  double upiAmount = 0.0;

  WaffleOrderProvider({
    WaffleOrderService? orderService,
    WaffleInventoryService? inventoryService,
  }) : orderService = orderService ?? WaffleOrderService(),
       inventoryService = inventoryService ?? WaffleInventoryService();

  Future<void> initialize(int orderId) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      order = await orderService.getOrder(orderId);
      categories = await inventoryService.loadCategories();
      // default to 'All' category (id=0) to show all products
      selectedCategoryId = 0;
      products = await inventoryService.loadProductsForCategory(
        selectedCategoryId,
      );
      orderItems = List<WaffleOrderItem>.from(order?.items ?? []);
      _syncPaymentDefaults();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeCategory(int categoryId) async {
    selectedCategoryId = categoryId;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      products = await inventoryService.loadProductsForCategory(categoryId);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void addProduct(WaffleProduct product) {
    final index = orderItems.indexWhere((item) => item.productId == product.id);
    if (index == -1) {
      orderItems.add(
        WaffleOrderItem(
          id: 0,
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: 1,
        ),
      );
    } else {
      final existing = orderItems[index];
      orderItems[index] = WaffleOrderItem(
        id: existing.id,
        productId: existing.productId,
        productName: existing.productName,
        price: existing.price,
        quantity: existing.quantity + 1,
      );
    }
    notifyListeners();
  }

  void removeProduct(WaffleProduct product) {
    final index = orderItems.indexWhere((item) => item.productId == product.id);
    if (index == -1) return;
    final existing = orderItems[index];
    if (existing.quantity > 1) {
      orderItems[index] = WaffleOrderItem(
        id: existing.id,
        productId: existing.productId,
        productName: existing.productName,
        price: existing.price,
        quantity: existing.quantity - 1,
      );
    } else {
      orderItems.removeAt(index);
    }
    notifyListeners();
  }

  int quantityForProduct(WaffleProduct product) {
    final item = orderItems.firstWhere(
      (item) => item.productId == product.id,
      orElse: () => WaffleOrderItem(
        id: 0,
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  double get totalPrice =>
      orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItemCount =>
      orderItems.fold(0, (sum, item) => sum + item.quantity);

  void setPaymentMode(WafflePaymentMode mode) {
    paymentMode = mode;
    _syncPaymentDefaults();
    notifyListeners();
  }

  void updateCashAmount(String value) {
    cashAmount = double.tryParse(value) ?? 0.0;
    if (paymentMode == WafflePaymentMode.both) {
      upiAmount = (totalPrice - cashAmount).clamp(0, totalPrice);
    }
    notifyListeners();
  }

  void updateUpiAmount(String value) {
    upiAmount = double.tryParse(value) ?? 0.0;
    if (paymentMode == WafflePaymentMode.both) {
      cashAmount = (totalPrice - upiAmount).clamp(0, totalPrice);
    }
    notifyListeners();
  }

  void _syncPaymentDefaults() {
    if (paymentMode == WafflePaymentMode.cash) {
      cashAmount = totalPrice;
      upiAmount = 0.0;
    } else if (paymentMode == WafflePaymentMode.upi) {
      upiAmount = totalPrice;
      cashAmount = 0.0;
    } else {
      cashAmount = 0.0;
      upiAmount = 0.0;
    }
  }

  bool get isPaymentValid {
    if (paymentMode == WafflePaymentMode.both) {
      return (cashAmount + upiAmount).toStringAsFixed(2) ==
          totalPrice.toStringAsFixed(2);
    }
    return (paymentMode == WafflePaymentMode.cash &&
            cashAmount.toStringAsFixed(2) == totalPrice.toStringAsFixed(2)) ||
        (paymentMode == WafflePaymentMode.upi &&
            upiAmount.toStringAsFixed(2) == totalPrice.toStringAsFixed(2));
  }

  Future<void> saveOrder() async {
    if (order == null) return;
    isSaving = true;
    notifyListeners();
    try {
      await orderService.updateOrderItems(order!.id, orderItems);
      order = await orderService.getOrder(order!.id);
    } catch (e) {
      error = e.toString();
    }
    isSaving = false;
    notifyListeners();
  }

  Future<bool> completeOrder() async {
    if (order == null || !isPaymentValid) return false;
    isSaving = true;
    notifyListeners();
    try {
      final completed = await orderService.completeOrder(
        order!.id,
        cash: cashAmount,
        upi: upiAmount,
      );
      order = completed;
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
