# PawChat Android - 快速开始指南

## 1. 环境准备

### 安装 Flutter

```bash
# macOS
brew install --cask flutter

# Linux
sudo snap install flutter --classic

# 验证安装
flutter doctor
```

### 配置 Android 开发环境

```bash
# 安装 Android Studio
# 然后安装 Android SDK 和模拟器

# 接受许可证
flutter doctor --android-licenses

# 检查设备
flutter devices
```

## 2. 创建项目

```bash
cd ~/.openclaw/workspace/pawchat-android

# 获取依赖
flutter pub get

# 运行代码生成 (JSON 序列化)
flutter pub run build_runner build --delete-conflicting-outputs
```

## 3. 启动 OpenClaw Gateway

确保 Gateway 已启动并配置好认证：

```bash
# 查看 Gateway 状态
openclaw gateway status

# 启动 Gateway (如果未运行)
openclaw gateway start

# 生成 Token (首次使用)
openclaw gateway --token "$(openssl rand -hex 32)"
```

## 4. 运行应用

### 使用模拟器

```bash
# 启动 Android 模拟器
flutter emulators --launch <emulator_id>

# 运行应用
flutter run
```

### 使用真机

```bash
# 启用 USB 调试并连接手机
# 然后运行
flutter run
```

## 5. 连接 Gateway

### 本地开发 (同一网络)

1. 获取你的设备 IP 地址：
   ```bash
   # Linux/macOS
   ip addr show | grep "inet "
   
   # 或
   ifconfig | grep "inet "
   ```

2. 在应用中配置：
   - URL: `ws://<你的 IP>:18789`
   - Token: (可选，如果 Gateway 配置了认证)

### 使用 Tailscale (推荐用于远程访问)

```bash
# 启用 Tailscale Serve
tailscale serve --bg https / http://localhost:18789

# 然后使用 HTTPS 连接
# URL: wss://<your-machine>.ts.net
```

## 6. 设备配对

首次连接时会提示需要配对：

```bash
# 在 Gateway 设备上查看待批准的设备
openclaw devices list

# 批准设备
openclaw devices approve <requestId>
```

本地连接 (`127.0.0.1`) 自动批准。

## 7. 项目结构

```
pawchat-android/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── core/
│   │   └── websocket/
│   │       ├── gateway_client.dart   # WebSocket 客户端
│   │       └── protocol.dart         # 协议定义
│   └── features/
│       └── chat/
│           ├── bloc/
│           │   └── chat_bloc.dart    # 状态管理
│           └── presentation/
│               ├── chat_screen.dart  # 聊天界面
│               ├── message_list.dart # 消息列表
│               └── message_input.dart # 输入框
├── pubspec.yaml                  # 依赖配置
└── README.md                     # 完整文档
```

## 8. 下一步

### 待实现功能

- [ ] 消息列表组件 (`message_list.dart`)
- [ ] 消息输入组件 (`message_input.dart`)
- [ ] 设置页面 (Gateway 配置持久化)
- [ ] 本地消息缓存
- [ ] Markdown 渲染优化
- [ ] 深色主题支持

### 参考资源

- [Flutter 文档](https://docs.flutter.dev)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [WebSocket Channel](https://pub.dev/packages/web_socket_channel)
- [Flutter BLoC](https://bloclibrary.dev)

## 常见问题

### Q: 连接超时
A: 检查防火墙设置，确保 18789 端口开放

### Q: 配对请求不出现
A: 检查 Gateway 日志，确认设备 ID 生成正常

### Q: 消息发送失败
A: 确认 Token 正确，检查网络连接

---

有问题？查看完整文档：`README.md`
