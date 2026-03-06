/// 消息角色
enum MessageRole { user, assistant, system }

/// 消息状态
enum MessageStatus { sending, sent, streaming, completed, error }

/// 消息模型
class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isStreaming;
  final String? sessionKey;
  final String? errorMessage;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.completed,
    this.isStreaming = false,
    this.sessionKey,
    this.errorMessage,
  });

  /// 创建用户消息
  factory Message.user(String content, {String? sessionKey}) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      sessionKey: sessionKey,
    );
  }

  /// 创建助手消息（流式）
  factory Message.assistantStreaming({String? sessionKey}) {
    return Message(
      id: 'streaming-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: MessageStatus.streaming,
      isStreaming: true,
      sessionKey: sessionKey,
    );
  }

  /// 创建系统消息
  factory Message.system(String content) {
    return Message(
      id: 'system-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.completed,
    );
  }

  /// 更新内容（用于流式响应）
  Message copyWith({
    String? content,
    MessageStatus? status,
    bool? isStreaming,
    String? errorMessage,
  }) {
    return Message(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      status: status ?? this.status,
      isStreaming: isStreaming ?? this.isStreaming,
      sessionKey: sessionKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 标记为已发送
  Message markAsSent() {
    return copyWith(status: MessageStatus.sent);
  }

  /// 标记为已完成
  Message markAsCompleted() {
    return copyWith(
      status: MessageStatus.completed,
      isStreaming: false,
    );
  }

  /// 标记为错误
  Message markAsError(String error) {
    return copyWith(
      status: MessageStatus.error,
      errorMessage: error,
      isStreaming: false,
    );
  }
}
