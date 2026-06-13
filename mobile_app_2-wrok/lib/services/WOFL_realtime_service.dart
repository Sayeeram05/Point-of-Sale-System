import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Singleton WebSocket service that maintains a persistent connection to the
/// WOFL backend's real-time orders endpoint: `ws://<ip>/ws/orders/`
///
/// Consumers subscribe to [stream] and receive a Map with keys:
///   {"type": "order_update", "action": "created"|"updated"|"deleted", "order_id": int}
///
/// The service automatically reconnects with exponential backoff (1s to 30s cap)
/// when the connection drops.
class WOFLRealtimeService {
  WOFLRealtimeService._();
  static final WOFLRealtimeService instance = WOFLRealtimeService._();

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _currentIp;
  bool _disposed = false;
  bool _reconnecting = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  static const int _maxRetrySeconds = 30;

  /// Call once after the server IP is known.
  void connect(String ip) {
    _currentIp = ip;
    _retryCount = 0;
    _reconnecting = false;
    _retryTimer?.cancel();
    _doConnect();
  }

  /// Call when the IP changes (e.g. settings page update).
  void reconnect(String newIp) {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnecting = false;
    connect(newIp);
  }

  void _doConnect() {
    if (_disposed || _currentIp == null) return;

    final uri = Uri.parse('ws://$_currentIp/ws/orders/');
    if (kDebugMode) debugPrint('[WOFLRT] Connecting to $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _retryCount = 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[WOFLRT] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;
      if (!_controller.isClosed) {
        _controller.add(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[WOFLRT] Parse error: $e');
    }
  }

  void _onError(Object error) {
    if (kDebugMode) debugPrint('[WOFLRT] Error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    if (kDebugMode) debugPrint('[WOFLRT] Connection closed');
    if (!_disposed) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnecting) return;
    _reconnecting = true;

    final delay = min(
      (1 << _retryCount).toDouble(),
      _maxRetrySeconds.toDouble(),
    );
    final jitter = Random().nextInt(1000);
    final total = Duration(
      milliseconds: (delay * 1000).toInt() + jitter,
    );

    if (kDebugMode) {
      debugPrint('[WOFLRT] Reconnecting in ${total.inMilliseconds}ms '
          '(attempt ${_retryCount + 1})');
    }

    _retryTimer = Timer(total, () {
      _reconnecting = false;
      _retryCount = min(_retryCount + 1, 5);
      _subscription?.cancel();
      _channel?.sink.close();
      _channel = null;
      _doConnect();
    });
  }

  void disconnect() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnecting = false;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
