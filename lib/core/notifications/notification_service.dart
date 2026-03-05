import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知服务
/// 
/// 处理本地推送通知
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[NotificationService] 已初始化，跳过');
      return;
    }

    debugPrint('[NotificationService] 初始化通知服务...');

    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建通知渠道 (Android 8.0+)
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('[NotificationService] 初始化完成');
  }

  /// 创建通知渠道
  Future<void> _createNotificationChannels() async {
    const defaultChannel = AndroidNotificationChannel(
      'pawchat_messages', // 渠道 ID
      '消息通知', // 渠道名称
      description: '新消息通知',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);
  }

  /// 处理通知点击
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] 通知点击：${response.payload}');
    // TODO: 导航到对应会话
  }

  /// 显示消息通知
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? sessionId,
    String? senderName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('[NotificationService] 显示消息通知：$title - $body');

    const androidDetails = AndroidNotificationDetails(
      'pawchat_messages',
      '消息通知',
      channelDescription: '新消息通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableLights: true,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // 唯一 ID
      title,
      body,
      details,
      payload: sessionId, // 点击后跳转到对应会话
    );
  }

  /// 显示一般通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pawchat_general',
        '一般通知',
        channelDescription: '一般通知',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('[NotificationService] 已取消所有通知');
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    // Android 13+ 需要请求通知权限
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[NotificationService] Android 通知权限：$granted');
      return granted ?? false;
    }

    // iOS 权限
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[NotificationService] iOS 通知权限：$granted');
      return granted ?? false;
    }

    return true; // 旧版本 Android 默认有权限
  }

  /// 检查通知权限
  Future<bool> hasPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final hasPermission = await androidPlugin.areNotificationsEnabled();
      return hasPermission ?? false;
    }

    return true;
  }

  /// 销毁
  void dispose() {
    _notifications.dispose();
  }
}
