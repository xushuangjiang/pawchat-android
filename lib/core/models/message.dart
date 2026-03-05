import 'package:equatable/equatable.dart';

/// 消息角色枚举
enum MessageRole {
  user,
  assistant,
  system,
  tool;

  String get value => name;

  static MessageRole fromString(String value) {
    return MessageRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageRole.system,
    );
  }
}

/// 消息状态枚举
enum MessageStatus {
  pending,      // 等待发送
  sending,      // 发送中
  streaming,    // 流式接收中
  completed,    // 已完成
  failed,       // 发送失败
  aborted;      // 已中止

  bool get isFinal => this == MessageStatus.completed || 
                      this == MessageStatus.failed || 
                      this == MessageStatus.aborted;
}

/// 统一的消息模型
/// 
/// 用于表示聊天应用中的任何消息（用户、助手、系统）
class Message extends Equatable {
  /// 唯一标识符
  final String id;

  /// 消息角色
  final MessageRole role;

  /// 消息内容
  final String content;

  /// 创建时间
  final DateTime timestamp;

  /// 关联的运行 ID（用于流式响应）
  final String? runId;

  /// 消息状态
  final MessageStatus status;

  /// 会话密钥
  final String? sessionKey;

  /// 元数据（工具调用、附件等）
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.runId,
    this.status = MessageStatus.completed,
    this.sessionKey,
    this.metadata,
  });

  /// 从 JSON 创建
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      role: MessageRole.fromString(json['role'] as String? ?? 'system'),
      content: json['content'] as String? ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      runId: json['runId'] as String?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'completed'),
        orElse: () => MessageStatus.completed,
      ),
      sessionKey: json['sessionKey'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.value,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    if (runId != null) 'runId': runId,
    'status': status.name,
    if (sessionKey != null) 'sessionKey': sessionKey,
    if (metadata != null) 'metadata': metadata,
  };

  /// 复制并修改
  Message copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    String? runId,
    MessageStatus? status,
    String? sessionKey,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      runId: runId ?? this.runId,
      status: status ?? this.status,
      sessionKey: sessionKey ?? this.sessionKey,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 是否是用户消息
  bool get isUser => role == MessageRole.user;

  /// 是否是助手消息
  bool get isAssistant => role == MessageRole.assistant;

  /// 是否是系统消息
  bool get isSystem => role == MessageRole.system;

  /// 是否正在流式传输
  bool get isStreaming => status == MessageStatus.streaming;

  /// 是否已完成
  bool get isCompleted => status == MessageStatus.completed;

  /// 创建用户消息（工厂方法）
  factory Message.user({
    required String content,
    String? sessionKey,
    String? id,
  }) {
    return Message(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      sessionKey: sessionKey,
      status: MessageStatus.completed,
    );
  }

  /// 创建助手消息（工厂方法）
  factory Message.assistant({
    required String content,
    String? runId,
    String? sessionKey,
    MessageStatus status = MessageStatus.completed,
    String? id,
  }) {
    return Message(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      runId: runId,
      sessionKey: sessionKey,
      status: status,
    );
  }

  /// 创建流式消息（工厂方法）
  factory Message.streaming({
    required String content,
    required String runId,
    String? sessionKey,
    String? id,
  }) {
    return Message(
      id: id ?? '${runId}_stream',
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      runId: runId,
      sessionKey: sessionKey,
      status: MessageStatus.streaming,
    );
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.parse(ts);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now();
  }

  @override
  List<Object?> get props => [id, role, content, timestamp, runId, status, sessionKey];

  @override
  String toString() {
    final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
    return 'Message(id: $id, role: ${role.value}, status: ${status.name}, content: $preview)';
  }
}

/// 会话信息模型
class SessionInfo extends Equatable {
  final String sessionKey;
  final String? title;
  final DateTime lastActive;
  final int messageCount;
  final DateTime createdAt;

  const SessionInfo({
    required this.sessionKey,
    this.title,
    required this.lastActive,
    required this.messageCount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? lastActive;

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionKey: json['sessionKey'] as String,
      title: json['title'] as String?,
      lastActive: Message._parseTimestamp(json['lastActive']),
      messageCount: json['messageCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null 
          ? Message._parseTimestamp(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionKey': sessionKey,
    if (title != null) 'title': title,
    'lastActive': lastActive.toIso8601String(),
    'messageCount': messageCount,
    'createdAt': createdAt.toIso8601String(),
  };

  SessionInfo copyWith({
    String? sessionKey,
    String? title,
    DateTime? lastActive,
    int? messageCount,
    DateTime? createdAt,
  }) {
    return SessionInfo(
      sessionKey: sessionKey ?? this.sessionKey,
      title: title ?? this.title,
      lastActive: lastActive ?? this.lastActive,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [sessionKey, title, lastActive, messageCount, createdAt];
}
