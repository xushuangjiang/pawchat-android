import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message.dart';

/// 本地存储服务
/// 
/// 使用 Hive 进行高效的本地数据持久化
class LocalStorage {
  static const String _messagesBoxName = 'messages';
  static const String _settingsBoxName = 'settings';
  static const String _sessionsBoxName = 'sessions';
  
  Box<List<dynamic>>? _messagesBox;
  Box<dynamic>? _settingsBox;
  Box<Map<dynamic, dynamic>>? _sessionsBox;
  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化存储
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    _messagesBox = await Hive.openBox<List<dynamic>>(_messagesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _sessionsBox = await Hive.openBox<Map<dynamic, dynamic>>(_sessionsBoxName);
    
    _isInitialized = true;
  }

  // ========== 消息相关 ==========

  /// 保存会话的所有消息
  Future<void> saveMessages(String sessionKey, List<Message> messages) async {
    await _ensureInitialized();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await _messagesBox!.put(sessionKey, jsonList);
  }

  /// 加载会话的消息
  List<Message>? loadMessages(String sessionKey) {
    if (!_isInitialized) return null;
    
    final data = _messagesBox!.get(sessionKey);
    if (data == null) return null;
    
    try {
      return data
          .map((json) => Message.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      print('[LocalStorage] 解析消息失败: $e');
      return null;
    }
  }

  /// 追加单条消息
  Future<void> appendMessage(String sessionKey, Message message) async {
    await _ensureInitialized();
    
    final existing = loadMessages(sessionKey) ?? [];
    existing.add(message);
    
    await saveMessages(sessionKey, existing);
    
    // 同时更新会话信息
    await updateSessionInfo(sessionKey, lastActive: DateTime.now());
  }

  /// 删除会话的所有消息
  Future<void> deleteMessages(String sessionKey) async {
    await _ensureInitialized();
    await _messagesBox!.delete(sessionKey);
  }

  /// 获取所有有消息的会话密钥
  Future<List<String>> getAllSessions() async {
    await _ensureInitialized();
    return _messagesBox!.keys.cast<String>().toList();
  }

  /// 清空所有消息
  Future<void> clearAllMessages() async {
    await _ensureInitialized();
    await _messagesBox!.clear();
  }

  // ========== 会话信息相关 ==========

  /// 保存会话信息
  Future<void> saveSessionInfo(SessionInfo info) async {
    await _ensureInitialized();
    await _sessionsBox!.put(info.sessionKey, info.toJson());
  }

  /// 获取会话信息
  SessionInfo? getSessionInfo(String sessionKey) {
    if (!_isInitialized) return null;
    
    final data = _sessionsBox!.get(sessionKey);
    if (data == null) return null;
    
    try {
      return SessionInfo.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('[LocalStorage] 解析会话信息失败: $e');
      return null;
    }
  }

  /// 更新会话信息
  Future<void> updateSessionInfo(
    String sessionKey, {
    String? title,
    DateTime? lastActive,
    int? messageCount,
  }) async {
    await _ensureInitialized();
    
    var info = getSessionInfo(sessionKey);
    if (info == null) {
      // 创建新会话信息
      final messages = loadMessages(sessionKey) ?? [];
      info = SessionInfo(
        sessionKey: sessionKey,
        title: title ?? sessionKey,
        lastActive: lastActive ?? DateTime.now(),
        messageCount: messageCount ?? messages.length,
      );
    } else {
      // 更新现有会话信息
      info = info.copyWith(
        title: title,
        lastActive: lastActive,
        messageCount: messageCount,
      );
    }
    
    await saveSessionInfo(info);
  }

  /// 获取所有会话信息
  List<SessionInfo> getAllSessionInfos() {
    if (!_isInitialized) return [];
    
    return _sessionsBox!.values
        .map((data) {
          try {
            return SessionInfo.fromJson(Map<String, dynamic>.from(data));
          } catch (e) {
            return null;
          }
        })
        .whereType<SessionInfo>()
        .toList()
      ..sort((a, b) => b.lastActive.compareTo(a.lastActive));
  }

  /// 删除会话信息
  Future<void> deleteSessionInfo(String sessionKey) async {
    await _ensureInitialized();
    await _sessionsBox!.delete(sessionKey);
  }

  // ========== 设置相关 ==========

  /// 保存字符串设置
  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// 获取字符串设置
  String? getString(String key) {
    if (!_isInitialized) return null;
    return _settingsBox!.get(key) as String?;
  }

  /// 保存布尔设置
  Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// 获取布尔设置
  bool getBool(String key, {bool defaultValue = false}) {
    if (!_isInitialized) return defaultValue;
    return _settingsBox!.get(key) as bool? ?? defaultValue;
  }

  /// 保存整数设置
  Future<void> setInt(String key, int value) async {
    await _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// 获取整数设置
  int? getInt(String key) {
    if (!_isInitialized) return null;
    return _settingsBox!.get(key) as int?;
  }

  /// 删除设置
  Future<void> removeSetting(String key) async {
    await _ensureInitialized();
    await _settingsBox!.delete(key);
  }

  // ========== 快捷方法 ==========

  /// 保存最后使用的会话
  Future<void> saveLastSession(String sessionKey) async {
    await setString('last_session', sessionKey);
  }

  /// 获取最后使用的会话
  String? getLastSession() {
    return getString('last_session');
  }

  /// 保存 Gateway URL
  Future<void> saveGatewayUrl(String url) async {
    await setString('gateway_url', url);
  }

  /// 获取 Gateway URL
  String? getGatewayUrl() {
    return getString('gateway_url');
  }

  /// 保存认证 Token
  Future<void> saveToken(String token) async {
    await setString('gateway_token', token);
  }

  /// 获取认证 Token
  String? getToken() {
    return getString('gateway_token');
  }

  // ========== 私有方法 ==========

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 关闭存储（应用退出时调用）
  Future<void> close() async {
    if (_isInitialized) {
      await _messagesBox?.close();
      await _settingsBox?.close();
      await _sessionsBox?.close();
      _isInitialized = false;
    }
  }
}
