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
            Uri.parse('$baseUrl/sales/order/emoji-color/$orderId/'),
            headers: _headers,
            body: json.encode({'emoji_id': emoji, 'color_id': color}),
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

  // Sales API endpoints
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
      final response = await _client
          .get(
            Uri.parse('$baseUrl/sales/order/$date/$date/'),
            headers: _headers,
          )
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
            Uri.parse('$baseUrl/sales/order/$orderId/detail/'),
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
          .post(Uri.parse('$baseUrl/sales/order/'), headers: _headers)
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
            Uri.parse('$baseUrl/sales/order/delete/$orderId/'),
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
      final Map<String, dynamic> body = {};
      if (upiAmount != null) body['upi_amount'] = upiAmount;
      if (cashAmount != null) body['cash_amount'] = cashAmount;

      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/order/complete/$orderId/1/'),
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

  static Future<Order> markOrderIncomplete(int orderId) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/order/complete/$orderId/0/'),
            headers: _headers,
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
          ? Uri.parse('$baseUrl/sales/menu/?exclude_order=$excludeOrder')
          : Uri.parse('$baseUrl/sales/menu/');
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

  // Tub Product API endpoints - using proper tub_product_id
  static Future<OrderItem> addTubProductToOrder(
    int orderId,
    String tubProductId,
    String categoryId,
  ) async {
    DebugService.logTub(
      'Adding tub product with product_id: $tubProductId (product-type: tubs) and category_id: $categoryId to order: $orderId',
    );
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/sales/orderitem/$orderId/'),
            headers: _headers,
            body: json.encode({
              'product_id': tubProductId,
              'product-type': 'tubs',
              'category_id': categoryId,
            }),
          )
          .timeout(_timeout);

      DebugService.logTub('Response Status: ${response.statusCode}');
      DebugService.logTub('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock reserved — bust menu cache

        // Check if this is an "incremented existing item" response
        if (data.containsKey('message') &&
            data['message'] == 'Order item pieces increased') {
          // The item already exists and was incremented
          DebugService.logApi('Tub product already exists, was incremented');
          // Return a special marker indicating this was an increment, not a new item
          return OrderItem(
            itemId: -1, // Special marker to indicate "incremented existing"
            orderItemId: -1,
            product: tubProductId,
            price: '0',
            pieces: 1,
          );
        } else if (data.containsKey('message') &&
            data['message'] == 'Product Added') {
          // This is a new product added, but API doesn't return proper data
          DebugService.logApi('Tub product was newly created');
          // Return a special marker indicating this was a new item creation
          return OrderItem(
            itemId: -2, // Special marker to indicate "new item created"
            orderItemId: -2,
            product: tubProductId,
            price: '0',
            pieces: 1,
          );
        } else {
          // For other response types, use the proper response data
          if (data['order_item_id'] != null) {
            DebugService.logApi(
              'TUB API order_item_id: \'${data['order_item_id']}\'',
            );
          }
          return OrderItem.fromJson(data);
        }
      } else if (response.statusCode == 400) {
        // Handle backend TubProduct price attribute error by retrying
        final data = json.decode(response.body);
        if (data['error'] != null &&
            data['error'].toString().contains('price')) {
          DebugService.logApi(
            'TUB API: Backend price error detected, retrying in 1 second...',
          );
          await Future.delayed(const Duration(seconds: 1));

          // Retry the same request
          final retryResponse = await _client.post(
            Uri.parse('$baseUrl/sales/orderitem/$orderId/'),
            headers: _headers,
            body: json.encode({
              'product_id': tubProductId,
              'product-type': 'tubs',
              'category_id': categoryId,
            }),
          );

          DebugService.logApi('');
          DebugService.logApi('');

          if (retryResponse.statusCode == 200 ||
              retryResponse.statusCode == 201) {
            final retryData = json.decode(retryResponse.body);

            if (retryData.containsKey('message') &&
                retryData['message'] == 'Order item pieces increased') {
              DebugService.logApi('');
              return OrderItem(
                itemId: int.tryParse(tubProductId) ?? 0,
                orderItemId: int.tryParse(tubProductId) ?? 0,
                product: tubProductId,
                price: '0',
                pieces: 1,
              );
            } else {
              if (retryData['order_item_id'] != null) {
                DebugService.logApi(
                  'TUB API Retry order_item_id: ${retryData['order_item_id']}',
                );
              }
              return OrderItem.fromJson(retryData);
            }
          } else {
            throw Exception(
              'Failed to add tub product to order after retry: ${retryResponse.statusCode}',
            );
          }
        } else {
          throw Exception(
            _extractErrorMessage(
              response,
              'Failed to add tub product to order',
            ),
          );
        }
      } else {
        throw Exception(
          _extractErrorMessage(response, 'Failed to add tub product to order'),
        );
      }
    } catch (e) {
      DebugService.logApi('');
      throw Exception('Error adding tub product to order: $e');
    }
  }

  static Future<OrderItem> increaseTubOrderItemQuantity(int tubItemId) async {
    DebugService.logApi('');
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/orderitem/update/$tubItemId/inc/'),
            headers: _headers,
          )
          .timeout(_timeout);

      DebugService.logApi('');
      DebugService.logApi('');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock reserved — bust menu cache

        // Check if response contains just a message (typical for increment operations)
        if (data.containsKey('message') &&
            data['message'] == 'Order item updated successfully') {
          // API only returns success message, not the updated item data
          // Return a special marker to indicate successful increment without data
          DebugService.logApi('');
          return OrderItem(
            itemId: tubItemId,
            orderItemId: tubItemId,
            product: 'UPDATED',
            price: '0',
            pieces: -99, // Special marker to indicate refresh needed
          );
        } else {
          // API returned actual item data
          return OrderItem.fromJson(data);
        }
      } else {
        DebugService.logApi(
          'Failed to increase tub quantity: ${response.statusCode} ${response.body}',
        );
        throw Exception(
          _extractErrorMessage(response, 'Failed to increase tub quantity'),
        );
      }
    } catch (e) {
      DebugService.logApi('Error increasing tub quantity: $e');
      throw Exception('Error increasing tub quantity: $e');
    }
  }

  static Future<OrderItem?> decreaseTubOrderItemQuantity(int tubItemId) async {
    DebugService.logApi('');
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/orderitem/update/$tubItemId/dec/'),
            headers: _headers,
          )
          .timeout(_timeout);

      DebugService.logApi('');
      DebugService.logApi('');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ApiCache.invalidate('menu'); // Stock freed — bust menu cache

        // If the response contains a message and total_order_price, item was deleted
        if (data is Map<String, dynamic> &&
            data.containsKey('message') &&
            data.containsKey('total_order_price')) {
          DebugService.logApi('');
          return null;
        }

        // Check if response contains just a message (typical for decrement operations)
        if (data.containsKey('message') &&
            data['message'] == 'Order item updated successfully') {
          // API only returns success message, not the updated item data
          // Return a special marker to indicate successful decrement without data
          DebugService.logApi('');
          return OrderItem(
            itemId: tubItemId,
            orderItemId: tubItemId,
            product: 'UPDATED',
            price: '0',
            pieces: -99, // Special marker to indicate refresh needed
          );
        } else {
          // API returned actual item data
          return OrderItem.fromJson(data);
        }
      } else if (response.statusCode == 204) {
        // Item was deleted (quantity reached 0)
        _ApiCache.invalidate('menu'); // Stock freed — bust menu cache
        DebugService.logApi('');
        return null;
      } else {
        throw Exception(
          'Failed to decrease tub quantity: ${response.statusCode}',
        );
      }
    } catch (e) {
      DebugService.logApi('');
      throw Exception('Error decreasing tub quantity: $e');
    }
  }

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
          .get(Uri.parse('$baseUrl/user/emojis/'), headers: _headers)
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
            Uri.parse('$baseUrl/user/emojis/'),
            headers: _headers,
            body: json.encode({'emoji_text': emojiText}),
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
            Uri.parse('$baseUrl/user/emojis/$emojiId/'),
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
          .get(Uri.parse('$baseUrl/user/colors/'), headers: _headers)
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
            Uri.parse('$baseUrl/user/colors/'),
            headers: _headers,
            body: json.encode({'color': colorHex}),
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
            Uri.parse('$baseUrl/user/colors/$colorId/'),
            headers: _headers,
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting color: $e');
    }
  }

  // Scoop-related API methods
  static Future<OrderItem> addScoopToOrder(
    int orderId,
    String scoopPriceId, {
    String? categoryId,
  }) async {
    DebugService.logOrder(
      'Adding scoop with scoop_price_id: $scoopPriceId, category_id: $categoryId to order: $orderId',
    );
    try {
      final body = {'scoop_price_id': scoopPriceId, 'product-type': 'scoops'};
      if (categoryId != null) {
        body['category_id'] = categoryId;
      }

      final response = await _client
          .post(
            Uri.parse('$baseUrl/sales/orderitem/$orderId/'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      DebugService.logOrder('Scoop Response Status: ${response.statusCode}');
      DebugService.logOrder('Scoop Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data.containsKey('message') &&
            data['message'] == 'Order item pieces increased') {
          DebugService.logOrder('Scoop already exists, was incremented');
          return OrderItem(
            itemId: -1,
            orderItemId: -1,
            product: 'scoop_$scoopPriceId',
            price: '0',
            pieces: 1,
          );
        } else if (data.containsKey('message') &&
            data['message'] == 'Product Added') {
          DebugService.logOrder('Scoop was newly created');
          return OrderItem(
            itemId: -2,
            orderItemId: -2,
            product: 'scoop_$scoopPriceId',
            price: '0',
            pieces: 1,
          );
        } else {
          return OrderItem.fromJson(data);
        }
      } else {
        throw Exception(
          _extractErrorMessage(response, 'Failed to add scoop to order'),
        );
      }
    } catch (e) {
      DebugService.logOrder('Error adding scoop to order: $e');
      throw Exception('Error adding scoop to order: $e');
    }
  }

  static Future<OrderItem> increaseScoopOrderItemQuantity(int itemId) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/orderitem/update/$itemId/inc/'),
            headers: _headers,
          )
          .timeout(_timeout);

      DebugService.logOrder(
        'Scoop Increment Response Status: ${response.statusCode}',
      );
      DebugService.logOrder('Scoop Increment Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('message') &&
            data['message'] == 'Order item updated successfully') {
          DebugService.logOrder('Scoop increment successful');
          return OrderItem(
            itemId: itemId,
            orderItemId: itemId,
            product: 'scoop',
            price: '0',
            pieces: 1,
          );
        } else {
          return OrderItem.fromJson(data);
        }
      } else {
        throw Exception(
          _extractErrorMessage(response, 'Failed to increase scoop quantity'),
        );
      }
    } catch (e) {
      DebugService.logOrder('Error increasing scoop quantity: $e');
      throw Exception('Error increasing scoop quantity: $e');
    }
  }

  static Future<OrderItem> decreaseScoopOrderItemQuantity(int itemId) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/sales/orderitem/update/$itemId/dec/'),
            headers: _headers,
          )
          .timeout(_timeout);

      DebugService.logOrder(
        'Scoop Decrement Response Status: ${response.statusCode}',
      );
      DebugService.logOrder('Scoop Decrement Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('message') &&
            data['message'] == 'Order item updated successfully') {
          DebugService.logOrder('Scoop decrement successful');
          return OrderItem(
            itemId: itemId,
            orderItemId: itemId,
            product: 'scoop',
            price: '0',
            pieces: 1,
          );
        } else {
          return OrderItem.fromJson(data);
        }
      } else {
        throw Exception(
          'Failed to decrease scoop quantity: ${response.statusCode}',
        );
      }
    } catch (e) {
      DebugService.logOrder('Error decreasing scoop quantity: $e');
      throw Exception('Error decreasing scoop quantity: $e');
    }
  }

  static Future<void> deleteScoopOrderItem(int itemId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/sales/orderitem/delete/$itemId/'),
            headers: _headers,
          )
          .timeout(_timeout);

      DebugService.logOrder(
        'Scoop Delete Response Status: ${response.statusCode}',
      );
      DebugService.logOrder('Scoop Delete Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete scoop order item: ${response.statusCode}',
        );
      }
    } catch (e) {
      DebugService.logOrder('Error deleting scoop order item: $e');
      throw Exception('Error deleting scoop order item: $e');
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ B2B API endpoints Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  static Future<Map<String, dynamic>> getB2BSettings() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/b2b/settings/'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get B2B settings: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting B2B settings: $e');
    }
  }

  static Future<Map<String, dynamic>> saveB2BSettings(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/settings/'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to save B2B settings: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saving B2B settings: $e');
    }
  }

  /// Atomically increments the invoice counter and returns the next code.
  static Future<String> consumeNextInvoiceNumber() async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/settings/next-number/'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['invoice_code'] as String;
      }
      throw Exception(
        'Failed to consume invoice number: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error consuming invoice number: $e');
    }
  }

  /// Returns {valid: bool, password_set: bool}
  static Future<Map<String, dynamic>> verifyB2BPassword(String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/settings/verify-password/'),
            headers: _headers,
            body: json.encode({'password': password}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to verify B2B password: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error verifying B2B password: $e');
    }
  }

  /// Returns {success: bool, password_set: bool}. Pass empty newPassword to remove it.
  static Future<Map<String, dynamic>> setB2BPassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/settings/set-password/'),
            headers: _headers,
            body: json.encode({
              'old_password': ?oldPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 403) {
        throw Exception('Current password is incorrect');
      }
      throw Exception('Failed to set B2B password: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getB2BInvoices() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/b2b/invoices/'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to get B2B invoices: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting B2B invoices: $e');
    }
  }

  static Future<void> validateB2BInvoiceStock(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/stock/validate/'),
            headers: _headers,
            body: json.encode({'items': data['items'] ?? []}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorMessage(response, 'Live stock validation failed'),
        );
      }
    } catch (e) {
      throw Exception('Error validating B2B stock: $e');
    }
  }

  static Future<Map<String, dynamic>> createB2BInvoice(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/invoices/'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
        _extractErrorMessage(response, 'Failed to create B2B invoice'),
      );
    } catch (e) {
      throw Exception('Error creating B2B invoice: $e');
    }
  }

  static Future<Map<String, dynamic>> updateB2BInvoice(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/b2b/invoices/$id/'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
        _extractErrorMessage(response, 'Failed to update B2B invoice'),
      );
    } catch (e) {
      throw Exception('Error updating B2B invoice: $e');
    }
  }

  static Future<void> deleteB2BInvoice(int id) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/b2b/invoices/$id/'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete B2B invoice: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting B2B invoice: $e');
    }
  }

  /// PATCH only the status field of a B2B invoice.
  static Future<void> updateB2BInvoiceStatus(int id, String status) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/b2b/invoices/$id/status/'),
            headers: _headers,
            body: json.encode({'status': status}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update invoice status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating invoice status: $e');
    }
  }

  static Future<List<dynamic>> getB2BCatalog() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/b2b/catalog/'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to get B2B catalog: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting B2B catalog: $e');
    }
  }

  static Future<List<dynamic>> saveB2BCatalog(
    List<Map<String, dynamic>> catalog,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/b2b/catalog/'),
            headers: _headers,
            body: json.encode(catalog),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to save B2B catalog: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saving B2B catalog: $e');
    }
  }

  /// Returns a map of productId -> stock info (available boxes + box_pieces for sticks).
  /// Fetches live stock from the backend for all B2B catalog products.
  static Future<Map<String, ({int available, int? boxPieces})>>
  getB2BStock() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/b2b/stock/'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final raw = json.decode(response.body) as Map<String, dynamic>;
        return raw.map((k, v) {
          if (v is Map) {
            return MapEntry(k, (
              available: ((v['available'] ?? 0) as num).toInt(),
              boxPieces: v['box_pieces'] != null
                  ? (v['box_pieces'] as num).toInt()
                  : null,
            ));
          }
          // Fallback: old flat-int format
          return MapEntry(k, (available: (v as num).toInt(), boxPieces: null));
        });
      }
      throw Exception('Failed to get B2B stock: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting B2B stock: $e');
    }
  }
}
