import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_models.dart';

String get _apiBaseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000/api';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api';
  }

  return 'http://127.0.0.1:8000/api';
}

Uri _endpoint(String path) => Uri.parse('$_apiBaseUrl/$path');

class ApiService {
  static Future<List<CategoryModel>> fetchCategories() async {
    final response = await http.get(_endpoint('category/'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ProductModel>> fetchProducts() async {
    final response = await http.get(_endpoint('products/'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ProductModel>> fetchProductsByCategory(
    int categoryId,
  ) async {
    final response = await http.get(
      _endpoint('products/category/$categoryId/'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load category products: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<OrderModel>> fetchOrders({
    String date = 'today',
    String? startDate,
    String? endDate,
  }) async {
    final queryParameters = <String, String>{};
    if (date.isNotEmpty) queryParameters['date'] = date;
    if (startDate != null) queryParameters['start_date'] = startDate;
    if (endDate != null) queryParameters['end_date'] = endDate;

    final uri = Uri.parse(
      '$_apiBaseUrl/orders/',
    ).replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final orders = data['orders'] as List<dynamic>?;
    if (orders == null) {
      return [];
    }

    return orders
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<OrderModel> createOrder({
    required int totalQuantity,
    required double upiAmount,
    required double cashAmount,
    required bool completed,
  }) async {
    final uri = _endpoint('orders/create/');
    final body = jsonEncode({
      'TotalQuantity': totalQuantity,
      'UpiAmount': upiAmount.toStringAsFixed(2),
      'CashAmount': cashAmount.toStringAsFixed(2),
      'Completed': completed,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create order: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}
