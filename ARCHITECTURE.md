# PawChat 架构设计

## 核心目标
基于 OpenClaw Gateway WebSocket 的 Android 聊天客户端

## 架构原则
1. **简洁优先** - 只保留核心功能
2. **稳定连接** - WebSocket 自动重连机制
3. **流畅体验** - 消息实时收发，本地缓存

## 模块划分

### Core (核心层)
- `gateway_client.dart` - WebSocket 连接管理
- `message_model.dart` - 消息数据模型
- `session_manager.dart` - 会话管理

### Features (功能层)
- `chat/` - 聊天界面
  - `chat_screen.dart` - 主界面
  - `message_list.dart` - 消息列表
  - `message_input.dart` - 输入框
- `settings/` - 设置
  - `settings_screen.dart` - Gateway 配置

### Data (数据层)
- `local_storage.dart` - Hive 本地存储
- `message_repository.dart` - 消息仓库

## 数据流
```
UI -> BLoC -> Repository -> GatewayClient
                |
                v
            LocalStorage
```

## 简化后的功能清单
1. ✅ WebSocket 连接/断开
2. ✅ 发送/接收消息
3. ✅ 显示消息历史
4. ✅ 配置 Gateway URL
5. ⚠️ 多会话（后续迭代）
