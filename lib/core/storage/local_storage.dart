import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../websocket/protocol.dart';

/// 本地存储管理器
class LocalStorage {
  static const String _keyMessages = 'chat_messages';
  static const String _keySettings = 'app_settings';
  static const String _keyLastSession = 'last_session_key';
  
  final SharedPreferences _prefs;
  
  LocalStorage(this._prefs);
  
  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }
  
  // ========== 消息缓存 ==========
  
  /// 保存消息列表
  Future<void> saveMessages(String sessionKey, List<ChatMessage> messages) async {
    final data = messages.map((m) => m.toJson()).toList();
    await _prefs.setString('$_keyMessages:$sessionKey', jsonEncode(data));
  }
  
  /// 加载消息列表
  List<ChatMessage>? loadMessages(String sessionKey) {
    final data = _prefs.getString('$_keyMessages:$sessionKey');
    if (data == null) return null;
    
    try {
      final list = jsonDecode(data) as List;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }
  
  /// 追加单条消息
  Future<void> appendMessage(String sessionKey, ChatMessage message) async {
    final messages = loadMessages(sessionKey) ?? <ChatMessage>[];
    messages.add(message);
    await saveMessages(sessionKey, messages);
  }
  
  /// 清除消息缓存
  Future<void> clearMessages(String sessionKey) async {
    await _prefs.remove('$_keyMessages:$sessionKey');
  }
  
  // ========== 设置 ==========
  
  /// 保存 Gateway 配置
  Future<void> saveGatewayConfig({
    required String host,
    int port = 18789,
    String? token,
    bool useSecure = false,
    bool autoConnect = false,
  }) async {
    await _prefs.setString('gateway_host', host);
    await _prefs.setInt('gateway_port', port);
    await _prefs.setString('gateway_token', token ?? '');
    await _prefs.setBool('gateway_secure', useSecure);
    await _prefs.setBool('auto_connect', autoConnect);
  }
  
  /// 加载 Gateway 配置
  Map<String, dynamic> loadGatewayConfig() {
    return {
      'host': _prefs.getString('gateway_host') ?? '192.168.1.100',
      'port': _prefs.getInt('gateway_port') ?? 18789,
      'token': _prefs.getString('gateway_token') ?? '',
      'useSecure': _prefs.getBool('gateway_secure') ?? false,
      'autoConnect': _prefs.getBool('auto_connect') ?? false,
    };
  }
  
  // ========== 会话管理 ==========
  
  /// 保存最后使用的会话
  Future<void> saveLastSession(String sessionKey) async {
    await _prefs.setString(_keyLastSession, sessionKey);
  }
  
  /// 获取最后使用的会话
  String? getLastSession() {
    return _prefs.getString(_keyLastSession);
  }
  
  /// 获取所有会话 key
  List<String> getAllSessions() {
    final keys = _prefs.getKeys();
    return keys
        .where((key) => key.startsWith('$_keyMessages:'))
        .map((key) => key.substring('$_keyMessages:'.length))
        .toList();
  }
  
  // ========== 工具方法 ==========
  
  /// 清除所有数据
  Future<void> clearAll() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
  
  /// 导出配置 (用于备份)
  Future<String> exportConfig() async {
    final config = {
      'gateway': loadGatewayConfig(),
      'lastSession': getLastSession(),
    };
    return jsonEncode(config);
  }
  
  /// 导入配置 (从备份恢复)
  Future<void> importConfig(String jsonStr) async {
    final config = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    if (config.containsKey('gateway')) {
      final gateway = config['gateway'] as Map<String, dynamic>;
      await saveGatewayConfig(
        host: gateway['host'] as String,
        port: gateway['port'] as int,
        token: gateway['token'] as String?,
        useSecure: gateway['useSecure'] as bool,
        autoConnect: gateway['autoConnect'] as bool,
      );
    }
    
    if (config.containsKey('lastSession')) {
      await saveLastSession(config['lastSession'] as String);
    }
  }
}
