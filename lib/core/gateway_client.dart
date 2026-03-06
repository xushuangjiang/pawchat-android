import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'message_model.dart';
import 'version.dart';

/// 连接状态
enum GatewayConnectionState { disconnected, connecting, connected, error }

/// Gateway WebSocket 客户端
/// 
/// 遵循 OpenClaw Gateway Protocol v3
class GatewayClient {
  WebSocketChannel? _channel;
  final _stateController = StreamController<GatewayConnectionState>.broadcast();
  final _messageController = StreamController<Message>.broadcast();
  
  String? _url;
  String? _token;
  String? _sessionKey;
  String? _deviceId;
  int _messageId = 0;
  bool _isConnected = false;
  Completer<void>? _connectCompleter;
  String? _challengeNonce;
  
  Stream<GatewayConnectionState> get stateStream => _stateController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;
  
  /// 生成唯一消息 ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_messageId++}';
  }
  
  /// 生成设备 ID
  String _getDeviceId() {
    _deviceId ??= 'pawchat-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
    return _deviceId!;
  }
  
  /// 连接到 Gateway
  Future<void> connect(String url, {String? token}) async {
    if (_channel != null) {
      await disconnect();
    }
    
    _url = url;
    _token = token;
    _stateController.add(GatewayConnectionState.connecting);
    
    try {
      // 构建 WebSocket URL
      var wsUrl = url.startsWith('ws') ? url : 'ws://$url';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;
      
      // 开始监听（必须在发送 connect 之前）
      _listen();
      
      // 等待 challenge 或发送 connect 请求
      await _waitForChallengeOrConnect(token);
      
    } catch (e) {
      _stateController.add(GatewayConnectionState.error);
      throw Exception('连接失败: $e');
    }
  }
  
  /// 等待 challenge 或直接发送 connect
  Future<void> _waitForChallengeOrConnect(String? token) async {
    // 创建 completer 等待响应
    _connectCompleter = Completer<void>();
    
    // 给服务器一点时间发送 challenge
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 如果没有收到 challenge，直接发送 connect
    if (_challengeNonce == null) {
      await _sendConnectRequest(token);
    }
    
    // 等待响应，超时 10 秒
    await _connectCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('连接超时：Gateway 未响应');
      },
    );
  }
  
  /// 发送 connect 请求（Protocol v3）
  Future<void> _sendConnectRequest(String? token) async {
    final deviceId = _getDeviceId();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'connect',
      'params': {
        'minProtocol': 3,
        'maxProtocol': 3,
        'client': {
          'id': 'cli',
          'version': AppVersion.version,
          'platform': 'android',
          'mode': 'cli',
        },
        'role': 'operator',
        'scopes': ['operator.read', 'operator.write'],
        'caps': [],
        'commands': [],
        'permissions': {},
        if (token != null && token.isNotEmpty)
          'auth': {'token': token},
        'locale': 'zh-CN',
        'userAgent': 'PawChat/${AppVersion.version}',
        // 暂时不发送 device 字段，避免签名验证
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    _isConnected = false;
    _challengeNonce = null;
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.completeError('Disconnected');
    }
    _connectCompleter = null;
    await _channel?.sink.close();
    _channel = null;
    _stateController.add(GatewayConnectionState.disconnected);
  }
  
  /// 获取聊天历史
  void getChatHistory({String? sessionKey, int limit = 50}) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'chat.history',
      'params': {
        if (sessionKey != null) 'sessionKey': sessionKey,
        'limit': limit,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取会话列表
  void getSessions({int limit = 50}) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'sessions.list',
      'params': {
        'limit': limit,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 重置会话
  void resetSession(String sessionKey) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'sessions.reset',
      'params': {
        'key': sessionKey,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 删除会话
  void deleteSession(String sessionKey) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'sessions.delete',
      'params': {
        'key': sessionKey,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 修改会话 (webchat 支持)
  void patchSession(String sessionKey, {String? title}) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'sessions.patch',
      'params': {
        'key': sessionKey,
        if (title != null) 'title': title,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取健康状态 (webchat 支持)
  void getHealth() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'health',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取状态 (webchat 支持)
  void getStatus() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'status',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取配置 (webchat 支持)
  void getConfig() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'config.get',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 设置配置 (webchat 支持)
  void setConfig(String path, dynamic value) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'config.set',
      'params': {
        'path': path,
        'value': value,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取模型列表 (webchat 支持)
  void getModels() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'models.list',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取代理列表 (webchat 支持)
  void getAgents() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'agents.list',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取节点列表 (webchat 支持)
  void getNodes() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'node.list',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 获取渠道状态 (webchat 支持)
  void getChannelsStatus() {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'channels.status',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 发送聊天消息
  void sendMessage(String content, {String? sessionKey}) {
    if (!_isConnected || _channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    // 如果没有指定 sessionKey，使用当前会话或创建新会话
    _sessionKey ??= 'session-${DateTime.now().millisecondsSinceEpoch}';
    if (sessionKey != null) {
      _sessionKey = sessionKey;
    }
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'chat.send',
      'params': {
        'content': content,
        'sessionKey': _sessionKey,
      },
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 中止当前响应
  void abort() {
    if (!_isConnected || _channel == null) return;
    
    final request = {
      'type': 'req',
      'id': _generateId(),
      'method': 'chat.abort',
      'params': {},
    };
    
    _channel!.sink.add(jsonEncode(request));
  }
  
  /// 监听消息
  void _listen() {
    _channel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String);
          _handleMessage(json);
        } catch (e) {
          print('解析消息失败: $e');
        }
      },
      onError: (error) {
        _isConnected = false;
        _stateController.add(GatewayConnectionState.error);
        if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
          _connectCompleter!.completeError(error);
        }
      },
      onDone: () {
        _isConnected = false;
        _stateController.add(GatewayConnectionState.disconnected);
        if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
          _connectCompleter!.completeError('Connection closed');
        }
      },
    );
  }
  
  /// 处理收到的消息
  void _handleMessage(Map<String, dynamic> json) {
    final type = json['type'];
    
    // 处理事件（包括 challenge）
    if (type == 'event') {
      final event = json['event'];
      final payload = json['payload'] ?? {};
      
      if (event == 'connect.challenge') {
        // 保存 challenge nonce
        _challengeNonce = payload['nonce']?.toString();
        // 重新发送 connect 请求（包含 nonce）
        _sendConnectRequest(_token);
        return;
      }
      
      if (event == 'chat.chunk') {
        // 流式响应片段
        final content = payload['content'] ?? '';
        _messageController.add(Message.assistantStreaming().copyWith(content: content));
      } else if (event == 'chat.complete') {
        // 响应完成
        final content = payload['content'] ?? '';
        _messageController.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: content,
          timestamp: DateTime.now(),
        ));
      } else if (event == 'chat.error') {
        // 错误消息
        final errorMsg = payload['error'] ?? '未知错误';
        _messageController.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: '❌ $errorMsg',
          timestamp: DateTime.now(),
        ));
      } else if (event == 'chat.history') {
        // 历史消息
        final history = payload['history'] as List? ?? [];
        for (final msg in history) {
          final role = msg['role'] == 'user' ? MessageRole.user : MessageRole.assistant;
          _messageController.add(Message(
            id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            role: role,
            content: msg['content'] ?? '',
            timestamp: DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now(),
          ));
        }
      } else if (event == 'presence') {
        // 设备在线状态更新
        final entries = payload['entries'] as List? ?? [];
        _messageController.add(Message.system('在线设备: ${entries.length}'));
      } else if (event == 'heartbeat') {
        // 心跳响应
        print('收到心跳响应');
      }
      return;
    }
    
    // 处理响应（包括 connect 响应）
    if (type == 'res') {
      final ok = json['ok'] ?? false;
      
      if (!ok) {
        final error = json['error'] ?? '请求失败';
        print('Gateway 错误: $error');
        if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
          _connectCompleter!.completeError(Exception(error));
        }
        return;
      }
      
      // 检查是否是 connect 响应
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _isConnected = true;
        _stateController.add(GatewayConnectionState.connected);
        _connectCompleter!.complete();
      }
    }
  }
  
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
