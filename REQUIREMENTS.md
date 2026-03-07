# PawChat 需求规格

## 核心需求
1. 连接 OpenClaw Gateway WebSocket
2. 发送消息并接收流式响应
3. 显示聊天记录
4. 基本错误处理

## 技术规格
- Protocol: WebSocket, OpenClaw Gateway Protocol v3
- 认证: Token based
- 消息格式: JSON

## Gateway 事件 (从 WebChat 源码确认)
- `connect.challenge` - 连接挑战
- `chat` - 聊天消息 (主要事件)
  - payload.message.content - 消息内容
  - payload.message.role - user/assistant
  - payload.streaming - 是否流式
- `presence` - 在线状态
- `heartbeat` - 心跳

## 发送方法
- `connect` - 连接
- `chat.send` - 发送消息
- `chat.abort` - 中止

## 成功标准
- [ ] 能连接 Gateway
- [ ] 能发送消息
- [ ] 能接收流式回复
- [ ] 错误时有提示
