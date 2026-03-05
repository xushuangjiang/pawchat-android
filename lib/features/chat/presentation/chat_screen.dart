import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import 'message_list.dart';
import 'message_input.dart';
import '../../../core/websocket/gateway_client.dart';
import '../../settings/settings_screen.dart';
import '../../sessions/sessions_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(GatewayClient()),
      child: const ChatView(),
    );
  }
}

class ChatView extends StatelessWidget {
  const ChatView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PawChat 🐾'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.list),
          tooltip: '会话列表',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SessionsScreen()),
            );
          },
        ),
        actions: [
          // 连接状态指示器
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              IconData icon;
              Color color;
              
              if (state is ChatConnected || state is ChatStreaming) {
                icon = Icons.cloud_done;
                color = Colors.green;
              } else if (state is ChatLoading) {
                icon = Icons.cloud_sync;
                color = Colors.orange;
              } else if (state is ChatPairingRequired) {
                icon = Icons.cloud_off;
                color = Colors.red;
              } else {
                icon = Icons.cloud_off;
                color = Colors.grey;
              }
              
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(icon, color: color, size: 24),
              );
            },
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
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
        },
        builder: (context, state) {
          if (state is ChatInitial) {
            return _buildDisconnectedState(context);
          } else if (state is ChatLoading) {
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
          } else if (state is ChatPairingRequired) {
            return _buildPairingState(context);
          } else if (state is ChatConnected || state is ChatStreaming) {
            return _buildChatState(context, state);
          } else if (state is ChatError) {
            return _buildErrorState(context, state);
          }
          
          return const Center(
            child: Text('未知状态'),
          );
        },
      ),
    );
  }
  
  Widget _buildDisconnectedState(BuildContext context) {
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
            onPressed: () {
              _showConnectionDialog(context);
            },
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
  
  Widget _buildPairingState(BuildContext context) {
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
            onPressed: () {
              context.read<ChatBloc>().add(const ChatDisconnect());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试连接'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatState(BuildContext context, ChatState state) {
    final messages = (state is ChatConnected) 
        ? (state as ChatConnected).messages 
        : (state is ChatStreaming) 
            ? (state as ChatStreaming).messages 
            : [];
    
    return Column(
      children: [
        // 消息列表
        Expanded(
          child: MessageList(
            messages: messages,
            streamingContent: state is ChatStreaming 
                ? (state as ChatStreaming).streamingContent 
                : null,
          ),
        ),
        // 输入框
        MessageInput(
          onSend: (content) {
            context.read<ChatBloc>().add(ChatSendMessage(content));
          },
          onAbort: state is ChatStreaming
              ? () {
                  context.read<ChatBloc>().add(const ChatAbort());
                }
              : null,
          isStreaming: state is ChatStreaming,
        ),
      ],
    );
  }
  
  Widget _buildErrorState(BuildContext context, ChatError state) {
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
            onPressed: () {
              context.read<ChatBloc>().add(const ChatDisconnect());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新连接'),
          ),
        ],
      ),
    );
  }
  
  void _showConnectionDialog(BuildContext context) {
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
