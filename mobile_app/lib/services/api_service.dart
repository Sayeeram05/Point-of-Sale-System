import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/menu.dart';
import '../models/user_preferences.dart';
import 'debug_service.dart';

/// Simple TTL cache for API responses that rarely change mid-session.
class _ApiCache {
  static final Map<String, _CacheEntry> _store = {};

  static T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
  }

  static void set(String key, dynamic value, Duration ttl) {
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  static void invalidate(String key) => _store.remove(key);

  static void invalidateAll() => _store.clear();
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiry;
  _CacheEntry(this.value, this.expiry);
}

class ApiService {
  /// Base URL for the backend. Override via [configure] before first use.
  static String _baseUrl = 'http://127.0.0.1:8000';
  static String get baseUrl => _baseUrl;

  /// Call once at app startup to set the backend URL.
  static void configure({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  // Persistent HTTP client Ã¢â‚¬â€ reuses TCP connections (keep-alive)
  static final http.Client _client = http.Client();

  // Common headers for all requests Ã¢â‚¬â€ single const allocation
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout duration for API calls
  static const Duration _timeout = Duration(seconds: 15);

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'] ?? decoded['message'];
        if (error != null && error.toString().trim().isNotEmpty) {
          return error.toString();
        }
      }
    } catch (_) {
      // ignore parsing issues and fall back to default message
    }
    return '$fallback: ${response.statusCode}';
  }

  // Cache durations
  static const Duration _menuCacheTtl = Duration(minutes: 5);
  static const Duration _emojiColorCacheTtl = Duration(minutes: 5);
  static const Duration _dailySummaryCacheTtl = Duration(seconds: 30);

  /// Invalidate all caches (call when data is known to have changed)
  static void invalidateCache() => _ApiCache.invalidateAll();
  static Future<Order> updateOrderAppearance(
    int orderId, {
    required String emoji,
    required String color,
  }) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/api/orders/$orderId/patch/'),
            headers: _headers,
            body: json.encode({'emoji': emoji, 'color': color}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        throw Exception(
          'Failed to update order appearance: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating order appearance: $e');
    }
  }

  static Uri _buildOrdersUri(String date) {
    return Uri.parse('$baseUrl/api/orders/today/');
  }

  static Future<DailySummary> getDailySummary(
    String date, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daily_summary_$date';
    if (!forceRefresh) {
      final cached = _ApiCache.get<DailySummary>(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final uri = _buildOrdersUri(date);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = DailySummary.fromJson(data);
        _ApiCache.set(cacheKey, summary, _dailySummaryCacheTtl);
        return summary;
      } else {
        throw Exception('Failed to load daily summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching daily summary: $e');
    }
  }

  /// Fetch a single order by ID (lightweight alternative to getDailySummary).
  static Future<Order> getOrderById(int orderId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/orders/$orderId/'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching order $orderId: $e');
    }
  }

  static Future<Order> createOrder() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/api/orders/create/'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  static Future<bool> deleteOrder(int orderId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/orders/$orderId/delete/'),
            headers: _headers,
          )
          .timeout(_timeout);

      final ok = response.statusCode == 200 || response.statusCode == 204;
      if (ok) _ApiCache.invalidate('menu'); // Stock freed — bust menu cache
      return ok;
    } catch (e) {
      throw Exception('Error deleting order: $e');
    }
  }

  static Future<Order> markOrderComplete(
    int orderId, {
    double? upiAmount,
    double? cashAmount,
  }) async {
    try {
      final Map<String, dynamic> body = {'Completed': true};
      if (upiAmount != null) body['UpiAmount'] = upiAmount.toStringAsFixed(2);
      if (cashAmount != null) body['CashAmount'] = cashAmount.toStringAsFixed(2);

      final response = await _client
          .patch(
            Uri.parse('$baseUrl/api/orders/$orderId/patch/'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock changed — bust menu cache
        return Order.fromJson(data);
      } else {
        throw Exception(
          'Failed to mark order complete: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error marking order complete: $e');
    }
  }

  static Future<Order> updateOrderWithItems(
    int orderId, {
    required int totalQuantity,
    required List<Map<String, dynamic>> orderItems,
    required double upiAmount,
    required double cashAmount,
    bool completed = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'TotalQuantity': totalQuantity,
        'UpiAmount': upiAmount.toStringAsFixed(2),
        'CashAmount': cashAmount.toStringAsFixed(2),
        'Completed': completed,
        'OrderItems': orderItems,
      };

      final response = await _client
          .put(
            Uri.parse('$baseUrl/api/orders/$orderId/update/'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu');
        return Order.fromJson(data);
      } else {
        throw Exception(
          'Failed to update order: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating order: $e');
    }
  }

  static Future<Order> markOrderIncomplete(int orderId) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/api/orders/$orderId/patch/'),
            headers: _headers,
            body: json.encode({'Completed': false}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock changed — bust menu cache
        return Order.fromJson(data);
      } else {
        throw Exception(
          'Failed to mark order incomplete: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error marking order incomplete: $e');
    }
  }

  // Menu API endpoints Ã¢â‚¬â€ cached for 5 minutes
  static Future<Menu> getMenu({
    bool forceRefresh = false,
    int? excludeOrder,
  }) async {
    if (!forceRefresh) {
      final cached = _ApiCache.get<Menu>('menu');
      if (cached != null) return cached;
    }
    try {
      final uri = excludeOrder != null
          ? Uri.parse('$baseUrl/api/products/menu?exclude_order=$excludeOrder')
          : Uri.parse('$baseUrl/api/products/menu');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final menu = Menu.fromJson(data);
        _ApiCache.set('menu', menu, _menuCacheTtl);
        return menu;
      } else if (response.statusCode == 404) {
        // No menu items available Ã¢â‚¬â€ return empty menu instead of throwing
        return Menu(iceSticks: {}, products: []);
      } else {
        throw Exception('Failed to load menu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching menu: $e');
    }
  }

  // Order Item API endpoints
  static Future<OrderItem> addProductToOrder(
    int orderId,
    String productId,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/sales/orderitem/$orderId/'),
            headers: _headers,
            body: json.encode({
              'product_id': productId,
              'product-type': 'ice-sticks',
            }),
          )
          .timeout(_timeout);

      DebugService.logApi('Response Status: ${response.statusCode}');
      DebugService.logApi('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Debug print to verify order_item_id
        if (data['order_item_id'] != null) {
          DebugService.logApi('order_item_id: \'${data['order_item_id']}\'');
        }
        _ApiCache.invalidate('menu'); // Stock reserved — bust menu cache
        return OrderItem.fromJson(data);
      } else {
        throw Exception(
          _extractErrorMessage(response, 'Failed to add product to order'),
        );
      }
    } catch (e) {
      DebugService.logApi('Error: $e');
      throw Exception('Error adding product to order: $e');
    }
  }

  // Tub-related API methods removed: app now supports only ice sticks.

  static Future<OrderItem> increaseOrderItemQuantity(int itemId) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/orderitem/update/$itemId/inc/'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock reserved — bust menu cache
        return OrderItem.fromJson(data);
      } else {
        DebugService.logApi(
          'Failed to increase quantity: ${response.statusCode} ${response.body}',
        );
        throw Exception(
          _extractErrorMessage(response, 'Failed to increase quantity'),
        );
      }
    } catch (e) {
      DebugService.logApi('Error increasing quantity: $e');
      throw Exception('Error increasing quantity: $e');
    }
  }

  static Future<OrderItem?> decreaseOrderItemQuantity(int itemId) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/orderitem/update/$itemId/dec/'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock freed — bust menu cache
        // If the response contains a message and total_order_price, item was deleted
        if (data is Map<String, dynamic> &&
            data.containsKey('message') &&
            data.containsKey('total_order_price')) {
          // Optionally, you can return null or a custom result
          return null;
        }
        return OrderItem.fromJson(data);
      } else if (response.statusCode == 204) {
        // Item was deleted (quantity reached 0)
        _ApiCache.invalidate('menu'); // Stock freed — bust menu cache
        return null;
      } else {
        throw Exception('Failed to decrease quantity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error decreasing quantity: $e');
    }
  }

  // User preferences API endpoints Ã¢â‚¬â€ cached for 5 minutes
  static Future<List<UserEmoji>> getEmojis() async {
    final cached = _ApiCache.get<List<UserEmoji>>('emojis');
    if (cached != null) return cached;
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/emoji/'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final emojis = data.map((emoji) => UserEmoji.fromJson(emoji)).toList();
        _ApiCache.set('emojis', emojis, _emojiColorCacheTtl);
        return emojis;
      } else {
        throw Exception('Failed to load emojis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching emojis: $e');
    }
  }

  static Future<UserEmoji> addEmoji(String emojiText) async {
    _ApiCache.invalidate('emojis'); // bust cache on mutation
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/emoji/'),
            headers: _headers,
            body: json.encode({
              'Emoji': emojiText,
              'emoji_text': emojiText,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return UserEmoji.fromJson(data);
      } else {
        throw Exception('Failed to add emoji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding emoji: $e');
    }
  }

  static Future<bool> deleteEmoji(int emojiId) async {
    _ApiCache.invalidate('emojis'); // bust cache on mutation
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/emoji/$emojiId/delete/'),
            headers: _headers,
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting emoji: $e');
    }
  }

  static Future<List<UserColor>> getColors() async {
    final cached = _ApiCache.get<List<UserColor>>('colors');
    if (cached != null) return cached;
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/color/'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final colors = data.map((color) => UserColor.fromJson(color)).toList();
        _ApiCache.set('colors', colors, _emojiColorCacheTtl);
        return colors;
      } else {
        throw Exception('Failed to load colors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching colors: $e');
    }
  }

  static Future<UserColor> addColor(String colorHex) async {
    _ApiCache.invalidate('colors'); // bust cache on mutation
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/color/'),
            headers: _headers,
            body: json.encode({
              'HexCode': colorHex,
              'color': colorHex,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return UserColor.fromJson(data);
      } else {
        throw Exception('Failed to add color: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding color: $e');
    }
  }

  static Future<bool> deleteColor(int colorId) async {
    _ApiCache.invalidate('colors'); // bust cache on mutation
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/color/$colorId/delete/'),
            headers: _headers,
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting color: $e');
    }
  }

  // Scoop-related API methods removed: app now supports only ice sticks.

  // deleteScoopOrderItem removed — scoops are not supported.

  // B2B API endpoints removed

}