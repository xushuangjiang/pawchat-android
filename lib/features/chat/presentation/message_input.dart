import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onAbort;
  final bool isStreaming;
  
  const MessageInput({
    super.key,
    required this.onSend,
    this.onAbort,
    this.isStreaming = false,
  });
  
  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: widget.isStreaming
            ? _buildAbortBar(theme)
            : _buildInputField(theme),
      ),
    );
  }
  
  Widget _buildAbortBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI 正在思考...',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onAbort,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('停止'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputField(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 附件按钮 (预留功能)
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            // TODO: 附件功能
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('附件功能开发中...')),
            );
          },
          color: theme.colorScheme.onSurfaceVariant,
        ),
        // 输入框
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 发送按钮
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send),
            color: theme.colorScheme.onPrimary,
            onPressed: _controller.text.trim().isNotEmpty 
                ? _sendMessage 
                : null,
          ),
        ),
      ],
    );
  }
  
  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    
    widget.onSend(content);
    _controller.clear();
    _focusNode.requestFocus();
  }
}
