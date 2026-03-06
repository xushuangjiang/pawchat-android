import 'dart:async';
import 'gateway_client.dart';

/// 自动重连管理器
class ReconnectionManager {
  final GatewayClient client;
  
  // 重连配置
  static const int _maxAttempts = 10;
  static const int _initialDelayMs = 1000;
  static const int _maxDelayMs = 30000;
  static const double _backoffMultiplier = 2.0;
  
  int _attemptCount = 0;
  Timer? _reconnectTimer;
  bool _isEnabled = false;
  String? _lastUrl;
  String? _lastToken;
  
  final _stateController = StreamController<ReconnectionState>.broadcast();
  
  Stream<ReconnectionState> get stateStream => _stateController.stream;
  bool get isEnabled => _isEnabled;
  int get attemptCount => _attemptCount;

  ReconnectionManager(this.client) {
    _listenToConnection();
  }

  void _listenToConnection() {
    client.stateStream.listen((state) {
      switch (state) {
        case GatewayConnectionState.connected:
          _onConnected();
          break;
        case GatewayConnectionState.disconnected:
          if (_isEnabled) _scheduleReconnect();
          break;
        case GatewayConnectionState.error:
          if (_isEnabled) _scheduleReconnect();
          break;
        default:
          break;
      }
    });
  }

  void _onConnected() {
    _attemptCount = 0;
    _reconnectTimer?.cancel();
    _stateController.add(ReconnectionState.connected);
  }

  void _scheduleReconnect() {
    if (_attemptCount >= _maxAttempts) {
      _stateController.add(ReconnectionState.maxAttemptsReached);
      return;
    }

    _reconnectTimer?.cancel();
    
    final delay = _calculateDelay();
    _attemptCount++;
    
    _stateController.add(ReconnectionState.reconnecting);
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      if (_lastUrl != null) {
        try {
          await client.connect(_lastUrl!, token: _lastToken);
        } catch (e) {
          // 连接失败，会继续触发 stateStream 的 error/disconnected
        }
      }
    });
  }

  int _calculateDelay() {
    final delay = (_initialDelayMs * 
        (_backoffMultiplier * _attemptCount)).toInt();
    return delay > _maxDelayMs ? _maxDelayMs : delay;
  }

  /// 启用自动重连
  void enable(String url, {String? token}) {
    _isEnabled = true;
    _lastUrl = url;
    _lastToken = token;
    _attemptCount = 0;
  }

  /// 禁用自动重连
  void disable() {
    _isEnabled = false;
    _reconnectTimer?.cancel();
    _attemptCount = 0;
  }

  /// 重置计数器
  void reset() {
    _attemptCount = 0;
    _reconnectTimer?.cancel();
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _stateController.close();
  }
}

enum ReconnectionState {
  connected,
  reconnecting,
  maxAttemptsReached,
}
