import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'message_model.dart';

/// 消息操作工具类
class MessageActions {
  /// 显示消息操作菜单
  static void showMessageMenu(
    BuildContext context,
    Message message, {
    VoidCallback? onDelete,
    VoidCallback? onRetry,
  }) {
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
                _copyToClipboard(context, message.content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('选择文本'),
              onTap: () {
                Navigator.pop(context);
                _showSelectableText(context, message);
              },
            ),
            if (onRetry != null && message.status == MessageStatus.error)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重试'),
                onTap: () {
                  Navigator.pop(context);
                  onRetry();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade400),
                title: Text('删除', style: TextStyle(color: Colors.red.shade400)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, onDelete);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 复制到剪贴板
  static void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示可选择文本对话框
  static void _showSelectableText(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              message.role == MessageRole.user ? Icons.person : Icons.smart_toy,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message.role == MessageRole.user ? '用户消息' : 'AI 回复'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(message.content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              _copyToClipboard(context, message.content);
              Navigator.pop(context);
            },
            child: const Text('复制全部'),
          ),
        ],
      ),
    );
  }

  /// 确认删除
  static void _confirmDelete(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示重连状态
  static void showReconnectionSnackBar(
    BuildContext context, {
    required int attempt,
    required int maxAttempts,
    VoidCallback? onCancel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('正在重连... ($attempt/$maxAttempts)'),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: onCancel != null
            ? SnackBarAction(
                label: '取消',
                onPressed: onCancel,
              )
            : null,
      ),
    );
  }

  /// 显示连接成功
  static void showConnectedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('已连接到 Gateway'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示连接断开
  static void showDisconnectedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('连接已断开'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
