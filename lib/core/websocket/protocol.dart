import '../models/message.dart';

/// Gateway 消息类型枚举
enum GatewayMessageType {
  chat,
  response,
  error,
  system,
  event,
  unknown;

  static GatewayMessageType fromString(String value) {
    return GatewayMessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GatewayMessageType.unknown,
    );
  }
}

/// Gateway 消息基类
/// 
/// 表示从 Gateway 接收到的任何消息
class GatewayMessage {
  final GatewayMessageType type;
  final String? event;
  final String? sessionKey;
  final String? runId;
  final Map<String, dynamic>? data;
  final String? content;
  final String? status;
  final String? errorCode;
  final String? errorMessage;
  
  const GatewayMessage({
    required this.type,
    this.event,
    this.sessionKey,
    this.runId,
    this.data,
    this.content,
    this.status,
    this.errorCode,
    this.errorMessage,
  });
  
  factory GatewayMessage.fromJson(Map<String, dynamic> json) {
    return GatewayMessage(
      type: GatewayMessageType.fromString(json['type'] as String? ?? 'unknown'),
      event: json['event'] as String?,
      sessionKey: json['sessionKey'] as String?,
      runId: json['runId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      content: json['content'] as String?,
      status: json['status'] as String?,
      errorCode: json['error']?['code'] as String?,
      errorMessage: json['error']?['message'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (event != null) 'event': event,
    if (sessionKey != null) 'sessionKey': sessionKey,
    if (runId != null) 'runId': runId,
    if (data != null) 'data': data,
    if (content != null) 'content': content,
    if (status != null) 'status': status,
    if (errorCode != null || errorMessage != null)
      'error': {
        if (errorCode != null) 'code': errorCode,
        if (errorMessage != null) 'message': errorMessage,
      },
  };

  /// 是否是错误消息
  bool get isError => type == GatewayMessageType.error || errorCode != null;

  /// 是否是配对错误
  bool get isPairingRequired => errorCode == 'pairing_required';

  /// 转换为 Message 对象（如果是聊天消息）
  Message? toMessage() {
    if (type != GatewayMessageType.chat && type != GatewayMessageType.response) {
      return null;
    }

    final role = _parseRole();
    final messageStatus = _parseStatus();

    return Message(
      id: runId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: role,
      content: content ?? '',
      timestamp: DateTime.now(),
      runId: runId,
      status: messageStatus,
      sessionKey: sessionKey,
    );
  }

  MessageRole _parseRole() {
    if (data?['role'] != null) {
      return MessageRole.fromString(data!['role'] as String);
    }
    // 根据消息类型推断角色
    if (type == GatewayMessageType.response) {
      return MessageRole.assistant;
    }
    return MessageRole.system;
  }

  MessageStatus _parseStatus() {
    if (status == null) return MessageStatus.completed;
    return MessageStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MessageStatus.completed,
    );
  }
}

/// chat.send 响应
class ChatSendResponse {
  final String runId;
  final String status; // 'started' | 'in_flight' | 'ok'
  final Map<String, dynamic>? metadata;
  
  const ChatSendResponse({
    required this.runId,
    required this.status,
    this.metadata,
  });
  
  factory ChatSendResponse.fromJson(Map<String, dynamic> json) {
    return ChatSendResponse(
      runId: json['runId'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'runId': runId,
    'status': status,
    if (metadata != null) 'metadata': metadata,
  };

  bool get isStarted => status == 'started' || status == 'in_flight';
  bool get isOk => status == 'ok';
}

/// 设备配对请求
class PairingRequest {
  final String requestId;
  final String deviceId;
  final String? deviceName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  
  const PairingRequest({
    required this.requestId,
    required this.deviceId,
    this.deviceName,
    required this.createdAt,
    this.expiresAt,
  });
  
  factory PairingRequest.fromJson(Map<String, dynamic> json) {
    return PairingRequest(
      requestId: json['requestId'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      expiresAt: json['expiresAt'] != null 
          ? _parseTimestamp(json['expiresAt'])
          : null,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Duration? get timeRemaining => expiresAt?.difference(DateTime.now());
  
  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.parse(ts);
    return DateTime.now();
  }
}

/// 工具调用事件（用于显示工具执行状态）
class ToolCallEvent {
  final String toolName;
  final Map<String, dynamic>? input;
  final String? output;
  final ToolCallStatus status;
  final DateTime timestamp;
  final Duration? duration;
  
  const ToolCallEvent({
    required this.toolName,
    this.input,
    this.output,
    required this.status,
    DateTime? timestamp,
    this.duration,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory ToolCallEvent.fromJson(Map<String, dynamic> json) {
    return ToolCallEvent(
      toolName: json['toolName'] as String,
      input: json['input'] as Map<String, dynamic>?,
      output: json['output'] as String?,
      status: ToolCallStatus.fromString(json['status'] as String? ?? 'unknown'),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
    );
  }

  String get displayName {
    // 将 snake_case 转换为可读名称
    return toolName
        .split('_')
        .map((s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }
}

enum ToolCallStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  unknown;

  static ToolCallStatus fromString(String value) {
    return ToolCallStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ToolCallStatus.unknown,
    );
  }

  String get displayText {
    switch (this) {
      case ToolCallStatus.pending:
        return '等待中';
      case ToolCallStatus.running:
        return '执行中';
      case ToolCallStatus.completed:
        return '已完成';
      case ToolCallStatus.failed:
        return '失败';
      case ToolCallStatus.cancelled:
        return '已取消';
      case ToolCallStatus.unknown:
        return '未知';
    }
  }
}

/// 会话信息
class SessionInfo {
  final String sessionKey;
  final String title;
  final DateTime lastActive;
  final int messageCount;

  const SessionInfo({
    required this.sessionKey,
    required this.title,
    required this.lastActive,
    required this.messageCount,
  });
}
