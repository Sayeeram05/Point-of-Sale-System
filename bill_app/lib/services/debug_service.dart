import 'package:flutter/foundation.dart';

class DebugService {
  // Disable all debug logging for better performance
  static const bool _enableLogging = false;

  static void log(String message, [Object? error]) {
    // Only log in debug mode and when logging is enabled
    if (kDebugMode && _enableLogging) {
      debugPrint('[DEBUG] $message');
      if (error != null) {
        debugPrint('[ERROR] $error');
      }
    }
  }

  static void logApi(String message) {
    if (kDebugMode && _enableLogging) {
      debugPrint('[API] $message');
    }
  }

  static void logTub(String message) {
    if (kDebugMode && _enableLogging) {
      debugPrint('[TUB] $message');
    }
  }

  static void logOrder(String message) {
    if (kDebugMode && _enableLogging) {
      debugPrint('[ORDER] $message');
    }
  }
}
