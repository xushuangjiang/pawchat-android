import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'message_model.dart';

/// 消息存储
class MessageStore {
  static const String _key = 'chat_messages';
  
  /// 保存消息列表
  static Future<void> saveMessages(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final data = messages.map((m) => {
      'id': m.id,
      'role': m.role.name,
      'content': m.content,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    await prefs.setString(_key, jsonEncode(data));
  }
  
  /// 加载消息列表
  static Future<List<Message>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    
    try {
      final data = jsonDecode(json) as List;
      return data.map((item) => Message(
        id: item['id'],
        role: MessageRole.values.byName(item['role']),
        content: item['content'],
        timestamp: DateTime.parse(item['timestamp']),
      )).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 清空消息
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
