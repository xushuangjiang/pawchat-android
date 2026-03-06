# PawChat

基于 OpenClaw Gateway WebSocket 的 Android 聊天客户端

## 📱 简介

PawChat 是一个简洁的 Android 聊天应用，让你可以通过手机与 OpenClaw Agent 进行实时对话。

## ✨ 功能特性

- 🔌 **WebSocket 连接** - 实时连接 OpenClaw Gateway
- 💬 **消息收发** - 支持流式响应，实时显示 AI 回复
- 💾 **本地缓存** - 消息本地存储，重启后保留
- 🎨 **深色主题** - 自动适配系统主题
- ⚙️ **灵活配置** - 自定义 Gateway URL 和 Token

## 📥 安装

从 [Releases](https://github.com/xushuangjiang/pawchat-android/releases) 页面下载最新 APK：

- `app-arm64-v8a-release.apk` - 适用于大多数现代 Android 手机
- `app-x86_64-release.apk` - 适用于 x86_64 模拟器

## 🚀 使用方法

1. **安装应用**
   ```bash
   adb install app-arm64-v8a-release.apk
   ```

2. **配置 Gateway**
   - 打开应用，点击右上角设置图标
   - 输入 Gateway URL（例如：`192.168.1.100:18789`）
   - 如有需要，输入 Token
   - 点击"连接"

3. **开始聊天**
   - 返回主界面
   - 在底部输入框输入消息
   - 点击发送按钮

## 🏗️ 技术栈

- **Flutter** 3.24.0
- **Dart** 3.0+
- **WebSocket** - 实时通信
- **SharedPreferences** - 本地数据持久化

## 🛠️ 开发构建

```bash
# 克隆仓库
git clone https://github.com/xushuangjiang/pawchat-android.git
cd pawchat-android

# 获取依赖
flutter pub get

# 运行调试版本
flutter run

# 构建发布版本
flutter build apk --release
```

## 📋 项目状态

当前版本：**v0.1.0 (Alpha)**

### ✅ 已实现
- [x] WebSocket 连接与认证
- [x] 消息收发（流式响应）
- [x] 本地消息缓存
- [x] 深色主题支持
- [x] Gateway 配置

### 🚧 待实现
- [ ] 多会话管理
- [ ] 附件上传（图片、文件）
- [ ] 推送通知
- [ ] 网络自动重连
- [ ] 消息搜索

## 🤝 贡献

欢迎提交 Issue 和 PR！

## 📄 许可证

MIT License
