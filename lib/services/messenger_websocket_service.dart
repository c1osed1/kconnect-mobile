/// Сервис для работы с WebSocket соединением системы сообщений
///
/// Управляет WebSocket соединением для сообщений.
/// Поддерживает аутентификацию, переподключение и отправку сообщений.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:uuid/uuid.dart';
import 'api_client/dio_client.dart';

/// Состояния WebSocket соединения
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Сообщение WebSocket
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json,
      timestamp: DateTime.now(),
    );
  }
}

/// Сервис WebSocket для системы сообщений
class MessengerWebSocketService {
  static const String _wsUrl = 'wss://k-connect.ru/ws/messenger';

  final DioClient _dioClient;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<WebSocketMessage> _messageController = StreamController<WebSocketMessage>.broadcast();
  final StreamController<WebSocketConnectionState> _connectionController = StreamController<WebSocketConnectionState>.broadcast();

  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 20);

  String? _deviceId;
  String? _sessionKey;
  bool _isAuthenticated = false;

  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<WebSocketConnectionState> get connectionState => _connectionController.stream;
  WebSocketConnectionState get currentConnectionState => _connectionState;
  bool get isAuthenticated => _isAuthenticated;

  MessengerWebSocketService(this._dioClient) {
    _generateDeviceId();
  }

  void _generateDeviceId() {
    const uuid = Uuid();
    _deviceId = uuid.v4().replaceAll('-', '').substring(0, 16);
  }

  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      debugPrint('WebSocket: Already connecting/connected, skipping');
      return;
    }

    debugPrint('WebSocket: Starting connection...');
    _updateConnectionState(WebSocketConnectionState.connecting);

    try {
      debugPrint('WebSocket: Getting session key...');
      _sessionKey = await _dioClient.getSession();
      debugPrint('WebSocket: Session key: ${_sessionKey != null ? "present (${_sessionKey!.length} chars)" : "null"}');

      if (_sessionKey == null) {
        throw Exception('Session key is null');
      }

      debugPrint('WebSocket: Connecting to $_wsUrl...');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      debugPrint('WebSocket: Waiting for connection ready...');
      await _channel!.ready;
      debugPrint('WebSocket: Connection established');

      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _isAuthenticated = false;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      debugPrint('WebSocket: Sending authentication message...');
      await _sendAuthMessage();

    } catch (e, stackTrace) {
      debugPrint('WebSocket: Connection failed: $e');
      debugPrint('WebSocket: Stack trace: $stackTrace');
      _updateConnectionState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  Future<void> _sendAuthMessage() async {
    if (_sessionKey == null || _deviceId == null) return;

    final authMessage = {
      'type': 'auth',
      'session_key': _sessionKey,
      'device_id': _deviceId,
    };

    _sendMessage(authMessage);
  }

  void disconnect() {
    _stopPingTimer();
    _stopReconnectTimer();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  void _onMessage(dynamic message) {
    try {
      debugPrint('WebSocket: Received: $message');
      final Map<String, dynamic> jsonMessage = json.decode(message as String);
      final wsMessage = WebSocketMessage.fromJson(jsonMessage);

      if (wsMessage.type == 'connected') {
        debugPrint('WebSocket: Authentication successful');
        _isAuthenticated = true;
        _startPingTimer();
      }

      _messageController.add(wsMessage);
    } catch (e, stackTrace) {
      debugPrint('WebSocket: Failed to parse message: $e');
      debugPrint('WebSocket: Message was: $message');
      debugPrint('WebSocket: Stack trace: $stackTrace');
    }
  }

  void _onError(Object error) {
    debugPrint('WebSocket: Connection error: $error');
    _updateConnectionState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket: Connection closed');
    _updateConnectionState(WebSocketConnectionState.disconnected);
    if (_connectionState != WebSocketConnectionState.disconnected) {
      _scheduleReconnect();
    }
  }

  void _updateConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendPing() {
    if (_connectionState == WebSocketConnectionState.connected) {
      final pingMessage = {
        'type': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ping_id': _generatePingId(),
      };
      _sendMessage(pingMessage);
    }
  }

  String _generatePingId() {
    return 'ping_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;
    _stopReconnectTimer();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      connect();
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_connectionState == WebSocketConnectionState.connected && _channel != null) {
      final jsonMessage = json.encode(message);
      debugPrint('WebSocket: Sending: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } else {
      debugPrint('WebSocket: Cannot send message - not connected');
    }
  }

  void sendGetChatsMessage() {
    final message = {
      'type': 'get_chats',
      'device_id': _deviceId,
    };
    _sendMessage(message);
  }

  void sendMessage({
    required String content,
    required int chatId,
    required String clientMessageId,
    String messageType = 'text',
  }) {
    final message = {
      'type': 'send_message',
      'content': content,
      'chat_id': chatId,
      'client_message_id': clientMessageId,
      'message_type': messageType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _sendMessage(message);
  }

  void sendMarkChatAsRead(int chatId) {
    final message = {
      'type': 'mark_chat_read',
      'chat_id': chatId,
      'device_id': _deviceId,
    };
    _sendMessage(message);
  }

  void sendReadReceipt({
    required int messageId,
    required int chatId,
  }) {
    final message = {
      'type': 'read_receipt',
      'message_id': messageId,
      'chat_id': chatId,
      'device_id': _deviceId,
    };
    _sendMessage(message);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
