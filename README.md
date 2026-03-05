# PawChat Android - OpenClaw 移动端应用

🐾 基于 OpenClaw Gateway WebSocket 的 Android 聊天客户端

## 技术选型

### 前端框架
- **Flutter 3.x** - 跨平台 UI 框架 (优先推荐)
  - 单一代码库支持 Android/iOS
  - 原生性能，热重载开发体验
  - 丰富的 Material 3 组件库
  
### 替代方案
- **React Native + Expo** - JavaScript/TypeScript 生态
- **Kotlin + Jetpack Compose** - 纯原生 Android

### 核心依赖
- WebSocket 连接：`web_socket_channel` (Flutter) / `okhttp` (Kotlin)
- 状态管理：`flutter_bloc` / `Riverpod`
- 本地存储：`hive` / `shared_preferences`
- JSON 序列化：`json_serializable`

## OpenClaw Gateway 协议

### 连接信息
- **默认端口**: `18789`
- **WebSocket URL**: `ws://<host>:18789/` 或 `wss://<host>:18789/`
- **认证方式**: Token 或 Password

### 核心 API

| 方法 | 描述 |
|------|------|
| `chat.history` | 获取会话历史消息 |
| `chat.send` | 发送消息 (非阻塞，返回 runId) |
| `chat.abort` | 中止当前运行 |
| `chat.inject` | 注入助手笔记 (仅 UI 显示) |

### 设备配对

首次连接新设备时需要配对批准：

```bash
# 查看待批准的设备
openclaw devices list

# 批准设备
openclaw devices approve <requestId>
```

本地连接 (`127.0.0.1`) 自动批准。

## 项目结构

```
pawchat-android/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart              # 应用配置
│   │   └── routes.dart           # 路由配置
│   ├── core/
│   │   ├── websocket/
│   │   │   ├── gateway_client.dart   # WebSocket 客户端
│   │   │   ├── protocol.dart         # 协议定义
│   │   │   └── auth.dart             # 认证处理
│   │   ├── storage/
│   │   │   └── local_storage.dart    # 本地存储
│   │   └── utils/
│   │       └── extensions.dart
│   ├── features/
│   │   ├── chat/
│   │   │   ├── presentation/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   ├── message_list.dart
│   │   │   │   └── message_input.dart
│   │   │   ├── bloc/
│   │   │   │   └── chat_bloc.dart
│   │   │   └── models/
│   │   │       └── message.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   └── gateway_config.dart
│   │   └── pairing/
│   │       └── pairing_screen.dart
│   └── widgets/
│       ├── message_bubble.dart
│       └── loading_indicator.dart
├── assets/
│   └── images/
├── test/
├── pubspec.yaml
└── README.md
```

## 快速开始

### 1. 环境准备

```bash
# 安装 Flutter
flutter doctor

# 创建项目
flutter create pawchat_android
cd pawchat_android

# 添加依赖
flutter pub add web_socket_channel flutter_bloc hive hive_flutter json_annotation
flutter pub add --dev build_runner json_serializable hive_generator
```

### 2. Gateway 配置

确保 OpenClaw Gateway 已启动并配置认证：

```bash
# 启动 Gateway
openclaw gateway

# 查看/生成 Token
openclaw gateway --token "$(openssl rand -hex 32)"
```

### 3. 连接配置

在应用中配置 Gateway 连接：

```dart
// settings/gateway_config.dart
class GatewayConfig {
  final String host;
  final int port;
  final String? token;
  final bool useSecure; // wss vs ws
  
  GatewayConfig({
    this.host = '192.168.1.100',
    this.port = 18789,
    this.token,
    this.useSecure = false,
  });
  
  String get wsUrl => '${useSecure ? 'wss' : 'ws'}://$host:$port';
}
```

## WebSocket 协议示例

