import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/websocket/gateway_client.dart';
import '../../../core/websocket/protocol.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/models/message.dart';

// ========== States ==========

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatConnected extends ChatState {
  final List<Message> messages;
  final String? currentRunId;
  final bool isReconnecting;
  final int reconnectAttempt;
  
  const ChatConnected({
    required this.messages,
    this.currentRunId,
    this.isReconnecting = false,
    this.reconnectAttempt = 0,
  });
  
  @override
  List<Object?> get props => [messages, currentRunId, isReconnecting, reconnectAttempt];
  
  ChatConnected copyWith({
    List<Message>? messages,
    String? currentRunId,
    bool? isReconnecting,
    int? reconnectAttempt,
  }) {
    return ChatConnected(
      messages: messages ?? this.messages,
      currentRunId: currentRunId ?? this.currentRunId,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
    );
  }
}

class ChatStreaming extends ChatState {
  final List<Message> messages;
  final String currentRunId;
  final String streamingContent;
  
  const ChatStreaming({
    required this.messages,
    required this.currentRunId,
    required this.streamingContent,
  });
  
  @override
  List<Object?> get props => [messages, currentRunId, streamingContent];
}

class ChatError extends ChatState {
  final String message;
  final bool isFatal;
  
  const ChatError(this.message, {this.isFatal = false});
  
  @override
  List<Object?> get props => [message, isFatal];
}

class ChatPairingRequired extends ChatState {
  final String? deviceId;
  
  const ChatPairingRequired({this.deviceId});
  
  @override
  List<Object?> get props => [deviceId];
}

// ========== Events ==========

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  
  @override
  List<Object?> get props => [];
}

class ChatConnect extends ChatEvent {
  final String url;
  final String? token;
  final String? password;
  final bool autoReconnect;
  final bool fromCache;
  
  const ChatConnect({
    required this.url,
    this.token,
    this.password,
    this.autoReconnect = true,
    this.fromCache = true,
  });
  
  @override
  List<Object?> get props => [url, token, password, autoReconnect, fromCache];
}

class ChatSendMessage extends ChatEvent {
  final String content;
  final Map<String, dynamic>? metadata;
  
  const ChatSendMessage(this.content, {this.metadata});
  
  @override
  List<Object?> get props => [content, metadata];
}

class ChatAbort extends ChatEvent {
  const ChatAbort();
  
  @override
  List<Object?> get props => [];
}

class ChatLoadHistory extends ChatEvent {
  final int limit;
  final bool fromCache;
  
  const ChatLoadHistory({this.limit = 50, this.fromCache = true});
  
  @override
  List<Object?> get props => [limit, fromCache];
}

class ChatDisconnect extends ChatEvent {
  const ChatDisconnect();
  
  @override
  List<Object?> get props => [];
}

class ChatReconnect extends ChatEvent {
  const ChatReconnect();
  
  @override
  List<Object?> get props => [];
}

class _ChatMessageReceived extends ChatEvent {
  final GatewayMessage message;
  
  const _ChatMessageReceived(this.message);
  
  @override
  List<Object?> get props => [message];
}

class _ChatStatusChanged extends ChatEvent {
  final ConnectionStatus status;
  
  const _ChatStatusChanged(this.status);
  
  @override
  List<Object?> get props => [status];
}

class _ChatConnectionError extends ChatEvent {
  final String error;
  
  const _ChatConnectionError(this.error);
  
  @override
  List<Object?> get props => [error];
}

