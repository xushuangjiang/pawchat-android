import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/websocket/protocol.dart';
import '../bloc/chat_bloc.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String? streamingContent;
  
  const MessageList({
    super.key,
    required this.messages,
    this.streamingContent,
  });
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // 下拉刷新加载历史消息
        context.read<ChatBloc>().add(const ChatLoadHistory(limit: 100));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        reverse: true, // 消息从底部开始
        itemCount: messages.length + (streamingContent != null ? 1 : 0),
        itemBuilder: (context, index) {
          // 因为是 reverse，索引需要反转
          final reversedIndex = messages.length - 1 - index;
          
          if (streamingContent != null && index == 0) {
            // 正在流式传输的消息 (显示在顶部，因为是 reverse)
            return MessageBubble(
              message: ChatMessage(
                role: 'assistant',
                content: streamingContent!,
                timestamp: DateTime.now(),
              ),
              isStreaming: true,
            );
          }
          
          if (reversedIndex < 0 || reversedIndex >= messages.length) {
            return const SizedBox.shrink();
          }
          
          final message = messages[reversedIndex];
          return MessageBubble(
            message: message,
            isStreaming: false,
          );
        },
      ),
    );
  }
}
