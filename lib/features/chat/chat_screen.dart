import 'package:flutter/material.dart';
import '../../core/gateway_client.dart';
import '../../core/message_model.dart';
import '../../core/message_store.dart';
import '../../core/message_actions.dart';
import '../../core/reconnection_manager.dart';
import '../../core/session_manager.dart';
import '../settings/settings_screen.dart';
import '../sessions/sessions_screen.dart';
import '../search/search_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = GatewayClient();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final ReconnectionManager _reconnectionManager;
  late final SessionManager _sessionManager;
  
  List<Message> _messages = [];
  GatewayConnectionState _connectionState = GatewayConnectionState.disconnected;
  ReconnectionState _reconnectionState = ReconnectionState.connected;
  Message? _streamingMessage;
  bool _isSending = false;
  
  @override
  void initState() {
    super.initState();
    _reconnectionManager = ReconnectionManager(_client);
    _sessionManager = SessionManager();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _sessionManager.loadSessions();
    await _loadMessages();
    _listenToConnection();
    _listenToReconnection();
    _listenToMessages();
  }
  
  Future<void> _loadMessages() async {
    final messages = await MessageStore.loadMessages();
    setState(() => _messages = messages);
  }
  
  void _listenToConnection() {
    _client.stateStream.listen((state) {
      setState(() => _connectionState = state);
      
      switch (state) {
        case GatewayConnectionState.connected:
          MessageActions.showConnectedSnackBar(context);
          break;
        case GatewayConnectionState.disconnected:
          if (_reconnectionManager.isEnabled) {
            MessageActions.showDisconnectedSnackBar(context);
          }
          break;
        default:
          break;
      }
    });
  }
  
  void _listenToReconnection() {
    _reconnectionManager.stateStream.listen((state) {
      setState(() => _reconnectionState = state);
      
      switch (state) {
        case ReconnectionState.reconnecting:
          MessageActions.showReconnectionSnackBar(
            context,
            attempt: _reconnectionManager.attemptCount,
            maxAttempts: 10,
            onCancel: () => _reconnectionManager.disable(),
          );
          break;
        case ReconnectionState.maxAttemptsReached:
          _showError('重连失败，请检查网络或 Gateway 状态');
          break;
        default:
          break;
      }
    });
  }
  
  void _listenToMessages() {
    _client.messageStream.listen((message) {
      setState(() {
        if (message.isStreaming) {
          _streamingMessage = message;
        } else {
          _streamingMessage = null;
          _isSending = false;
          _messages.add(message);
          _saveMessages();
        }
      });
      _scrollToBottom();
    });
  }
  
  void _saveMessages() {
    MessageStore.saveMessages(_messages);
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
  
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    if (!_client.isConnected) {
      _showError('请先连接到 Gateway');
      return;
    }
    
    // 添加用户消息
    final userMsg = Message.user(text);
    setState(() {
      _messages.add(userMsg);
      _isSending = true;
      _textController.clear();
    });
    _saveMessages();
    _scrollToBottom();
    
    // 发送到 Gateway
    try {
      final sessionKey = _sessionManager.currentSession?.key;
      _client.sendMessage(text, sessionKey: sessionKey);
      if (sessionKey != null) {
        _sessionManager.updateSessionTime(sessionKey);
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showError('发送失败: $e');
    }
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  void dispose() {
    _client.dispose();
    _reconnectionManager.dispose();
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
          _buildConnectionIndicator(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: '搜索',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _openSessions,
            tooltip: '会话',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '设置',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildReconnectionBanner(),
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildConnectionIndicator() {
    Color color;
    IconData icon;
    String tooltip;
    
    switch (_connectionState) {
      case GatewayConnectionState.connected:
        color = Colors.green;
        icon = Icons.circle;
        tooltip = '已连接';
        break;
      case GatewayConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.pending;
        tooltip = '连接中...';
        break;
      case GatewayConnectionState.error:
        color = Colors.red;
        icon = Icons.error_outline;
        tooltip = '连接错误';
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
        tooltip = '未连接';
    }
    
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(icon, color: color, size: 12),
      ),
    );
  }
  
  Widget _buildReconnectionBanner() {
    if (_reconnectionState != ReconnectionState.reconnecting) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '正在重连... (${_reconnectionManager.attemptCount}/10)',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
          TextButton(
            onPressed: () => _reconnectionManager.disable(),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList() {
    final items = [..._messages];
    if (_streamingMessage != null) {
      items.add(_streamingMessage!);
    }
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '开始新的对话',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角设置连接 Gateway',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMessageBubble(items[index]),
    );
  }
  
  Widget _buildMessageBubble(Message msg) {
    final isUser = msg.role == MessageRole.user;
    final isSystem = msg.role == MessageRole.system;
    
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.content,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    
    return GestureDetector(
      onLongPress: () => MessageActions.showMessageMenu(
        context,
        msg,
        onDelete: () => _deleteMessage(msg),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : null,
                ),
              ),
              if (msg.isStreaming)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUser ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _deleteMessage(Message msg) {
    setState(() {
      _messages.removeWhere((m) => m.id == msg.id);
    });
    _saveMessages();
  }
  
  Widget _buildInputArea() {
    final isConnected = _client.isConnected;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: isConnected && !_isSending,
                decoration: InputDecoration(
                  hintText: isConnected 
                      ? (_isSending ? '发送中...' : '输入消息...')
                      : '请先连接 Gateway',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: isConnected && !_isSending ? _sendMessage : null,
              elevation: 0,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }
  
  void _openSessions() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionsScreen(sessionManager: _sessionManager),
      ),
    );
    if (result == true) {
      // 会话已切换，可以重新加载消息
      _loadMessages();
    }
  }
  
  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          client: _client,
          reconnectionManager: _reconnectionManager,
          sessionManager: _sessionManager,
        ),
      ),
    );
    if (result == true) {
      _loadMessages();
    }
  }
}
