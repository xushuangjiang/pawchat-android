# 🚀 快速开始 - 5 分钟部署指南

**目标**: 5 分钟内开始自动构建 APK  
**设备**: 三星 S24 Ultra

---

## ⏱️ 时间线

| 步骤 | 时间 | 说明 |
|------|------|------|
| 1. 创建 GitHub 仓库 | 1 分钟 | github.com/new |
| 2. 推送代码 | 2 分钟 | 运行脚本 |
| 3. 自动构建 | 5-10 分钟 | GitHub Actions |
| 4. 下载安装 | 2 分钟 | 下载到手机 |

**总计**: 10-15 分钟

---

## 📋 步骤详解

### 1️⃣ 创建 GitHub 仓库 (1 分钟)

1. 访问 https://github.com/new
2. 填写:
   - **Repository name**: `pawchat-android`
   - **Description**: PawChat Android - OpenClaw 客户端
   - **Visibility**: Public 或 Private
   - ❌ **不要**勾选 "Add a README file"
   - ❌ **不要**勾选 "Add .gitignore"
   - ❌ **不要**选择 License
3. 点击 **Create repository**

---

### 2️⃣ 推送代码 (2 分钟)

**运行自动脚本**:

```bash
cd ~/.openclaw/workspace/pawchat-android
chmod +x setup-github.sh
./setup-github.sh
```

**按提示操作**:
1. 输入 GitHub 用户名
2. 输入邮箱
3. 选择是否立即推送

**或手动操作**:

```bash
cd ~/.openclaw/workspace/pawchat-android

# 初始化 Git
git init
git add .
git commit -m "Initial commit: PawChat Android v1.1"

# 添加远程仓库 (替换 YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/pawchat-android.git

# 推送
git branch -M main
git push -u origin main
```

---

### 3️⃣ 等待构建 (5-10 分钟)

**查看进度**:
```
https://github.com/YOUR_USERNAME/pawchat-android/actions
```

**构建状态**:
- 🟡 黄色 = 进行中
- 🟢 绿色 = 成功
- 🔴 红色 = 失败

---

### 4️⃣ 下载 APK (2 分钟)

**从 Actions 下载**:

1. 访问 Actions 页面
2. 点击最新构建 (最上面)
3. 滚动到底部 **Artifacts**
4. 点击 `pawchat-apks`
5. 下载 ZIP 文件
6. 解压得到:
   - `app-arm64-v8a-release.apk` ← **S24 Ultra 使用这个**

**从 Releases 下载** (如果打了 Tag):

```bash
# 访问
https://github.com/YOUR_USERNAME/pawchat-android/releases

# 下载 app-arm64-v8a-release.apk
```

---

### 5️⃣ 安装到 S24 Ultra (2 分钟)

**方法 1: USB 安装**

```bash
# 手机设置:
# 1. 设置 → 关于手机 → 软件信息
# 2. 连续点击"编译编号"7 次
# 3. 设置 → 开发者选项 → 启用"USB 调试"
# 4. USB 连接电脑

# 电脑执行:
adb install app-arm64-v8a-release.apk
```

**方法 2: 直接传输**

1. 将 APK 传到手机 (微信/QQ/邮件/USB)
2. 文件管理器中点击 APK
3. 允许"安装未知应用"
4. 点击安装

---

## 🎯 验证安装

**打开 PawChat**:
1. 在手机应用列表找到 PawChat
2. 打开应用
3. 检查设置:
   - Gateway 地址：`ws://192.168.0.213:18789` (你的树莓派 IP)
   - Token: 从 OpenClaw 获取

**测试连接**:
1. 点击连接
2. 发送测试消息
3. 收到回复 = 成功！✅

---

## 🔄 后续更新

**推送新代码自动构建**:

```bash
# 修改代码后
git add .
git commit -m "Fix: something"
git push

# GitHub Actions 会自动构建新版本
```

**发布新版本**:

```bash
# 更新版本号 (pubspec.yaml)
# version: 1.1.0+1

git add .
git commit -m "Release v1.1.0"
git tag v1.1.0
git push origin v1.1.0

# 自动创建 GitHub Release
```

---

## ⚡ 一键脚本 (可选)

创建 `deploy.sh`:

```bash
#!/bin/bash
# 一键部署脚本

set -e

echo "🚀 一键部署到 GitHub..."

# 推送代码
git add .
git commit -m "Auto deploy: $(date '+%Y-%m-%d %H:%M')"
git push

echo "✅ 推送完成!"
echo ""
echo "📊 查看构建:"
echo "   https://github.com/YOUR_USERNAME/pawchat-android/actions"
echo ""
echo "⏱️  构建时间：5-10 分钟"
```

使用:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🐛 故障排除

### 构建失败

**查看日志**:
```
Actions → 点击失败的构建 → 查看错误
```

**常见错误**:
- `pubspec.yaml` 格式错误 → 检查 YAML 缩进
- 依赖冲突 → 运行 `flutter pub get` 本地测试
- 编译错误 → 运行 `flutter analyze` 检查代码

### 下载失败

- Artifacts 保留 30 天
- 过期需要重新构建
- 使用 Releases 永久保存

### 安装失败

- 检查"安装未知应用"权限
- 检查 Android 版本兼容性
- 尝试卸载旧版本后重新安装

---

## 📞 快速参考

| 操作 | 命令/链接 |
|------|----------|
| 创建仓库 | https://github.com/new |
| 查看构建 | https://github.com/USER/pawchat-android/actions |
| 下载 APK | Actions → Artifacts |
| 发布版本 | `git tag v1.1.0 && git push origin v1.1.0` |
| 本地测试 | `flutter analyze` |

---

*准备好开始了吗？运行 `./setup-github.sh`！🐾*
