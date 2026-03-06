# PawChat

基于 OpenClaw Gateway WebSocket 的 Android 聊天客户端 (Alpha)

## ⚠️ 版本状态

**v0.1.0 Alpha** - 早期测试版本，功能尚未完善

## ✨ 当前功能

- 🔌 **WebSocket 连接** - 连接 OpenClaw Gateway
- 💬 **消息收发** - 支持流式响应
- 💾 **本地缓存** - 消息本地存储
- 🎨 **深色主题** - 自动适配系统主题
- ⚙️ **Gateway 配置** - 自定义 URL 和 Token

## 📥 安装

从 [Releases](https://github.com/xushuangjiang/pawchat-android/releases) 下载 APK：

```bash
# ARM64 设备（大多数手机）
adb install app-arm64-v8a-release.apk

# x86_64 模拟器
adb install app-x86_64-release.apk
```

## 🚀 使用方法

1. 打开应用
2. 点击右上角 **设置** 图标
3. 输入 Gateway URL（如：`192.168.1.100:18789`）
4. 点击 **连接**
5. 返回聊天界面开始对话

## 🛠️ 开发

```bash
flutter pub get
flutter run
flutter build apk --release
```

## 📝 项目信息

- **Flutter**: 3.24.0
- **依赖**: web_socket_channel, shared_preferences
- **架构**: 简化状态管理（无 BLoC）

## ⚠️ 已知问题

- 多会话功能待实现
- 附件上传待实现
- 推送通知待实现
- 网络重连机制待优化
