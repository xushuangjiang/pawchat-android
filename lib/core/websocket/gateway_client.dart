import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'protocol.dart';

/// OpenClaw Gateway WebSocket 客户端
class GatewayClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<GatewayMessage>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _sessionKey;
  
  Stream<GatewayMessage> get messages => _messageController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get status => _status;
  String? get sessionKey => _sessionKey;
  
  /// 连接到 Gateway
  Future<void> connect({
    required String url,
    String? token,
    String? password,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_status == ConnectionStatus.connected) {
      throw StateError('Already connected');
    }
    
    _updateStatus(ConnectionStatus.connecting);
    
    try {
      final uri = Uri.parse(url);
      final authParams = <String, String>{};
      
      if (token != null) {
        authParams['auth.token'] = token;
      } else if (password != null) {
        authParams['auth.password'] = password;
      }
      
      final connectUri = authParams.isNotEmpty
          ? uri.replace(queryParameters: authParams)
          : uri;
      
      _channel = WebSocketChannel.connect(connectUri);
      
      // 设置连接超时
      await _channel!.ready.timeout(timeout);
      
      _updateStatus(ConnectionStatus.connected);
      
      // 开始监听消息
      _listenToMessages();
      
    } on TimeoutException {
      _updateStatus(ConnectionStatus.failed);
      throw GatewayException('Connection timeout');
    } catch (e) {
      _updateStatus(ConnectionStatus.failed);
      throw GatewayException('Connection failed: $e');
    }
  }
  
  void _listenToMessages() {
    _channel!.stream.listen(
      (data) {
        try {
          final message = GatewayMessage.fromJson(jsonDecode(data as String));
          _messageController.add(message);
          
          // 处理配对错误
          if (message.type == 'error' && 
              message.data?['code'] == 'pairing_required') {
            _updateStatus(ConnectionStatus.pairingRequired);
          }
        } catch (e) {
          _messageController.addError(GatewayException('Parse error: $e'));
        }
      },
      onError: (error) {
        _updateStatus(ConnectionStatus.disconnected);
        _messageController.addError(GatewayException('WebSocket error: $error'));
      },
      onDone: () {
        _updateStatus(ConnectionStatus.disconnected);
        _messageController.add(GatewayMessage(
          type: 'system',
          event: 'disconnected',
        ));
      },
    );
  }
  
  /// 发送消息
  Future<ChatSendResponse> sendChat({
    required String content,
    String? sessionKey,
    String? idempotencyKey,
  }) async {
    if (_status != ConnectionStatus.connected) {
      throw GatewayException('Not connected');
    }
    
    final payload = {
      'method': 'chat.send',
      'params': {
        'content': content,
        if (sessionKey != null) 'sessionKey': sessionKey,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
    };
    
    _channel!.sink.add(jsonEncode(payload));
    
    // 等待响应 (带超时)
    final response = await messages
        .where((msg) => msg.type == 'response' && msg.data?['method'] == 'chat.send')
        .timeout(const Duration(seconds: 30))
        .first;
    
    return ChatSendResponse.fromJson(response.data!);
  }
  
  /// 获取聊天历史
  Future<List<ChatMessage>> getChatHistory({
    String? sessionKey,
    int limit = 50,
  }) async {
    if (_status != ConnectionStatus.connected) {
      throw GatewayException('Not connected');
    }
    
    final payload = {
      'method': 'chat.history',
      'params': {
        if (sessionKey != null) 'sessionKey': sessionKey,
        'limit': limit,
      },
    };
    
    _channel!.sink.add(jsonEncode(payload));
    
    final response = await messages
        .where((msg) => msg.type == 'response' && msg.data?['method'] == 'chat.history')
        .timeout(const Duration(seconds: 30))
        .first;
    
    final history = response.data?['history'] as List?;
    if (history == null) return [];
    
    return history
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
  /// 中止当前运行
  Future<void> abortChat({
    String? sessionKey,
    String? runId,
  }) async {
    if (_status != ConnectionStatus.connected) {
      throw GatewayException('Not connected');
    }
    
    final payload = {
      'method': 'chat.abort',
      'params': {
        if (sessionKey != null) 'sessionKey': sessionKey,
        if (runId != null) 'runId': runId,
      },
    };
    
    _channel!.sink.add(jsonEncode(payload));
  }
  
  /// 注入助手笔记 (仅 UI 显示，不触发 agent)
  Future<void> injectNote({
    required String content,
    String? sessionKey,
  }) async {
    if (_status != ConnectionStatus.connected) {
      throw GatewayException('Not connected');
    }
    
    final payload = {
      'method': 'chat.inject',
      'params': {
        'content': content,
        if (sessionKey != null) 'sessionKey': sessionKey,
      },
    };
    
    _channel!.sink.add(jsonEncode(payload));
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    _updateStatus(ConnectionStatus.disconnecting);
    
    await _channel?.sink.close();
    _channel = null;
    _sessionKey = null;
    
    _updateStatus(ConnectionStatus.disconnected);
  }
  
  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
  
  /// 释放资源
  void dispose() {
    _channel?.sink.close();
    _messageController.close();
    _statusController.close();
  }
}

/// 连接状态
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  pairingRequired,
  failed,
  disconnecting,
}

/// Gateway 异常
class GatewayException implements Exception {
  final String message;
  GatewayException(this.message);
  
  @override
  String toString() => 'GatewayException: $message';
}
