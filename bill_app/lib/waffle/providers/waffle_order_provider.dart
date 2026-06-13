import 'package:flutter/foundation.dart';
import '../models/WOFL_order_model.dart';
import '../models/WOFL_product_model.dart';
import '../services/WOFL_inventory_service.dart';
import '../services/WOFL_order_service.dart';

enum WOFLPaymentMode { cash, upi, both }

class WOFLOrderProvider extends ChangeNotifier {
  final WOFLOrderService orderService;
  final WOFLInventoryService inventoryService;

  WOFLOrder? order;
  List<WOFLCategory> categories = [];
  List<WOFLProduct> products = [];
  List<WOFLOrderItem> orderItems = [];
  bool isLoading = true;
  bool isSaving = false;
  String error = '';
  int selectedCategoryId = 0;
  WOFLPaymentMode paymentMode = WOFLPaymentMode.cash;
  double cashAmount = 0.0;
  double upiAmount = 0.0;

  WOFLOrderProvider({
    WOFLOrderService? orderService,
    WOFLInventoryService? inventoryService,
  }) : orderService = orderService ?? WOFLOrderService(),
       inventoryService = inventoryService ?? WOFLInventoryService();

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
      orderItems = List<WOFLOrderItem>.from(order?.items ?? []);
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

  void addProduct(WOFLProduct product) {
    final index = orderItems.indexWhere((item) => item.productId == product.id);
    if (index == -1) {
      orderItems.add(
        WOFLOrderItem(
          id: 0,
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: 1,
        ),
      );
    } else {
      final existing = orderItems[index];
      orderItems[index] = WOFLOrderItem(
        id: existing.id,
        productId: existing.productId,
        productName: existing.productName,
        price: existing.price,
        quantity: existing.quantity + 1,
      );
    }
    notifyListeners();
  }

  void removeProduct(WOFLProduct product) {
    final index = orderItems.indexWhere((item) => item.productId == product.id);
    if (index == -1) return;
    final existing = orderItems[index];
    if (existing.quantity > 1) {
      orderItems[index] = WOFLOrderItem(
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

  int quantityForProduct(WOFLProduct product) {
    final item = orderItems.firstWhere(
      (item) => item.productId == product.id,
      orElse: () => WOFLOrderItem(
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

  void setPaymentMode(WOFLPaymentMode mode) {
    paymentMode = mode;
    _syncPaymentDefaults();
    notifyListeners();
  }

  void updateCashAmount(String value) {
    cashAmount = double.tryParse(value) ?? 0.0;
    if (paymentMode == WOFLPaymentMode.both) {
      upiAmount = (totalPrice - cashAmount).clamp(0, totalPrice);
    }
    notifyListeners();
  }

  void updateUpiAmount(String value) {
    upiAmount = double.tryParse(value) ?? 0.0;
    if (paymentMode == WOFLPaymentMode.both) {
      cashAmount = (totalPrice - upiAmount).clamp(0, totalPrice);
    }
    notifyListeners();
  }

  void _syncPaymentDefaults() {
    if (paymentMode == WOFLPaymentMode.cash) {
      cashAmount = totalPrice;
      upiAmount = 0.0;
    } else if (paymentMode == WOFLPaymentMode.upi) {
      upiAmount = totalPrice;
      cashAmount = 0.0;
    } else {
      cashAmount = 0.0;
      upiAmount = 0.0;
    }
  }

  bool get isPaymentValid {
    if (paymentMode == WOFLPaymentMode.both) {
      return (cashAmount + upiAmount).toStringAsFixed(2) ==
          totalPrice.toStringAsFixed(2);
    }
    return (paymentMode == WOFLPaymentMode.cash &&
            cashAmount.toStringAsFixed(2) == totalPrice.toStringAsFixed(2)) ||
        (paymentMode == WOFLPaymentMode.upi &&
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
