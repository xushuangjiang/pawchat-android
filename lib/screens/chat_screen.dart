import 'package:flutter/material.dart';
import '../core/gateway_client.dart';
import '../core/message.dart';

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
  bool _isConnecting = false;
  String? _error;
  String _gatewayUrl = 'ws://192.168.0.213:18789';
  String? _token;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _client.stateStream.listen((state) {
      setState(() {
        _isConnecting = state == GatewayConnectionState.connecting;
        if (state == GatewayConnectionState.error) {
          _error = '连接失败';
        } else if (state == GatewayConnectionState.connected) {
          _error = null;
        }
      });
    });

    _client.messageStream.listen((message) {
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
    setState(() => _error = null);
    try {
      await _client.connect(_gatewayUrl, token: _token);
    } catch (e) {
      setState(() => _error = '连接失败: $e');
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
            TextField(
              decoration: const InputDecoration(
                labelText: 'Token (可选)',
                hintText: '留空则不认证',
              ),
              obscureText: true,
              onChanged: (v) => _token = v.isEmpty ? null : v,
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
              Navigator.pop(context);
              _connect();
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
                    color: _client.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _client.isConnected ? '已连接' : '未连接',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          // 连接按钮
          IconButton(
            icon: Icon(_client.isConnected ? Icons.link_off : Icons.link),
            onPressed: _client.isConnected
                ? () => _client.disconnect()
                : _showConnectDialog,
            tooltip: _client.isConnected ? '断开' : '连接',
          ),
        ],
      ),
      body: Column(
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
                      enabled: _client.isConnected,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _client.isConnected ? _sendMessage : null,
                    icon: const Icon(Icons.send),
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
