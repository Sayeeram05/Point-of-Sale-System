import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/WOFL_constants.dart';
import '../models/WOFL_product_model.dart';
import '../models/WOFL_order_model.dart';
import '../models/WOFL_sales_model.dart';

class WOFLApiService {
  static String _baseUrl = 'http://127.0.0.1:8000';
  static final http.Client _client = http.Client();
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static const Duration _timeout = Duration(seconds: 15);

  static void configure({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  static String get _root => '$_baseUrl/api';

  static String _extractError(http.Response response, String defaultMessage) {
    try {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        final error = body['error'] ?? body['message'];
        if (error != null && error.toString().isNotEmpty) {
          return error.toString();
        }
      }
    } catch (_) {}
    return '$defaultMessage (${response.statusCode})';
  }

  static Future<List<WOFLCategory>> getCategories() async {
    final uri = Uri.parse('$_root/${WOFLConstants.categoryEndpoint}/');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body) as List<dynamic>;
      return jsonBody
          .map((item) => WOFLCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_extractError(response, 'Failed to load categories'));
  }

  static Future<List<WOFLProduct>> getProductsByCategory(
    int categoryId,
  ) async {
    final uri = Uri.parse(
      '$_root/${WOFLConstants.productsEndpoint}/category/$categoryId/',
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body) as List<dynamic>;
      return jsonBody
          .map((item) => WOFLProduct.fromJson(item as Map<String, dynamic>))
          .where((product) => !product.deleted)
          .toList();
    }
    throw Exception(_extractError(response, 'Failed to load products'));
  }

  static Future<List<WOFLProduct>> getAllProducts() async {
    final uri = Uri.parse('$_root/${WOFLConstants.productsEndpoint}/');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body) as List<dynamic>;
      return jsonBody
          .map((item) => WOFLProduct.fromJson(item as Map<String, dynamic>))
          .where((product) => !product.deleted)
          .toList();
    }
    throw Exception(_extractError(response, 'Failed to load products'));
  }

  static Future<WOFLOrder> createOrder() async {
    final uri = Uri.parse('$_root/${WOFLConstants.ordersEndpoint}/create/');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: json.encode({
            'TotalQuantity': 0,
            'UpiAmount': 0,
            'CashAmount': 0,
            'Completed': false,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return WOFLOrder.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractError(response, 'Failed to create order'));
  }

  static Future<WOFLOrder> getOrder(int orderId) async {
    final uri = Uri.parse('$_root/${WOFLConstants.ordersEndpoint}/$orderId/');
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WOFLOrder.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractError(response, 'Failed to load order'));
  }

  static Future<WOFLOrder> updateOrderItems(
    int orderId,
    List<WOFLOrderItem> items,
  ) async {
    final uri = Uri.parse(
      '$_root/${WOFLConstants.ordersEndpoint}/$orderId/update/',
    );
    final body = {
      'TotalQuantity': items.fold<int>(0, (sum, item) => sum + item.quantity),
      'CashAmount': 0,
      'UpiAmount': 0,
      'Completed': false,
      'OrderItems': items.map((item) => item.toJson(orderId)).toList(),
    };
    final response = await _client
        .put(uri, headers: _headers, body: json.encode(body))
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WOFLOrder.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractError(response, 'Failed to update order'));
  }

  static Future<WOFLOrder> completeOrder(
    int orderId, {
    double cash = 0,
    double upi = 0,
  }) async {
    final uri = Uri.parse(
      '$_root/${WOFLConstants.ordersEndpoint}/$orderId/patch/',
    );
    final body = {'Completed': true, 'CashAmount': cash, 'UpiAmount': upi};
    final response = await _client
        .patch(uri, headers: _headers, body: json.encode(body))
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WOFLOrder.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractError(response, 'Failed to complete order'));
  }

  static Future<WOFLOrder> markOrderIncomplete(int orderId) async {
    final uri = Uri.parse(
      '$_root/${WOFLConstants.ordersEndpoint}/$orderId/patch/',
    );
    final body = {'Completed': false, 'CashAmount': 0, 'UpiAmount': 0};
    final response = await _client
        .patch(uri, headers: _headers, body: json.encode(body))
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WOFLOrder.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractError(response, 'Failed to mark order incomplete'));
  }

  static Future<void> deleteOrder(int orderId) async {
    final uri = Uri.parse(
      '$_root/${WOFLConstants.ordersEndpoint}/$orderId/delete/',
    );
    final response = await _client
        .delete(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception(_extractError(response, 'Failed to delete order'));
  }

  static Future<WOFLSalesSummary> getDailySummary({
    String date = 'today',
  }) async {
    final uri = Uri.parse(
      '$_root/${WOFLConstants.ordersEndpoint}/?date=$date',
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WOFLSalesSummary.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractError(response, 'Failed to load WOFL summary'));
  }
}
