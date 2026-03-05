import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  
  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onRetry,
    this.onCopy,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(theme),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBubbleColor(theme, isUser),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(theme, isUser),
                    if (isStreaming) ...[
                      const SizedBox(height: 8),
                      _buildStreamingIndicator(theme, isUser),
                    ],
                    if (!isStreaming) ...[
                      const SizedBox(height: 4),
                      _buildFooter(theme, isUser),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return CircleAvatar(
      backgroundColor: theme.colorScheme.primary,
      radius: 16,
      child: const Text('🐾', style: TextStyle(fontSize: 16)),
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isUser) {
    if (isUser) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  Widget _buildContent(ThemeData theme, bool isUser) {
    final textColor = isUser 
        ? theme.colorScheme.onPrimary 
        : theme.colorScheme.onSurfaceVariant;

    return SelectionArea(
      child: MarkdownBody(
        data: message.content,
        selectable: false,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: textColor,
            fontSize: 15,
            height: 1.5,
          ),
          code: TextStyle(
            backgroundColor: isUser 
                ? theme.colorScheme.primary.withAlpha(50)
                : theme.colorScheme.surface.withAlpha(50),
            fontFamily: 'monospace',
            fontSize: 13,
            color: textColor,
          ),
          codeblockDecoration: BoxDecoration(
            color: isUser 
                ? theme.colorScheme.primary.withAlpha(30)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: TextStyle(
            color: textColor.withAlpha(200),
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: textColor.withAlpha(100),
                width: 4,
              ),
            ),
          ),
          listBullet: TextStyle(color: textColor),
          h1: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          h2: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          h3: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          a: TextStyle(
            color: isUser 
                ? theme.colorScheme.onPrimary.withAlpha(230)
                : theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (text, href, title) {
          if (href != null) {
            // TODO: 打开链接
          }
        },
      ),
    );
  }

  Widget _buildStreamingIndicator(ThemeData theme, bool isUser) {
    final indicatorColor = isUser 
        ? theme.colorScheme.onPrimary.withAlpha(180)
        : theme.colorScheme.onSurfaceVariant.withAlpha(180);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '思考中...',
          style: TextStyle(
            fontSize: 12,
            color: indicatorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, bool isUser) {
    final textColor = isUser 
        ? theme.colorScheme.onPrimary.withAlpha(180)
        : theme.colorScheme.onSurfaceVariant.withAlpha(180);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: textColor,
          ),
        ),
        if (message.status == MessageStatus.failed) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.error_outline,
            size: 12,
            color: theme.colorScheme.error,
          ),
        ],
      ],
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(context);
                onCopy?.call();
              },
            ),
            if (message.status == MessageStatus.failed && onRetry != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重试'),
                onTap: () {
                  Navigator.pop(context);
                  onRetry?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现分享
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
