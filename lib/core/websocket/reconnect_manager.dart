import 'dart:async';
import 'package:flutter/foundation.dart';

/// 重连管理器 - 处理 WebSocket 自动重连
/// 
/// 功能:
/// - 指数退避策略 (1s, 2s, 4s, 8s, 16s, 30s...)
/// - 最大重连次数限制
/// - 网络状态监听 (可选)
/// - 重连状态回调
class ReconnectManager {
  /// 最大重连次数
  final int maxRetries;

  /// 初始重试间隔 (毫秒)
  final int initialDelayMs;

  /// 最大重试间隔 (毫秒)
  final int maxDelayMs;

  /// 重连回调
  final Function() onReconnect;

  /// 重连成功回调
  final Function()? onSuccess;

  /// 重连失败回调 (达到最大次数)
  final Function(int attempts)? onFailure;

  /// 重连状态变化回调
  final Function(bool isReconnecting, int attempt)? onStateChange;

  Timer? _retryTimer;
  int _attempt = 0;
  bool _isReconnecting = false;

  ReconnectManager({
    this.maxRetries = 10,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 30000,
    required this.onReconnect,
    this.onSuccess,
    this.onFailure,
    this.onStateChange,
  });

  /// 计算指数退避延迟
  int _calculateDelay(int attempt) {
    // 指数增长：initialDelay * 2^attempt
    final exponentialDelay = initialDelayMs * (1 << attempt);
    // 限制在最大值以内
    return exponentialDelay.clamp(initialDelayMs, maxDelayMs);
  }

  /// 开始重连流程
  void startReconnecting() {
    if (_isReconnecting) {
      debugPrint('[ReconnectManager] 已在重连中，忽略重复请求');
      return;
    }

    debugPrint('[ReconnectManager] 开始重连流程');
    _attempt = 0;
    _isReconnecting = true;
    _notifyStateChange();
    
    _scheduleRetry();
  }

  /// 调度下一次重试
  void _scheduleRetry() {
    if (_attempt >= maxRetries) {
      debugPrint('[ReconnectManager] 达到最大重连次数 ($_attempt)，停止重连');
      _isReconnecting = false;
      _notifyStateChange();
      onFailure?.call(_attempt);
      return;
    }

    final delay = _calculateDelay(_attempt);
    debugPrint('[ReconnectManager] 计划第 ${_attempt + 1}/$maxRetries 次重连，延迟 ${delay}ms');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(milliseconds: delay), () {
      _attempt++;
      _notifyStateChange();
      _tryReconnect();
    });
  }

  /// 尝试重连
  Future<void> _tryReconnect() async {
    if (!_isReconnecting) {
      debugPrint('[ReconnectManager] 重连已取消，跳过本次尝试');
      return;
    }

    try {
      debugPrint('[ReconnectManager] 执行重连尝试 ($_attempt/$maxRetries)');
      await onReconnect();
      
      // 重连成功
      debugPrint('[ReconnectManager] 重连成功！');
      reset();
      onSuccess?.call();
    } catch (e, stackTrace) {
      debugPrint('[ReconnectManager] 重连失败：$e');
      if (kDebugMode) {
        debugPrint('[ReconnectManager] 堆栈：$stackTrace');
      }
      // 继续下一次重试
      _scheduleRetry();
    }
  }

  /// 重连成功时调用 - 重置状态
  void reset() {
    debugPrint('[ReconnectManager] 重置重连状态');
    _retryTimer?.cancel();
    _retryTimer = null;
    _attempt = 0;
    _isReconnecting = false;
    _notifyStateChange();
  }

  /// 取消重连
  void cancel() {
    debugPrint('[ReconnectManager] 取消重连');
    _retryTimer?.cancel();
    _retryTimer = null;
    _isReconnecting = false;
    _notifyStateChange();
  }

  /// 通知状态变化
  void _notifyStateChange() {
    onStateChange?.call(_isReconnecting, _attempt);
  }

  /// 是否正在重连
  bool get isReconnecting => _isReconnecting;

  /// 当前重连尝试次数
  int get attempt => _attempt;

  /// 是否已达到最大重连次数
  bool get isMaxRetriesReached => _attempt >= maxRetries;

  /// 销毁
  void dispose() {
    cancel();
  }
}

/// 网络连接状态枚举
enum NetworkStatus {
  connected,
  disconnected,
  reconnecting,
}

/// 网络状态监听器 (可选功能)
class NetworkStatusListener {
  StreamSubscription? _subscription;
  NetworkStatus _status = NetworkStatus.disconnected;
  final List<Function(NetworkStatus)> _listeners = [];

  NetworkStatusListener() {
    // TODO: 集成 connectivity_plus 包监听网络状态
    // _startListening();
  }

  void _startListening() {
    // 使用 connectivity_plus 监听网络变化
    // Connectivity().onConnectivityChanged.listen((result) {
    //   _updateStatus(result);
    // });
  }

  void _updateStatus(dynamic result) {
    // 根据网络结果更新状态
    // 触发重连逻辑
  }

  void addListener(Function(NetworkStatus) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(NetworkStatus) listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
