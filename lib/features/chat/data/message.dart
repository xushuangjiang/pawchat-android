/// 消息模型
/// 
/// 表示一条聊天消息，包含角色、内容、时间戳等信息
class Message {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.sessionId,
    this.metadata,
  });

  /// 从 JSON 创建 Message
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      sessionId: json['sessionId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'metadata': metadata,
    };
  }

  /// 复制并修改
  Message copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.role == role &&
        other.content == content &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, role, content, timestamp);
  }
}
