import 'package:flutter/material.dart';

import '../../../core/storage/local_storage.dart';
import '../../../features/chat/data/message.dart';

/// 消息搜索服务
/// 
/// 提供本地消息缓存的搜索功能
class MessageSearchService {
  final LocalStorage _storage;

  MessageSearchService({required LocalStorage storage})
      : _storage = storage;

  /// 搜索消息
  /// 
  /// [query] - 搜索关键词
  /// [sessionKey] - 可选，限制在特定会话中搜索
  /// [limit] - 最大返回结果数
  Future<List<SearchedMessage>> search({
    required String query,
    String? sessionKey,
    int limit = 50,
  }) async {
    debugPrint('[MessageSearch] 搜索："$query" in ${sessionKey ?? "all sessions"}');

    final queryLower = query.toLowerCase();
    final results = <SearchedMessage>[];

    // 获取要搜索的会话列表
    final sessions = sessionKey != null
        ? [sessionKey]
        : await _storage.getAllSessions();

    for (final session in sessions) {
      final chatMessages = await _storage.loadMessages(session) ?? [];
      
      for (final chatMessage in chatMessages) {
        // 将 ChatMessage 转换为 Message (ChatMessage 没有 messageId 字段，使用 content 作为唯一标识)
        final message = Message(
          id: chatMessage.content, // 使用 content 作为临时 id
          role: chatMessage.role,
          content: chatMessage.content,
          timestamp: chatMessage.timestamp,
        );
        
        final content = message.content.toLowerCase();
        if (content.contains(queryLower)) {
          // 找到匹配位置
          final matchStart = content.indexOf(queryLower);
          final context = _extractContext(content, matchStart, query.length);
          
          results.add(SearchedMessage(
            message: message,
            sessionKey: session,
            matchStart: matchStart,
            matchLength: query.length,
            context: context,
          ));

          if (results.length >= limit) {
            break;
          }
        }
      }

      if (results.length >= limit) {
        break;
      }
    }

    debugPrint('[MessageSearch] 找到 ${results.length} 条结果');
    return results;
  }

  /// 提取上下文 (前后各 50 字符)
  String _extractContext(String content, int matchStart, int matchLength) {
    const contextLength = 50;
    final start = (matchStart - contextLength).clamp(0, content.length);
    final end = (matchStart + matchLength + contextLength).clamp(0, content.length);
    
    var context = content.substring(start, end);
    
    // 添加省略号
    if (start > 0) context = '...$context';
    if (end < content.length) context = '$context...';
    
    return context;
  }

  /// 高亮文本中的匹配部分
  static List<TextSpan> highlightMatches({
    required String text,
    required String query,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }

    final spans = <TextSpan>[];
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    
    int start = 0;
    int index;

    while ((index = textLower.indexOf(queryLower, start)) != -1) {
      // 添加匹配前的普通文本
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }

      // 添加高亮的匹配文本
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle,
      ));

      start = index + query.length;
    }

    // 添加剩余的普通文本
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }

    return spans;
  }
}

/// 搜索结果
class SearchedMessage {
  /// 原始消息
  final Message message;

  /// 所属会话
  final String sessionKey;

  /// 匹配开始位置
  final int matchStart;

  /// 匹配长度
  final int matchLength;

  /// 上下文 (包含匹配内容的前后文本)
  final String context;

  SearchedMessage({
    required this.message,
    required this.sessionKey,
    required this.matchStart,
    required this.matchLength,
    required this.context,
  });

  /// 获取显示时间
  String get displayTime {
    final date = message.timestamp;
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