// ========== BLoC ==========

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GatewayClient _client;
  final LocalStorage? _storage;
  String? _currentRunId;
  String _sessionKey = 'default';
  StreamSubscription<GatewayMessage>? _messageSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  
  ChatBloc(this._client, {LocalStorage? storage}) 
      : _storage = storage, 
        super(const ChatInitial()) {
    _registerHandlers();
  }

  void _registerHandlers() {
    on<ChatConnect>(_onConnect);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatAbort>(_onAbort);
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatDisconnect>(_onDisconnect);
    on<ChatReconnect>(_onReconnect);
    on<_ChatMessageReceived>(_onMessageReceived);
    on<_ChatStatusChanged>(_onStatusChanged);
  }
  
  /// 设置会话密钥
  void setSessionKey(String key) {
    _sessionKey = key;
    _storage?.saveLastSession(key);
  }
  
  /// 获取当前会话密钥
  String get sessionKey => _sessionKey;
  
  Future<void> _onConnect(ChatConnect event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    
    try {
      await _client.connect(
        url: event.url,
        token: event.token,
        password: event.password,
      );
      
      // 监听连接状态
      _statusSubscription = _client.statusStream.listen((status) {
        add(_ChatStatusChanged(status));
      });
      
      // 监听消息
      _messageSubscription = _client.messages.listen(
        (message) => add(_ChatMessageReceived(message)),
        onError: (error) => add(_ChatConnectionError('消息接收错误: $error')),
      );
      
      // 先加载缓存消息
      if (event.fromCache && _storage != null) {
        final cachedMessages = _storage!.loadMessages(_sessionKey);
        if (cachedMessages != null && cachedMessages.isNotEmpty) {
          emit(ChatConnected(messages: cachedMessages));
        }
      }
      
      // 然后从 Gateway 加载历史消息
      add(const ChatLoadHistory(fromCache: false));
      
    } catch (e) {
      emit(ChatError('连接失败：$e', isFatal: true));
    }
  }
  
  Future<void> _onStatusChanged(_ChatStatusChanged event, Emitter<ChatState> emit) async {
    switch (event.status) {
      case ConnectionStatus.pairingRequired:
        emit(const ChatPairingRequired());
        break;
      case ConnectionStatus.disconnected:
        if (state is ChatConnected) {
          // 保持当前状态但标记为断开
          final currentState = state as ChatConnected;
          emit(currentState.copyWith(isReconnecting: true));
        } else {
          emit(const ChatInitial());
        }
        break;
      case ConnectionStatus.connected:
        if (state is ChatConnected) {
          final currentState = state as ChatConnected;
          emit(currentState.copyWith(isReconnecting: false, reconnectAttempt: 0));
        }
        break;
      default:
        break;
    }
  }
  
  Future<void> _onMessageReceived(_ChatMessageReceived event, Emitter<ChatState> emit) async {
    final message = event.message;
    
    if (message.type == GatewayMessageType.chat) {
      await _handleChatMessage(message, emit);
    } else if (message.isError) {
      emit(ChatError(message.errorMessage ?? '未知错误'));
    }
  }

  Future<void> _handleChatMessage(GatewayMessage message, Emitter<ChatState> emit) async {
    final msgStatus = message.status;
    
    if (msgStatus == 'streaming') {
      // 处理流式响应
      if (state is ChatConnected) {
        final currentState = state as ChatConnected;
        emit(ChatStreaming(
          messages: currentState.messages,
          currentRunId: message.runId ?? _currentRunId ?? '',
          streamingContent: message.content ?? '',
        ));
      }
    } else if (msgStatus == 'completed') {
      // 完成，将消息添加到历史
      if (state is ChatStreaming) {
        final currentState = state as ChatStreaming;
        final newMessage = Message.assistant(
          content: message.content ?? '',
          runId: message.runId,
          sessionKey: _sessionKey,
        );
        
        final newMessages = [...currentState.messages, newMessage];
        
        emit(ChatConnected(
          messages: newMessages,
          currentRunId: null,
        ));
        
        // 缓存消息
        await _storage?.appendMessage(_sessionKey, newMessage);
      }
      _currentRunId = null;
    }
  }
  
  Future<void> _onSendMessage(ChatSendMessage event, Emitter<ChatState> emit) async {
    if (state is! ChatConnected && state is! ChatStreaming) {
      emit(const ChatError('未连接到 Gateway'));
      return;
    }
    
    try {
      final userMessage = Message.user(
        content: event.content,
        sessionKey: _sessionKey,
      );
      
      // 添加用户消息到 UI
      if (state is ChatConnected) {
        final currentState = state as ChatConnected;
        emit(ChatConnected(
          messages: [...currentState.messages, userMessage],
          currentRunId: _currentRunId,
        ));
        
        // 缓存消息
        await _storage?.appendMessage(_sessionKey, userMessage);
      }
      
      // 发送消息到 Gateway
      final response = await _client.sendChat(
        content: event.content,
        idempotencyKey: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      _currentRunId = response.runId;
      
    } catch (e) {
      emit(ChatError('发送失败：$e'));
    }
  }
  
  Future<void> _onAbort(ChatAbort event, Emitter<ChatState> emit) async {
    try {
      await _client.abortChat(runId: _currentRunId);
      _currentRunId = null;
      
      if (state is ChatStreaming) {
        final currentState = state as ChatStreaming;
        emit(ChatConnected(
          messages: currentState.messages,
          currentRunId: null,
        ));
      }
    } catch (e) {
      emit(ChatError('中止失败：$e'));
    }
  }
  
  Future<void> _onLoadHistory(ChatLoadHistory event, Emitter<ChatState> emit) async {
    try {
      List<Message> history = [];
      
      if (event.fromCache && _storage != null) {
        // 从缓存加载
        final cached = _storage!.loadMessages(_sessionKey);
        if (cached != null) history = cached;
      }
      
      // 从 Gateway 加载更多历史
      final gatewayHistory = await _client.getChatHistory(limit: event.limit);
      
      // 合并并去重（基于时间戳）
      final allMessages = {...history, ...gatewayHistory}.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // 保存到缓存
      if (_storage != null && allMessages.isNotEmpty) {
        await _storage!.saveMessages(_sessionKey, allMessages);
      }
      
      emit(ChatConnected(
        messages: allMessages,
        currentRunId: _currentRunId,
      ));
    } catch (e) {
      emit(ChatError('加载历史失败：$e'));
    }
  }
  
  Future<void> _onReconnect(ChatReconnect event, Emitter<ChatState> emit) async {
    // 触发重连逻辑
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      emit(currentState.copyWith(
        isReconnecting: true,
        reconnectAttempt: currentState.reconnectAttempt + 1,
      ));
    }
  }
  
  Future<void> _onDisconnect(ChatDisconnect event, Emitter<ChatState> emit) async {
    await _cleanup();
    emit(const ChatInitial());
  }

  Future<void> _cleanup() async {
    await _client.disconnect();
    await _messageSubscription?.cancel();
    await _statusSubscription?.cancel();
    _messageSubscription = null;
    _statusSubscription = null;
    _currentRunId = null;
  }
  
  @override
  Future<void> close() async {
    await _cleanup();
    _client.dispose();
    return super.close();
  }
}
