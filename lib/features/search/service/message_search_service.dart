import 'package:flutter/material.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/models/message.dart';

/// 消息搜索服务
/// 
/// 提供本地消息缓存的搜索功能
class MessageSearchService {
  final LocalStorage _storage;

  MessageSearchService({required LocalStorage storage}) : _storage = storage;

  /// 搜索消息
  /// 
  /// [query] - 搜索关键词
  /// [sessionKey] - 可选，限制在特定会话中搜索
  /// [limit] - 最大返回结果数
  Future<List<SearchResult>> search({
    required String query,
    String? sessionKey,
    int limit = 50,
  }) async {
    debugPrint('[MessageSearch] 搜索："$query" in ${sessionKey ?? "all sessions"}');

    if (query.trim().isEmpty) return [];

    final queryLower = query.toLowerCase();
    final results = <SearchResult>[];

    // 获取要搜索的会话列表
    final sessions = sessionKey != null
        ? [sessionKey]
        : await _storage.getAllSessions();

    for (final session in sessions) {
      final messages = _storage.loadMessages(session) ?? [];
      
      for (final message in messages) {
        final content = message.content.toLowerCase();
        if (content.contains(queryLower)) {
          // 找到匹配位置
          final matchStart = content.indexOf(queryLower);
          final context = _extractContext(content, matchStart, query.length);
          
          results.add(SearchResult(
            message: message,
            sessionKey: session,
            matchStart: matchStart,
            matchLength: query.length,
            context: context,
          ));

          if (results.length >= limit) break;
        }
      }

      if (results.length >= limit) break;
    }

    debugPrint('[MessageSearch] 找到 ${results.length} 条结果');
    return results;
  }

  /// 高级搜索 - 支持多个条件
  Future<List<SearchResult>> advancedSearch({
    String? keyword,
    String? sessionKey,
    MessageRole? role,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final results = <SearchResult>[];
    final sessions = sessionKey != null
        ? [sessionKey]
        : await _storage.getAllSessions();

    for (final session in sessions) {
      final messages = _storage.loadMessages(session) ?? [];
      
      for (final message in messages) {
        // 角色过滤
        if (role != null && message.role != role) continue;
        
        // 日期范围过滤
        if (startDate != null && message.timestamp.isBefore(startDate)) continue;
        if (endDate != null && message.timestamp.isAfter(endDate)) continue;
        
        // 关键词过滤
        if (keyword != null && keyword.isNotEmpty) {
          final content = message.content.toLowerCase();
          final queryLower = keyword.toLowerCase();
          
          if (!content.contains(queryLower)) continue;
          
          final matchStart = content.indexOf(queryLower);
          final context = _extractContext(content, matchStart, keyword.length);
          
          results.add(SearchResult(
            message: message,
            sessionKey: session,
            matchStart: matchStart,
            matchLength: keyword.length,
            context: context,
          ));
        } else {
          // 无关键词，只按其他条件过滤
          results.add(SearchResult(
            message: message,
            sessionKey: session,
            matchStart: 0,
            matchLength: 0,
            context: message.content.length > 100 
                ? '${message.content.substring(0, 100)}...'
                : message.content,
          ));
        }

        if (results.length >= limit) break;
      }

      if (results.length >= limit) break;
    }

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
class SearchResult {
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

  const SearchResult({
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

  /// 获取相对时间
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(message.timestamp);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return displayTime;
  }
}
