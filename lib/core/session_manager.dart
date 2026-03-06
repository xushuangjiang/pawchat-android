import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_model.dart';

/// 会话管理器
class SessionManager {
  static const String _sessionsKey = 'sessions_list';
  static const String _currentSessionKey = 'current_session_key';
  
  final List<Session> _sessions = [];
  String? _currentSessionKey;
  
  List<Session> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionKey => _currentSessionKey;
  
  Session? get currentSession {
    if (_currentSessionKey == null) return null;
    try {
      return _sessions.firstWhere((s) => s.key == _currentSessionKey);
    } catch (e) {
      return null;
    }
  }

  /// 加载会话列表
  Future<void> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_sessionsKey);
    
    if (json != null) {
      try {
        final data = jsonDecode(json) as List;
        _sessions.clear();
        _sessions.addAll(
          data.map((item) => Session.fromJson(item)),
        );
      } catch (e) {
        print('加载会话失败: $e');
      }
    }
    
    _currentSessionKey = prefs.getString(_currentSessionKey);
  }

  /// 保存会话列表
  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionsKey, jsonEncode(data));
  }

  /// 创建新会话
  Future<Session> createSession({String? title}) async {
    final key = 'session-${DateTime.now().millisecondsSinceEpoch}';
    final session = Session(
      key: key,
      title: title,
      updatedAt: DateTime.now(),
      isActive: true,
    );
    
    _sessions.insert(0, session);
    _currentSessionKey = key;
    
    await _saveSessions();
    await _saveCurrentSession();
    
    return session;
  }

  /// 切换当前会话
  Future<void> switchSession(String key) async {
    _currentSessionKey = key;
    await _saveCurrentSession();
  }

  /// 更新会话
  Future<void> updateSession(Session session) async {
    final index = _sessions.indexWhere((s) => s.key == session.key);
    if (index >= 0) {
      _sessions[index] = session;
      await _saveSessions();
    }
  }

  /// 删除会话
  Future<void> deleteSession(String key) async {
    _sessions.removeWhere((s) => s.key == key);
    
    if (_currentSessionKey == key) {
      _currentSessionKey = _sessions.isNotEmpty ? _sessions.first.key : null;
    }
    
    await _saveSessions();
    await _saveCurrentSession();
  }

  /// 更新会话时间
  Future<void> updateSessionTime(String key) async {
    final index = _sessions.indexWhere((s) => s.key == key);
    if (index >= 0) {
      _sessions[index] = _sessions[index].copyWith(
        updatedAt: DateTime.now(),
      );
      // 移动到最前面
      final session = _sessions.removeAt(index);
      _sessions.insert(0, session);
      await _saveSessions();
    }
  }

  /// 保存当前会话
  Future<void> _saveCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentSessionKey != null) {
      await prefs.setString(_currentSessionKey, _currentSessionKey!);
    } else {
      await prefs.remove(_currentSessionKey);
    }
  }

  /// 清空所有会话
  Future<void> clearAll() async {
    _sessions.clear();
    _currentSessionKey = null;
    await _saveSessions();
    await _saveCurrentSession();
  }

  /// 从 Gateway 同步会话
  void syncFromGateway(List<dynamic> gatewaySessions) {
    for (final data in gatewaySessions) {
      final key = data['key'];
      final existingIndex = _sessions.indexWhere((s) => s.key == key);
      
      final session = Session(
        key: key,
        title: data['title'],
        updatedAt: DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now(),
        messageCount: data['messageCount'] ?? 0,
      );
      
      if (existingIndex >= 0) {
        _sessions[existingIndex] = session;
      } else {
        _sessions.add(session);
      }
    }
    
    // 按时间排序
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _saveSessions();
  }
}
