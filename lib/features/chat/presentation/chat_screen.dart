import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/models/message.dart';
import '../../../core/websocket/gateway_client.dart';
import '../bloc/chat_bloc.dart';
import 'message_list.dart';
import 'message_input.dart';
import 'reconnect_indicator.dart';
import '../../settings/settings_screen.dart';
import '../../sessions/sessions_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(getIt<GatewayClient>()),
      child: const ChatView(),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Column(
            children: [
              // 重连指示器
              if (state is ChatConnected && state.isReconnecting)
                ReconnectIndicator(
                  isReconnecting: state.isReconnecting,
                  attempt: state.reconnectAttempt,
                ),
              // 主内容区域
              Expanded(
                child: _buildBody(state),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('PawChat 🐾'),
      leading: IconButton(
        icon: const Icon(Icons.list),
        tooltip: '会话列表',
        onPressed: () => _navigateToSessions(),
      ),
      actions: [
        // 连接状态指示器
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _buildConnectionStatus(state),
            );
          },
        ),
        // 设置按钮
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '设置',
          onPressed: () => _navigateToSettings(),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(ChatState state) {
    IconData icon;
    Color color;
    String tooltip;
    
    switch (state.runtimeType) {
      case ChatConnected:
        final connected = state as ChatConnected;
        if (connected.isReconnecting) {
          icon = Icons.cloud_sync;
          color = Colors.orange;
          tooltip = '正在重连...';
        } else {
          icon = Icons.cloud_done;
          color = Colors.green;
          tooltip = '已连接';
        }
        break;
      case ChatLoading:
        icon = Icons.cloud_sync;
        color = Colors.orange;
        tooltip = '连接中...';
        break;
      case ChatPairingRequired:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = '需要配对';
        break;
      default:
        icon = Icons.cloud_off;
        color = Colors.grey;
        tooltip = '未连接';
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildBody(ChatState state) {
    return switch (state) {
      ChatInitial() => _buildDisconnectedState(),
      ChatLoading() => _buildLoadingState(),
      ChatPairingRequired() => _buildPairingState(),
      ChatConnected() => _buildChatState(state),
      ChatStreaming() => _buildChatState(state),
      ChatError() => _buildErrorState(state),
      _ => const Center(child: Text('未知状态')),
    };
  }

  Widget _buildDisconnectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            '未连接到 OpenClaw Gateway',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '配置 Gateway 地址后开始聊天',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showConnectionDialog(),
            icon: const Icon(Icons.cloud_sync),
            label: const Text('连接 Gateway'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在连接 Gateway...'),
        ],
      ),
    );
  }

  Widget _buildPairingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            '需要设备配对',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '这是新设备首次连接。请在 Gateway 所在设备上批准此设备的连接请求。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '批准命令:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'openclaw devices approve <requestId>',
              style: TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.read<ChatBloc>().add(const ChatDisconnect()),
            icon: const Icon(Icons.refresh),
            label: const Text('重试连接'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatState(ChatState state) {
    final messages = switch (state) {
      ChatConnected() => state.messages,
      ChatStreaming() => state.messages,
      _ => <Message>[],
    };

    final streamingContent = state is ChatStreaming ? state.streamingContent : null;

    return Column(
      children: [
        Expanded(
          child: MessageList(
            messages: messages,
            streamingContent: streamingContent,
            scrollController: _scrollController,
          ),
        ),
        MessageInput(
          onSend: (content) {
            context.read<ChatBloc>().add(ChatSendMessage(content));
          },
          onAbort: state is ChatStreaming
              ? () => context.read<ChatBloc>().add(const ChatAbort())
              : null,
          isStreaming: state is ChatStreaming,
        ),
      ],
    );
  }

  Widget _buildErrorState(ChatError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 24),
          const Text(
            '发生错误',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.read<ChatBloc>().add(const ChatDisconnect()),
            icon: const Icon(Icons.refresh),
            label: const Text('重新连接'),
          ),
        ],
      ),
    );
  }

  void _handleStateChanges(BuildContext context, ChatState state) {
    if (state is ChatError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: state.isFatal ? Colors.red : Colors.orange,
          action: state.isFatal
              ? SnackBarAction(
                  label: '重试',
                  onPressed: () => context.read<ChatBloc>().add(const ChatReconnect()),
                )
              : null,
        ),
      );
    } else if (state is ChatPairingRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要设备配对！请在 Gateway 批准此设备'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _navigateToSessions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SessionsScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showConnectionDialog() {
    final urlController = TextEditingController(text: 'ws://192.168.1.100:18789');
    final tokenController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接 Gateway'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL',
                hintText: 'ws://host:18789',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Token (可选)',
                hintText: 'Gateway 认证 Token',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(ChatConnect(
                url: urlController.text,
                token: tokenController.text.isEmpty ? null : tokenController.text,
              ));
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }
}
