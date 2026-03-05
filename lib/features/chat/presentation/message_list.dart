import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/message.dart';
import '../bloc/chat_bloc.dart';
import 'message_bubble.dart';

class MessageList extends StatefulWidget {
  final List<Message> messages;
  final String? streamingContent;
  final ScrollController? scrollController;
  
  const MessageList({
    super.key,
    required this.messages,
    this.streamingContent,
    this.scrollController,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late ScrollController _scrollController;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    // 初始滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 当有新消息或流式内容变化时，自动滚动到底部
    if (widget.messages.length != oldWidget.messages.length ||
        widget.streamingContent != oldWidget.streamingContent) {
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 100.0;
    
    setState(() {
      _isAtBottom = maxScroll - currentScroll < threshold;
    });
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    if (animate) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatBloc>().add(const ChatLoadHistory(limit: 100));
      },
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            reverse: false,
            itemCount: widget.messages.length + (widget.streamingContent != null ? 1 : 0),
            itemBuilder: (context, index) {
              // 如果有流式内容，显示在最后
              if (widget.streamingContent != null && 
                  index == widget.messages.length) {
                return MessageBubble(
                  message: Message.streaming(
                    content: widget.streamingContent!,
                    runId: 'streaming',
                    sessionKey: null,
                  ),
                  isStreaming: true,
                );
              }

              if (index < 0 || index >= widget.messages.length) {
                return const SizedBox.shrink();
              }

              final message = widget.messages[index];
              return MessageBubble(
                message: message,
                isStreaming: false,
                onCopy: () => _copyMessage(context, message.content),
              );
            },
          ),
          // 滚动到底部按钮
          if (!_isAtBottom)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                onPressed: () => _scrollToBottom(),
                child: const Icon(Icons.arrow_downward),
              ),
            ),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context, String content) {
    // TODO: 实现复制到剪贴板
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
