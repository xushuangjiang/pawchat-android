# PawChat

OpenClaw Gateway 的 Android 客户端

## 状态

⚠️ **Beta 开发中** - 功能已实现，尚未经过完整测试验证

## 功能

- 🔌 WebSocket 连接 Gateway (Protocol v3)
- 💬 消息收发（支持流式响应）
- 🔄 自动重连
- 📁 多会话管理
- 🔍 消息搜索
- 🎨 深色/浅色主题

## 要求

- Android 6.0+ (API 23+)
- Flutter 3.x
- OpenClaw Gateway 2026.3.2+

## 构建

```bash
# 验证协议
python3 test/gateway_protocol_test.py

# 构建 APK
flutter build apk --release
```

## 配置

1. 打开应用
2. 进入设置
3. 输入 Gateway URL (例如: `192.168.1.100:18789`)
4. 输入 Token (如果需要)
5. 点击连接

## 测试

```bash
cd test
python3 gateway_protocol_test.py        # 协议验证
python3 webchat_validation_test.py      # WebChat 兼容性验证
```

## 许可证

MIT