### 连接建立

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class GatewayClient {
  late WebSocketChannel _channel;
  
  Future<void> connect(String url, String? token) async {
    final uri = Uri.parse(url);
    final authUri = token != null 
        ? uri.replace(queryParameters: {'auth.token': token})
        : uri;
    
    _channel = WebSocketChannel.connect(authUri);
    
    // 监听消息
    _channel.stream.listen(
      (message) => _handleMessage(message),
      onError: (error) => _handleError(error),
      onDone: () => _handleDisconnect(),
    );
  }
  
  void _handleMessage(dynamic message) {
    // 解析 Gateway 响应
    final data = jsonDecode(message as String);
    // 处理不同类型的消息...
  }
}
```

### 发送消息

```dart
Future<Map<String, dynamic>> sendMessage({
  required String sessionKey,
  required String content,
  String? idempotencyKey,
}) async {
  final payload = {
    'method': 'chat.send',
    'params': {
      'sessionKey': sessionKey,
      'content': content,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    },
  };
  
  _channel.sink.add(jsonEncode(payload));
  
  // 等待响应 (包含 runId)
  // ...
}
```

### 接收流式响应

```dart
// Gateway 通过 chat 事件流式返回响应
// 事件格式示例:
{
  "type": "chat",
  "sessionKey": "default",
  "runId": "xxx",
  "content": "部分响应内容...",
  "status": "streaming" | "completed" | "aborted"
}
```

## 安全考虑

### 认证
- 使用 Token 认证而非 Password（Token 可撤销）
- Token 存储在安全存储中 (Android Keystore)
- 支持 Tailscale 身份认证（如使用 Tailscale Serve）

### 网络
- 优先使用 `wss://` (TLS 加密)
- 本地开发可用 `ws://`
- 通过 Tailscale Serve 获得 HTTPS

### 设备配对
- 首次连接需要用户批准
- 配对请求 1 小时后过期
- 可随时撤销已配对设备

## 功能清单

### MVP (最小可行产品)
- [ ] Gateway 连接配置
- [ ] WebSocket 认证
- [ ] 设备配对流程
- [ ] 发送/接收消息
- [ ] 消息历史加载
- [ ] 流式响应显示
- [ ] 中止运行

### 后续迭代
- [ ] 多会话管理
- [ ] 消息搜索
- [ ] 离线缓存
- [ ] 推送通知
- [ ] 语音输入
- [ ] 附件支持
- [ ] 主题定制

## 开发参考

- OpenClaw 文档：https://docs.openclaw.ai
- Control UI 源码：`~/.npm-global/lib/node_modules/openclaw/dist/control-ui`
- WebSocket 协议参考：`docs/web/control-ui.md`

## 状态追踪

- 创建日期：2026-03-05
- 状态：核心功能开发完成 (v1.0)
- 完成度：49% (51/104 功能)

### 已完成 (v1.0)
- ✅ WebSocket 客户端 (`gateway_client.dart`)
- ✅ 协议定义 (`protocol.dart`)
- ✅ BLoC 状态管理 (`chat_bloc.dart`)
- ✅ 聊天界面 (`chat_screen.dart`)
- ✅ 消息列表 + 下拉刷新 (`message_list.dart`)
- ✅ 消息气泡 (`message_bubble.dart`)
- ✅ 输入框 (`message_input.dart`)
- ✅ 设置页面 (`settings_screen.dart`)
- ✅ 本地存储 (`local_storage.dart`)
- ✅ 工具调用显示 (`tool_call_display.dart`)
- ✅ 会话管理 (`sessions_screen.dart`)
- ✅ 路由系统 (`routes.dart`)
- ✅ 工具扩展 (`extensions.dart`)
- ✅ 消息缓存
- ✅ 深色主题

### v1.1 计划
- [ ] 自动重连机制
- [ ] 消息搜索
- [ ] 附件上传
- [ ] 推送通知

### v2.0 愿景
- [ ] 语音输入
- [ ] 端到端加密
- [ ] 多账号支持
- [ ] iOS 版本
