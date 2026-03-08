import 'dart:io';
import 'package:flutter/material.dart';
import '../core/gateway_client.dart';
import '../core/message.dart';
import 'package:path_provider/path_provider.dart';

/// 主聊天界面 - MVP 版本
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = GatewayClient();
  final _messages = <Message>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isConnecting = false;  // 用于显示全屏加载指示器
  bool _isConnected = false;   // 连接成功状态
  String? _error;
  String _gatewayUrl = 'ws://192.168.0.213:18789';
  // 测试用 token - 生产环境应该让用户输入
  final String? _token = '989674d657564edbc29ef906489fba9e742f5b782273d331';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _client.stateStream.listen((state) {
      debugPrint('📡 Client state changed: $state');
      setState(() {
        _isConnecting = state == GatewayConnectionState.connecting;
        _isConnected = state == GatewayConnectionState.connected;
        if (state == GatewayConnectionState.error) {
          _error = '连接失败';
          debugPrint('❌ Connection error!');
        } else if (state == GatewayConnectionState.connected) {
          _error = null;
          debugPrint('✅ Connection successful!');
        }
      });
    });

    _client.messageStream.listen((message) {
      debugPrint('💬 Received message: ${message.role} - ${message.content.substring(0, 50)}...');
      setState(() {
        // 查找是否已有相同 ID 的流式消息
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index >= 0 && _messages[index].isStreaming) {
          // 更新现有流式消息
          _messages[index] = message;
        } else {
          // 添加新消息
          _messages.add(message);
        }
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _connect() async {
    debugPrint('🔴 === _connect() CALLED ===');
    await _writeDebugLog('_connect() CALLED at ${DateTime.now()}');
    
    // 检查 mounted 状态 (Critic 建议 C3)
    if (!mounted) {
      debugPrint('❌ Widget not mounted, aborting _connect()');
      return;
    }
    
    setState(() {
      _error = null;
      _isConnecting = true;  // 显示全屏加载指示器
    });
    
    try {
      debugPrint('🌐 Connecting to: $_gatewayUrl');
      await _writeDebugLog('Connecting to $_gatewayUrl');
      await _client.connect(_gatewayUrl, token: _token);
      debugPrint('✅ Connect completed!');
      await _writeDebugLog('Connect success!');
    } catch (e) {
      debugPrint('❌ Connect error: $e');
      await _writeDebugLog('Connect error: $e');
      if (mounted) {
        setState(() => _error = '连接失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
  
  Future<void> _writeDebugLog(String message) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final file = File('${directory.path}/pawchat_debug.log');
        await file.writeAsString(
          '[${DateTime.now()}] $message\n',
          mode: FileMode.append,
        );
        debugPrint('📝 Log written: $message');
      } else {
        debugPrint('❌ Log failed: directory is null');
      }
    } catch (e) {
      debugPrint('❌ Log ERROR: $e');
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_client.isConnected) {
      setState(() => _error = '请先连接 Gateway');
      return;
    }

    // 添加用户消息到列表
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _textController.clear();
    });

    _scrollToBottom();

    // 发送到 Gateway
    try {
      _client.sendMessage(text);
    } catch (e) {
      setState(() => _error = '发送失败: $e');
    }
  }

  void _showConnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接 Gateway'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Gateway URL',
                hintText: 'ws://192.168.0.213:18789',
              ),
              controller: TextEditingController(text: _gatewayUrl),
              onChanged: (v) => _gatewayUrl = v,
            ),
            const SizedBox(height: 8),
            // Token 已硬编码，无需输入
            // TextField(
            //   decoration: const InputDecoration(
            //     labelText: 'Token (可选)',
            //     hintText: '留空则不认证',
            //   ),
            //   obscureText: true,
            //   onChanged: (v) => _token = v.isEmpty ? null : v,
            // ),
            const Text(
              'Token 已自动填充',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              debugPrint('🔘 Connect button PRESSED!');
              Navigator.pop(context);
              // 使用 addPostFrameCallback 确保在下一帧执行，并检查 mounted
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  debugPrint('🚀 Starting _connect() from callback');
                  _connect();
                } else {
                  debugPrint('❌ Widget not mounted, cannot connect');
                }
              });
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _client.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PawChat'),
        actions: [
          // 连接状态指示器
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? '已连接' : '未连接',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          // 连接按钮
          IconButton(
            icon: Icon(_isConnected ? Icons.link_off : Icons.link),
            onPressed: _isConnected
                ? () => _client.disconnect()
                : _showConnectDialog,
            tooltip: _isConnected ? '断开' : '连接',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 错误提示
              if (_error != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade900),
                    textAlign: TextAlign.center,
                  ),
                ),

              // 连接中提示
              if (_isConnecting)
                const LinearProgressIndicator(),

              // 消息列表
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text(
                          '点击右上角连接按钮开始',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _MessageBubble(message: msg);
                        },
                      ),
              ),

              // 输入框
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: '输入消息...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          enabled: _isConnected,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isConnected ? _sendMessage : null,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // 全屏加载指示器 (Critic 建议 C4)
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '正在连接 Gateway...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 消息气泡
class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
