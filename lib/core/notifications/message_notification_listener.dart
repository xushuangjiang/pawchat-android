import 'package:flutter/foundation.dart';

import '../bloc/chat_bloc.dart';
import '../data/message.dart';
import 'notification_service.dart';

/// 消息通知监听器
/// 
/// 监听 ChatBloc 状态变化，在新消息到达时显示通知
class MessageNotificationListener {
  final NotificationService _notificationService;
  String? _currentSessionKey;
  bool _isAppInForeground = false;

  MessageNotificationListener({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  /// 初始化监听器
  void initialize() {
    debugPrint('[MessageNotificationListener] 初始化');
    // TODO: 监听应用前后台状态
  }

  /// 设置当前会话
  /// 
  /// 如果新消息属于当前会话，不显示通知 (用户正在查看)
  void setCurrentSession(String? sessionKey) {
    _currentSessionKey = sessionKey;
    debugPrint('[MessageNotificationListener] 当前会话：$sessionKey');
  }

  /// 设置应用前后台状态
  void setAppInForeground(bool inForeground) {
    _isAppInForeground = inForeground;
    debugPrint('[MessageNotificationListener] 应用在前台：$inForeground');
  }

  /// 处理新消息
  /// 
  /// 如果消息不属于当前会话且应用在后台，显示通知
  Future<void> onNewMessage(Message message, String sessionKey) async {
    // 如果是用户自己发送的消息，不显示通知
    if (message.role == 'user') {
      return;
    }

    // 如果应用在前台，不显示通知
    if (_isAppInForeground) {
      debugPrint('[MessageNotificationListener] 应用在前台，跳过通知');
      return;
    }

    // 如果消息属于当前会话，不显示通知
    if (sessionKey == _currentSessionKey) {
      debugPrint('[MessageNotificationListener] 当前会话消息，跳过通知');
      return;
    }

    // 显示通知
    debugPrint('[MessageNotificationListener] 显示新消息通知');
    await _notificationService.showMessageNotification(
      title: '新消息',
      body: _truncateMessage(message.content),
      sessionId: sessionKey,
    );
  }

  /// 截断消息内容 (用于通知预览)
  String _truncateMessage(String content, {int maxLength = 100}) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }

  /// 销毁
  void dispose() {
    debugPrint('[MessageNotificationListener] 销毁');
  }
}
