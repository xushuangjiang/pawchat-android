# PawChat 项目文档

## 项目信息

- **名称**: PawChat
- **版本**: v0.1.0 (Alpha)
- **目标**: OpenClaw Gateway Android 客户端
- **状态**: 开发中

## 核心功能

1. WebSocket 实时通信
2. 消息收发与流式响应
3. 本地消息持久化
4. Gateway 连接配置

## 技术架构

### 简化架构
```
lib/
├── main.dart                    # 应用入口
├── core/
│   ├── gateway_client.dart      # WebSocket 客户端
│   ├── message_model.dart       # 消息模型
│   └── message_store.dart       # 本地存储
└── features/
    ├── chat/
    │   └── chat_screen.dart     # 聊天界面
    └── settings/
        └── settings_screen.dart # 设置界面
```

### 依赖
- web_socket_channel: ^2.4.0
- shared_preferences: ^2.2.2

## 发布历史

### v0.1.0 (2026-03-06)
- 初始 Alpha 版本
- 基础聊天功能
- Gateway 连接配置
