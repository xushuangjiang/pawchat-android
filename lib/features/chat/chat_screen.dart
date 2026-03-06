import 'package:flutter/material.dart';
import '../../core/gateway_client.dart';
import '../../core/message_model.dart';
import '../../core/message_store.dart';
import '../settings/settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = GatewayClient();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Message> _messages = [];
  GatewayConnectionState _connectionState = GatewayConnectionState.disconnected;
  bool _isStreaming = false;
  String _streamingContent = '';
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToConnection();
    _listenToMessages();
  }
  
  void _loadMessages() async {
    final messages = await MessageStore.loadMessages();
    setState(() => _messages = messages);
  }
  
  void _listenToConnection() {
    _client.stateStream.listen((state) {
      setState(() => _connectionState = state);
    });
  }
  
  Message? _currentStreamingMessage;
  
  void _listenToMessages() {
    _client.messageStream.listen((message) {
      setState(() {
        if (message.isStreaming) {
          _isStreaming = true;
          _currentStreamingMessage = message;
        } else {
          _isStreaming = false;
          _currentStreamingMessage = null;
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
    
    // 添加用户消息
    final userMsg = Message.user(text);
    setState(() {
      _messages.add(userMsg);
      _textController.clear();
    });
    _saveMessages();
    _scrollToBottom();
    
    // 发送到 Gateway
    try {
      _client.sendMessage(text);
    } catch (e) {
      _showError('发送失败: $e');
    }
  }
  
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
          _buildConnectionIndicator(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isStreaming) _buildStreamingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildConnectionIndicator() {
    Color color;
    IconData icon;
    
    switch (_connectionState) {
      case GatewayConnectionState.connected:
        color = Colors.green;
        icon = Icons.circle;
        break;
      case GatewayConnectionState.connecting:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case GatewayConnectionState.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(icon, color: color, size: 12),
    );
  }
  
  Widget _buildMessageList() {
    final items = [..._messages];
    if (_isStreaming && _currentStreamingMessage != null) {
      items.add(_currentStreamingMessage!);
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
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStreamingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('思考中...', style: TextStyle(color: Colors.grey)),
          Spacer(),
          TextButton(
            onPressed: () => _client.abort(),
            child: Text('中止'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
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
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(client: _client)),
    );
    if (result == true) {
      _loadMessages();
    }
  }
}
