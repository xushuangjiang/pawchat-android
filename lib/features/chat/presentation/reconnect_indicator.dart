import 'package:flutter/material.dart';

/// 自动重连指示器
/// 
/// 显示在聊天界面顶部，提示用户当前重连状态
class ReconnectIndicator extends StatelessWidget {
  /// 是否正在重连
  final bool isReconnecting;

  /// 当前重连尝试次数
  final int attempt;

  /// 最大重连次数
  final int maxAttempts;

  const ReconnectIndicator({
    super.key,
    required this.isReconnecting,
    required this.attempt,
    this.maxAttempts = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (!isReconnecting) {
      return const SizedBox.shrink();
    }

    final progress = attempt / maxAttempts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '正在重连... ($attempt/$maxAttempts)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onErrorContainer,
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 网络状态指示器 (小型)
/// 
/// 显示在 AppBar 或状态栏
class NetworkStatusIndicator extends StatelessWidget {
  /// 连接状态
  final bool isConnected;

  /// 是否正在重连
  final bool isReconnecting;

  const NetworkStatusIndicator({
    super.key,
    required this.isConnected,
    this.isReconnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String tooltip;

    if (isReconnecting) {
      statusColor = Colors.orange;
      tooltip = '正在重连...';
    } else if (isConnected) {
      statusColor = Colors.green;
      tooltip = '已连接';
    } else {
      statusColor = Colors.red;
      tooltip = '已断开';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
      ),
    );
  }
}
