import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/websocket/gateway_client.dart';
import '../../../core/websocket/protocol.dart';
import '../../../core/storage/local_storage.dart';

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
  final List<ChatMessage> messages;
  final String? currentRunId;
  
  const ChatConnected({
    required this.messages,
    this.currentRunId,
  });
  
  @override
  List<Object?> get props => [messages, currentRunId];
  
  ChatConnected copyWith({
    List<ChatMessage>? messages,
    String? currentRunId,
  }) {
    return ChatConnected(
      messages: messages ?? this.messages,
      currentRunId: currentRunId ?? this.currentRunId,
    );
  }
}

class ChatStreaming extends ChatState {
  final List<ChatMessage> messages;
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
  
  const ChatError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ChatPairingRequired extends ChatState {
  const ChatPairingRequired();
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
  
  const ChatConnect({
    required this.url,
    this.token,
    this.password,
  });
  
  @override
  List<Object?> get props => [url, token, password];
}

class ChatSendMessage extends ChatEvent {
  final String content;
  
  const ChatSendMessage(this.content);
  
  @override
  List<Object?> get props => [content];
}

class ChatAbort extends ChatEvent {
  const ChatAbort();
  
  @override
  List<Object?> get props => [];
}

class ChatLoadHistory extends ChatEvent {
  final int limit;
  
  const ChatLoadHistory({this.limit = 50});
  
  @override
  List<Object?> get props => [limit];
}

class ChatDisconnect extends ChatEvent {
  const ChatDisconnect();
  
  @override
  List<Object?> get props => [];
}

// ========== BLoC ==========

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GatewayClient _client;
  final LocalStorage? _storage;
  String? _currentRunId;
  String _sessionKey = 'default';
  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  
  ChatBloc(this._client, {LocalStorage? storage}) 
      : _storage = storage, 
        super(const ChatInitial()) {
    on<ChatConnect>(_onConnect);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatAbort>(_onAbort);
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatDisconnect>(_onDisconnect);
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
        if (status == ConnectionStatus.pairingRequired) {
          emit(const ChatPairingRequired());
        } else if (status == ConnectionStatus.disconnected) {
          emit(const ChatInitial());
        }
      });
      
      // 监听消息
      _messageSubscription = _client.messages.listen((message) {
        _handleGatewayMessage(message);
      });
      
      // 先加载缓存消息
      if (_storage != null) {
        final cachedMessages = _storage!.loadMessages(_sessionKey);
        if (cachedMessages != null && cachedMessages.isNotEmpty) {
          emit(ChatConnected(
            messages: cachedMessages,
            currentRunId: _currentRunId,
          ));
        }
      }
      
      // 然后从 Gateway 加载历史消息
      add(const ChatLoadHistory());
      
    } catch (e) {
      emit(ChatError('连接失败：$e'));
    }
  }
  
  void _handleGatewayMessage(GatewayMessage message) {
    if (message.type == 'chat') {
      // 处理流式响应
      if (message.status == 'streaming') {
        if (state is ChatConnected) {
          final currentState = state as ChatConnected;
          emit(ChatStreaming(
            messages: currentState.messages,
            currentRunId: message.runId ?? _currentRunId ?? '',
            streamingContent: message.content ?? '',
          ));
        }
      } else if (message.status == 'completed') {
        // 完成，将消息添加到历史
        if (state is ChatStreaming) {
          final currentState = state as ChatStreaming;
          final newMessage = ChatMessage(
            role: 'assistant',
            content: message.content ?? '',
            timestamp: DateTime.now(),
            runId: message.runId,
          );
          final newMessages = [...currentState.messages, newMessage];
          
          emit(ChatConnected(
            messages: newMessages,
            currentRunId: null,
          ));
          
          // 缓存消息
          if (_storage != null) {
            _storage!.appendMessage(_sessionKey, newMessage);
          }
        }
        _currentRunId = null;
      }
    }
  }
  
  Future<void> _onSendMessage(ChatSendMessage event, Emitter<ChatState> emit) async {
    if (state is! ChatConnected && state is! ChatStreaming) {
      emit(const ChatError('未连接到 Gateway'));
      return;
    }
    
    try {
      final userMessage = ChatMessage(
        role: 'user',
        content: event.content,
        timestamp: DateTime.now(),
      );
      
      // 添加用户消息到 UI
      if (state is ChatConnected) {
        final currentState = state as ChatConnected;
        emit(ChatConnected(
          messages: [...currentState.messages, userMessage],
          currentRunId: _currentRunId,
        ));
        
        // 缓存消息
        if (_storage != null) {
          await _storage!.appendMessage(_sessionKey, userMessage);
        }
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
      final history = await _client.getChatHistory(limit: event.limit);
      
      // 保存到缓存
      if (_storage != null && history.isNotEmpty) {
        await _storage!.saveMessages(_sessionKey, history);
      }
      
      emit(ChatConnected(
        messages: history,
        currentRunId: _currentRunId,
      ));
    } catch (e) {
      emit(ChatError('加载历史失败：$e'));
    }
  }
  
  Future<void> _onDisconnect(ChatDisconnect event, Emitter<ChatState> emit) async {
    await _client.disconnect();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    emit(const ChatInitial());
  }
  
  @override
  Future<void> close() {
    _client.dispose();
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    return super.close();
  }
}
