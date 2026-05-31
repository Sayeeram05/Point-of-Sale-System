import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  static void configureCertificates() {
    // Only allow self-signed certificates in debug mode
    if (kDebugMode) {
      HttpOverrides.global = MyHttpOverrides();
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  static bool _isDevelopmentHost(String host) {
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.');
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (_isDevelopmentHost(host)) {
          return true;
        }
        // Reject self-signed certs for non-local hosts even in debug
        return false;
      };
  }
}
