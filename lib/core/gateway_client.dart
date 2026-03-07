import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'message.dart';

/// Gateway 连接状态
enum ConnectionState { disconnected, connecting, connected, error }

/// Gateway WebSocket 客户端 - 简化版
class GatewayClient {
  WebSocketChannel? _channel;
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<Message>.broadcast();
  
  ConnectionState _state = ConnectionState.disconnected;
  int _msgId = 0;
  String? _sessionKey;
  String? _challengeNonce;
  
  Stream<ConnectionState> get stateStream => _stateController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  ConnectionState get state => _state;
  bool get isConnected => _state == ConnectionState.connected;

  /// 生成消息 ID
  String _nextId() => 'msg-${++_msgId}';

  /// 连接到 Gateway
  Future<void> connect(String url, {String? token}) async {
    if (_state == ConnectionState.connecting || _state == ConnectionState.connected) {
      await disconnect();
    }
    
    _setState(ConnectionState.connecting);
    
    try {
      final wsUrl = url.startsWith('ws') ? url : 'ws://$url';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          print('WebSocket error: $e');
          _setState(ConnectionState.error);
        },
        onDone: () {
          print('WebSocket closed');
          _setState(ConnectionState.disconnected);
        },
      );
      
      // 等待 challenge 然后发送 connect
      await _waitAndConnect(token);
      
    } catch (e) {
      print('Connect error: $e');
      _setState(ConnectionState.error);
      throw Exception('连接失败: $e');
    }
  }

  /// 等待 challenge 并发送 connect
  Future<void> _waitAndConnect(String? token) async {
    // 等待最多 5 秒接收 challenge
    for (var i = 0; i < 50; i++) {
      if (_challengeNonce != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // 发送 connect 请求
    final request = {
      'type': 'req',
      'id': _nextId(),
      'method': 'connect',
      'params': {
        'minProtocol': 3,
        'maxProtocol': 3,
        'client': {
          'id': 'pawchat',
          'version': '1.0.0',
          'platform': 'android',
          'mode': 'cli',
        },
        'role': 'operator',
        'scopes': ['operator.read', 'operator.write'],
        if (token != null) 'auth': {'token': token},
        'locale': 'zh-CN',
        'userAgent': 'PawChat/1.0.0',
      },
    };
    
    _send(request);
    
    // 等待连接成功
    for (var i = 0; i < 50; i++) {
      if (_state == ConnectionState.connected) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    throw Exception('连接超时');
  }

  /// 发送消息到 Gateway
  void sendMessage(String content) {
    if (!isConnected) throw Exception('未连接');
    
    _sessionKey ??= 'session-${DateTime.now().millisecondsSinceEpoch}';
    
    _send({
      'type': 'req',
      'id': _nextId(),
      'method': 'chat.send',
      'params': {
        'content': content,
        'sessionKey': _sessionKey,
      },
    });
  }

  /// 中止当前响应
  void abort() {
    if (!isConnected) return;
    _send({
      'type': 'req',
      'id': _nextId(),
      'method': 'chat.abort',
      'params': {},
    });
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _challengeNonce = null;
    _setState(ConnectionState.disconnected);
  }

  /// 发送数据
  void _send(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    print('→ Send: $json');
    _channel?.sink.add(json);
  }

  /// 处理收到的消息
  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      print('← Recv: $json');
      _handleMessage(json);
    } catch (e) {
      print('Parse error: $e');
    }
  }

  /// 处理消息
  void _handleMessage(Map<String, dynamic> json) {
    final type = json['type'];
    
    if (type == 'event') {
      _handleEvent(json);
    } else if (type == 'res') {
      _handleResponse(json);
    }
  }

  /// 处理事件
  void _handleEvent(Map<String, dynamic> json) {
    final event = json['event'];
    final payload = json['payload'] ?? {};
    
    switch (event) {
      case 'connect.challenge':
        _challengeNonce = payload['nonce']?.toString();
        print('Got challenge: $_challengeNonce');
        break;
        
      case 'chat':
        _handleChatEvent(payload);
        break;
        
      case 'presence':
        print('Presence update: ${payload['entries']?.length} devices');
        break;
        
      case 'heartbeat':
        print('Heartbeat');
        break;
    }
  }

  /// 处理聊天事件
  void _handleChatEvent(Map<String, dynamic> payload) {
    final msg = payload['message'] ?? {};
    final isStreaming = payload['streaming'] ?? false;
    
    final message = Message(
      id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: msg['role'] ?? 'assistant',
      content: msg['content'] ?? '',
      timestamp: DateTime.now(),
      isStreaming: isStreaming,
    );
    
    _messageController.add(message);
  }

  /// 处理响应
  void _handleResponse(Map<String, dynamic> json) {
    final ok = json['ok'] ?? false;
    final id = json['id'] ?? '';
    
    if (!ok) {
      print('Error response: ${json['error']}');
      return;
    }
    
    // 连接成功
    if (id.startsWith('msg-') && _state == ConnectionState.connecting) {
      _setState(ConnectionState.connected);
      print('Connected!');
    }
  }

  /// 设置状态
  void _setState(ConnectionState state) {
    _state = state;
    _stateController.add(state);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
