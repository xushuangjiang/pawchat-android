import 'dart:convert';

/// Gateway 消息基类
class GatewayMessage {
  final String type;
  final String? event;
  final String? sessionKey;
  final String? runId;
  final Map<String, dynamic>? data;
  final String? content;
  final String? status;
  
  GatewayMessage({
    required this.type,
    this.event,
    this.sessionKey,
    this.runId,
    this.data,
    this.content,
    this.status,
  });
  
  factory GatewayMessage.fromJson(Map<String, dynamic> json) {
    return GatewayMessage(
      type: json['type'] as String? ?? 'unknown',
      event: json['event'] as String?,
      sessionKey: json['sessionKey'] as String?,
      runId: json['runId'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      content: json['content'] as String?,
      status: json['status'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'type': type,
    if (event != null) 'event': event,
    if (sessionKey != null) 'sessionKey': sessionKey,
    if (runId != null) 'runId': runId,
    if (data != null) 'data': data,
    if (content != null) 'content': content,
    if (status != null) 'status': status,
  };
}

/// 聊天消息
class ChatMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final String? runId;
  final bool? isStreaming;
  final bool? isAborted;
  
  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.runId,
    this.isStreaming,
    this.isAborted,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      runId: json['runId'] as String?,
      isStreaming: json['isStreaming'] as bool?,
      isAborted: json['isAborted'] as bool?,
    );
  }
  
  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.parse(ts);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now();
  }
  
  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    if (runId != null) 'runId': runId,
    if (isStreaming != null) 'isStreaming': isStreaming,
    if (isAborted != null) 'isAborted': isAborted,
  };
}

/// chat.send 响应
class ChatSendResponse {
  final String runId;
  final String status; // 'started' | 'in_flight' | 'ok'
  
  ChatSendResponse({
    required this.runId,
    required this.status,
  });
  
  factory ChatSendResponse.fromJson(Map<String, dynamic> json) {
    return ChatSendResponse(
      runId: json['runId'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'runId': runId,
    'status': status,
  };
}

/// 设备配对请求
class PairingRequest {
  final String requestId;
  final String deviceId;
  final String? deviceName;
  final DateTime createdAt;
  
  PairingRequest({
    required this.requestId,
    required this.deviceId,
    this.deviceName,
    required this.createdAt,
  });
  
  factory PairingRequest.fromJson(Map<String, dynamic> json) {
    return PairingRequest(
      requestId: json['requestId'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }
  
  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.parse(ts);
    return DateTime.now();
  }
}

/// 工具调用事件 (用于显示工具执行状态)
class ToolCallEvent {
  final String toolName;
  final Map<String, dynamic>? input;
  final String? output;
  final String status; // 'pending' | 'running' | 'completed' | 'failed'
  
  ToolCallEvent({
    required this.toolName,
    this.input,
    this.output,
    required this.status,
  });
  
  factory ToolCallEvent.fromJson(Map<String, dynamic> json) {
    return ToolCallEvent(
      toolName: json['toolName'] as String,
      input: json['input'] as Map<String, dynamic>?,
      output: json['output'] as String?,
      status: json['status'] as String? ?? 'unknown',
    );
  }
}

/// 会话信息
class SessionInfo {
  final String sessionKey;
  final String? title;
  final DateTime lastActive;
  final int messageCount;
  
  SessionInfo({
    required this.sessionKey,
    this.title,
    required this.lastActive,
    required this.messageCount,
  });
  
  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionKey: json['sessionKey'] as String,
      title: json['title'] as String?,
      lastActive: _parseTimestamp(json['lastActive']),
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }
  
  static DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.parse(ts);
    return DateTime.now();
  }
}
