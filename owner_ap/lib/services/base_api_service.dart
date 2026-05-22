import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Base API service for handling common HTTP operations
/// Provides error handling, logging, and response parsing
class BaseApiService {
  static String get baseUrl => AppConfig.djangoBaseUrl;
  static Duration get timeout => AppConfig.apiTimeout;

  /// GET request with error handling
  static Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      if (AppConfig.enableDebugLogs) {
        print('API GET Request: $uri');
      }
      
      final response = await http.get(
        uri,
        headers: _getHeaders(),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (AppConfig.enableDebugLogs) {
        print('API GET Error: ${e.toString()}');
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST request with error handling
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PUT request with error handling
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// DELETE request with error handling
  static Future<void> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
      ).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_getErrorMessage(response));
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Get standard headers for API requests
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Handle HTTP response and parse JSON
  static dynamic _handleResponse(http.Response response) {
    if (AppConfig.enableDebugLogs) {
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiException('Invalid JSON response: ${e.toString()}');
      }
    } else {
      throw ApiException(_getErrorMessage(response));
    }
  }

  /// Extract error message from response
  static String _getErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body.containsKey('error')) {
        return body['error'].toString();
      }
      if (body.containsKey('message')) {
        return body['message'].toString();
      }
      if (body.containsKey('detail')) {
        return body['detail'].toString();
      }
    } catch (e) {
      // If we can't parse the error, use status code
    }

    switch (response.statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      default:
        return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  
  const ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}