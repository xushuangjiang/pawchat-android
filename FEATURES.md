# PawChat 功能清单

基于 OpenClaw Gateway Protocol v3 实现的完整功能列表

## ✅ 已实现功能

### 核心连接
- [x] WebSocket 连接到 Gateway
- [x] Protocol v3 握手 (connect.challenge)
- [x] Token 认证
- [x] 连接状态管理 (disconnected/connecting/connected/error)
- [x] 自动重连 (指数退避算法)
- [x] 重连状态指示器

### 消息功能
- [x] 发送消息 (chat.send)
- [x] 接收流式响应 (chat.chunk)
- [x] 响应完成处理 (chat.complete)
- [x] 错误处理 (chat.error)
- [x] 中止响应 (chat.abort)
- [x] 获取历史消息 (chat.history)
- [x] 本地消息存储 (SharedPreferences)
- [x] 消息复制
- [x] 消息选择文本
- [x] 消息删除

### 会话管理
- [x] 多会话支持
- [x] 创建新会话
- [x] 切换会话
- [x] 重命名会话
- [x] 删除会话
- [x] 会话列表从 Gateway 同步 (sessions.list)
- [x] 会话重置 (sessions.reset)
- [x] 会话删除 (sessions.delete)
- [x] 会话时间排序

### 搜索功能
- [x] 本地消息搜索
- [x] 搜索结果高亮
- [x] 消息详情查看
- [x] 时间格式化显示

### UI/UX
- [x] 深色/浅色主题
- [x] Material 3 设计
- [x] 连接状态指示器
- [x] 重连横幅提示
- [x] 空状态提示
- [x] 消息气泡样式
- [x] 流式响应动画
- [x] 设置页面
- [x] 会话管理页面
- [x] 搜索页面

### 设置
- [x] Gateway URL 配置
- [x] Token 配置
- [x] 自动重连开关
- [x] 会话同步
- [x] 清空聊天记录
- [x] 设置持久化

## 📋 代码结构

```
lib/
├── core/
│   ├── gateway_client.dart      # WebSocket 客户端
│   ├── message_model.dart       # 消息模型
│   ├── message_store.dart       # 消息存储
│   ├── message_actions.dart     # 消息操作
│   ├── reconnection_manager.dart # 自动重连管理
│   ├── session_manager.dart     # 会话管理
│   ├── session_model.dart       # 会话模型
│   ├── version.dart             # 版本信息
│   └── log_service.dart         # 日志服务
├── features/
│   ├── chat/
│   │   └── chat_screen.dart     # 聊天主界面
│   ├── sessions/
│   │   └── sessions_screen.dart # 会话管理
│   ├── search/
│   │   └── search_screen.dart   # 消息搜索
│   └── settings/
│       └── settings_screen.dart # 设置
└── main.dart                    # 应用入口
```

## 🔌 Gateway 协议支持

### 发送的方法
- `connect` - 连接握手
- `chat.send` - 发送消息
- `chat.abort` - 中止响应
- `chat.history` - 获取历史
- `sessions.list` - 获取会话列表
- `sessions.reset` - 重置会话
- `sessions.delete` - 删除会话

### 接收的事件
- `connect.challenge` - 连接挑战
- `chat.chunk` - 流式响应片段
- `chat.complete` - 响应完成
- `chat.error` - 错误消息
- `chat.history` - 历史消息
- `presence` - 设备在线状态
- `heartbeat` - 心跳响应

## 🎯 下一步（可选增强）

### 高优先级
- [ ] Markdown 渲染 (代码块、列表等)
- [ ] 图片/附件发送
- [ ] 消息撤回

### 中优先级
- [ ] 推送通知
- [ ] 语音输入
- [ ] 快捷指令

### 低优先级
- [ ] 导出聊天记录
- [ ] 多语言支持
- [ ] 主题自定义
