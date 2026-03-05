# 🚀 GitHub Actions 自动构建指南

**目标**: 自动构建 PawChat Android APK，无需本地环境  
**适用**: 三星 S24 Ultra (ARM64)

---

## 📋 步骤概览

1. 创建 GitHub 仓库
2. 推送代码
3. 自动构建
4. 下载 APK

---

## 1️⃣ 创建 GitHub 仓库

### 在 GitHub 上创建新仓库

```bash
# 访问 https://github.com/new
# 仓库名：pawchat-android
# 可见性：Public 或 Private
# 不要初始化 README (我们已有代码)
```

### 初始化本地 Git

```bash
cd ~/.openclaw/workspace/pawchat-android

# 初始化 Git
git init

# 添加所有文件
git add .

# 首次提交
git commit -m "Initial commit: PawChat Android v1.1"

# 添加远程仓库 (替换 YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/pawchat-android.git

# 推送到 main 分支
git branch -M main
git push -u origin main
```

---

## 2️⃣ 触发自动构建

### 方式 A: 推送代码自动构建

```bash
# 每次推送到 main 或 develop 分支都会自动构建
git add .
git commit -m "Fix: something"
git push
```

### 方式 B: 手动触发构建

1. 访问 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **Build APK** 工作流
4. 点击 **Run workflow**
5. 选择分支 (main)
6. 点击 **Run workflow**

### 方式 C: 创建 Release (推荐)

```bash
# 打标签并推送 (触发自动发布)
git tag v1.1.0
git push origin v1.1.0
```

---

## 3️⃣ 等待构建完成

### 查看构建进度

1. 访问 https://github.com/YOUR_USERNAME/pawchat-android/actions
2. 查看最新构建任务
3. 等待完成 (约 5-10 分钟)

### 构建产物

**普通推送** → Artifacts (保留 30 天)
- 点击构建任务
- 滚动到底部
- 下载 `pawchat-apks`

**创建 Tag** → Releases (永久)
- 访问 Releases 页面
- 下载最新版本的 APK

---

## 4️⃣ 下载 APK

### 从 Artifacts 下载

1. 访问 Actions → 最新构建
2. 滚动到底部 **Artifacts**
3. 点击 `pawchat-apks`
4. 下载 ZIP 文件
5. 解压得到:
   - `app-arm64-v8a-release.apk` ← **S24 Ultra 使用这个**
   - `app-armeabi-v7a-release.apk`
   - `app-x86_64-release.apk`

### 从 Releases 下载 (如果打了 Tag)

1. 访问 https://github.com/YOUR_USERNAME/pawchat-android/releases
2. 点击最新版本 (如 v1.1.0)
3. 下载 `app-arm64-v8a-release.apk`

---

## 5️⃣ 安装到三星 S24 Ultra

### 方法 1: USB 安装 (推荐)

```bash
# 手机设置:
# 1. 设置 → 关于手机 → 软件信息
# 2. 连续点击"编译编号"7 次
# 3. 设置 → 开发者选项 → 启用"USB 调试"
# 4. USB 连接电脑

# 电脑执行:
adb install app-arm64-v8a-release.apk
```

### 方法 2: 直接传输

1. 将 APK 传到手机 (微信/QQ/邮件/USB)
2. 在手机上点击 APK 文件
3. 允许"安装未知应用"
4. 点击安装

---

## 📊 工作流说明

### build.yml - 常规构建

**触发条件**:
- 推送到 main/develop 分支
- Pull Request
- 手动触发

**产物**:
- APK (split per ABI)
- App Bundle (Play Store)

### analyze.yml - 代码质量检查

**触发条件**:
- 推送到 main/develop 分支
- Pull Request

**检查**:
- Flutter analyze
- 运行测试 (如果有)

### release.yml - 自动发布

**触发条件**:
- 创建 Tag (如 v1.1.0)

**产物**:
- GitHub Release
- 所有 APK 文件
- App Bundle

---

## 🔧 自定义配置

### 修改 Flutter 版本

编辑 `.github/workflows/build.yml`:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.19.0'  # 修改版本号
    channel: 'stable'
```

### 修改构建参数

```yaml
- name: Build APK
  run: flutter build apk --release --split-per-abi
  # 可以添加更多参数
```

### 添加签名 (发布到 Play Store)

创建 `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=YOUR_KEYSTORE_FILE
```

修改 `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            keyAlias 'your-key-alias'
            keyPassword 'your-key-password'
            storeFile file('your-keystore.jks')
            storePassword 'your-store-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## ⚡ 快速开始 (复制粘贴)

```bash
# 1. 进入项目目录
cd ~/.openclaw/workspace/pawchat-android

# 2. 初始化 Git
git init
git add .
git commit -m "Initial commit"

# 3. 添加远程仓库 (替换 YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/pawchat-android.git

# 4. 推送代码
git branch -M main
git push -u origin main

# 5. 等待构建完成 (访问 GitHub Actions)
# https://github.com/YOUR_USERNAME/pawchat-android/actions

# 6. 下载 APK (构建完成后)
# - app-arm64-v8a-release.apk (S24 Ultra)

# 7. 安装到手机
adb install app-arm64-v8a-release.apk
```

---

## 📝 版本发布流程

```bash
# 1. 更新版本号
# 修改 pubspec.yaml: version: 1.1.0+1

# 2. 提交更改
git add .
git commit -m "Release v1.1.0"

# 3. 打标签
git tag v1.1.0

# 4. 推送标签 (触发自动发布)
git push origin v1.1.0

# 5. 访问 Releases 下载
# https://github.com/YOUR_USERNAME/pawchat-android/releases
```

---

## 🐛 常见问题

### Q: 构建失败？

**查看日志**:
1. 访问 Actions
2. 点击失败的构建
3. 查看错误信息

**常见错误**:
- `flutter pub get` 失败 → 检查 `pubspec.yaml` 格式
- 编译错误 → 查看 `flutter analyze` 输出
- 内存不足 → GitHub Actions 默认 7GB RAM

### Q: 构建太慢？

- 首次构建需要下载依赖 (5-10 分钟)
- 后续构建会使用缓存 (2-5 分钟)
- 使用 `cache: true` 启用缓存

### Q: 如何下载特定架构的 APK？

- S24 Ultra (ARM64): `app-arm64-v8a-release.apk`
- 旧设备 (ARMv7): `app-armeabi-v7a-release.apk`
- 模拟器 (x86_64): `app-x86_64-release.apk`

---

## 📞 需要帮助？

1. 查看 GitHub Actions 日志
2. 检查 `.github/workflows/` 配置
3. 运行 `flutter analyze` 本地检查

---

*准备好推送代码了吗？🐾*
