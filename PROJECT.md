# PawChat 项目

## 基本信息

- **名称**: PawChat
- **版本**: v0.2.0 Beta
- **目标**: OpenClaw Gateway Android 客户端

## 代码结构

```
lib/
├── main.dart
├── core/
│   ├── gateway_client.dart      # WebSocket 连接 (Gateway Protocol v3)
│   ├── message_model.dart       # 消息模型
│   ├── message_store.dart       # 本地存储
│   ├── message_actions.dart     # 消息操作 (复制/选择/删除)
│   ├── reconnection_manager.dart # 自动重连管理
│   ├── session_manager.dart     # 会话管理
│   ├── session_model.dart       # 会话模型
│   ├── version.dart             # 版本信息
│   └── log_service.dart         # 日志服务
├── features/
│   ├── chat/
│   │   └── chat_screen.dart     # 聊天界面
│   ├── sessions/
│   │   └── sessions_screen.dart # 会话管理
│   ├── search/
│   │   └── search_screen.dart   # 消息搜索
│   └── settings/
│       └── settings_screen.dart # 设置界面
└── main.dart                    # 应用入口
```

## 依赖

```yaml
dependencies:
  web_socket_channel: ^2.4.0    # WebSocket 连接
  shared_preferences: ^2.2.2    # 本地存储
  path_provider: ^2.1.1         # 文件系统
  share_plus: ^7.2.1            # 分享功能
```

## 功能特性

### 已实现
- [x] WebSocket 连接 Gateway (Protocol v3)
- [x] 消息收发（流式响应）
- [x] 自动重连（指数退避）
- [x] 多会话管理
- [x] 消息搜索
- [x] 消息操作（复制/选择/删除）
- [x] 深色/浅色主题
- [x] WebChat 兼容的所有 Gateway 方法

### 测试中
- [ ] 附件上传
- [ ] Markdown 渲染

## 版本历史

- v0.2.0 (2026-03-07) - Beta 版本，完整功能实现
- v0.1.0 (2026-03-06) - 初始 Alpha 版本

## 状态

⚠️ **开发中** - 尚未经过完整测试验证，不建议生产使用
