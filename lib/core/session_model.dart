/// 会话模型
class Session {
  final String key;
  final String? title;
  final DateTime updatedAt;
  final int messageCount;
  final bool isActive;

  Session({
    required this.key,
    this.title,
    required this.updatedAt,
    this.messageCount = 0,
    this.isActive = false,
  });

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return '会话 ${key.substring(key.length > 8 ? key.length - 8 : 0)}';
  }

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${updatedAt.month}/${updatedAt.day}';
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      key: json['key'] ?? '',
      title: json['title'],
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      messageCount: json['messageCount'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'updatedAt': updatedAt.toIso8601String(),
      'messageCount': messageCount,
      'isActive': isActive,
    };
  }

  Session copyWith({
    String? key,
    String? title,
    DateTime? updatedAt,
    int? messageCount,
    bool? isActive,
  }) {
    return Session(
      key: key ?? this.key,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
