# PawChat Android 开发任务

## 当前状态 (2026-03-07 22:55)

### 已完成
- [x] MVP 版本重构完成
- [x] 修复 ConnectionState 命名冲突
- [x] 添加硬编码 Token
- [x] 修复 client id (openclaw-control-ui)
- [x] 修复 role (operator)
- [x] 修复 mode (cli)
- [x] 添加调试日志

### 待验证
- [ ] 连接 Gateway 测试
- [ ] 发送消息测试
- [ ] 接收流式响应测试

### 已知问题
1. 连接参数已修正，等待构建验证
2. 需要测试完整聊天流程

## Gateway 协议规范

### Connect 参数
```json
{
  "minProtocol": 3,
  "maxProtocol": 3,
  "client": {
    "id": "openclaw-control-ui",
    "version": "1.0.0",
    "platform": "android",
    "mode": "cli"
  },
  "role": "operator",
  "scopes": ["operator.read", "operator.write"],
  "auth": {"token": "..."},
  "locale": "zh-CN",
  "userAgent": "PawChat/1.0.0"
}
```

### 角色支持
- `operator` - 操作员角色
- `node` - 节点角色

### Client ID 支持
- `openclaw-control-ui` - 控制界面
- `webchat-ui` - WebChat UI
- `webchat` - WebChat
- `cli` - CLI
- `gateway-client` - Gateway 客户端

### Client Mode 支持
- `cli` - 命令行模式
- `webchat` - WebChat 模式

## 下一步行动
1. 等待当前构建完成
2. 安装测试 APK
3. 验证连接功能
4. 测试消息收发
5. 修复后续问题
