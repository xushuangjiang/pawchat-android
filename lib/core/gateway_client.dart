import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'message_model.dart';

/// 连接状态
enum ConnectionState { disconnected, connecting, connected, error }

/// Gateway WebSocket 客户端
class GatewayClient {
  WebSocketChannel? _channel;
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<Message>.broadcast();
  
  String? _url;
  String? _token;
  
  Stream<ConnectionState> get stateStream => _stateController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  
  /// 连接到 Gateway
  Future<void> connect(String url, {String? token}) async {
    if (_channel != null) {
      await disconnect();
    }
    
    _url = url;
    _token = token;
    _stateController.add(ConnectionState.connecting);
    
    try {
      // 构建连接 URL
      var wsUrl = url.startsWith('ws') ? url : 'ws://$url';
      if (token != null && token.isNotEmpty) {
        wsUrl += '?auth.token=$token';
      }
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;
      
      _stateController.add(ConnectionState.connected);
      _listen();
      
    } catch (e) {
      _stateController.add(ConnectionState.error);
      throw Exception('连接失败: $e');
    }
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _stateController.add(ConnectionState.disconnected);
  }
  
  /// 发送消息
  void sendMessage(String content) {
    if (_channel == null) {
      throw Exception('未连接到 Gateway');
    }
    
    final payload = {
      'method': 'chat.send',
      'params': {'content': content},
    };
    
    _channel!.sink.add(jsonEncode(payload));
  }
  
  /// 中止当前响应
  void abort() {
    if (_channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'method': 'chat.abort',
    }));
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
        _stateController.add(ConnectionState.error);
      },
      onDone: () {
        _stateController.add(ConnectionState.disconnected);
      },
    );
  }
  
  /// 处理收到的消息
  void _handleMessage(Map<String, dynamic> json) {
    final type = json['type'];
    
    if (type == 'chunk') {
      // 流式响应片段
      final content = json['content'] ?? '';
      _messageController.add(Message.assistantStreaming().copyWith(content: content));
    } else if (type == 'complete') {
      // 响应完成
      final content = json['content'] ?? '';
      _messageController.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      ));
    } else if (type == 'error') {
      // 错误消息
      final errorMsg = json['error'] ?? '未知错误';
      _messageController.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: '❌ $errorMsg',
        timestamp: DateTime.now(),
      ));
    }
  }
  
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
