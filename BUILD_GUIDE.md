# 📱 PawChat Android - 构建指南

**目标设备**: 三星 Galaxy S24 Ultra (Android 14, ARM64)  
**构建日期**: 2026-03-05

---

## ⚠️ 当前环境状态

**检查时间**: 2026-03-05 14:35

| 组件 | 状态 | 说明 |
|------|------|------|
| Flutter SDK | ❌ 未安装 | 需要安装 |
| Android SDK | ❌ 未安装 | 需要安装 |
| Java JDK | ❌ 未安装 | 需要安装 |
| 项目 Android 配置 | ❌ 未初始化 | 需要创建 |

---

## 🚀 方案选择

### 方案 A: 在 PC 上构建 (推荐 ⭐)

**优点**:
- ✅ 构建速度快
- ✅ 调试方便
- ✅ 可以直接连接手机测试

**步骤**:
1. 在 PC 上安装 Flutter
2. 克隆/复制项目
3. 运行构建命令

### 方案 B: 使用 GitHub Actions 自动构建

**优点**:
- ✅ 无需本地环境
- ✅ 自动化 CI/CD
- ✅ 每次提交自动构建

**步骤**:
1. 创建 GitHub 仓库
2. 配置 GitHub Actions
3. 推送代码自动构建

### 方案 C: 在当前设备 (树莓派) 安装 Flutter

**不推荐**:
- ❌ 树莓派性能有限
- ❌ Android SDK 占用大 (10GB+)
- ❌ 构建速度慢

---

## 📋 方案 A: PC 构建详细步骤

### 1️⃣ 安装 Flutter

**Windows**:
```powershell
# 下载 Flutter SDK
# 访问：https://docs.flutter.dev/get-started/install/windows

# 解压到 C:\src\flutter
# 添加到 PATH

# 验证安装
flutter doctor
```

**macOS**:
```bash
# 使用 Homebrew
brew install --cask flutter

# 验证安装
flutter doctor
```

**Linux**:
```bash
# 下载 Flutter SDK
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# 添加到 PATH
export PATH="$PATH:$HOME/flutter/bin"

# 验证安装
flutter doctor
```

### 2️⃣ 安装 Android Studio

```bash
# 下载 Android Studio
# https://developer.android.com/studio

# 安装后打开 Android Studio
# Tools → SDK Manager → 安装:
# - Android SDK Platform 34 (Android 14)
# - Android SDK Build-Tools
# - Android Emulator (可选)
```

### 3️⃣ 接受 Android 许可证

```bash
flutter doctor --android-licenses
# 输入 y 接受所有许可证
```

### 4️⃣ 配置项目

```bash
# 进入项目目录
cd pawchat-android

# 获取依赖
flutter pub get

# 检查配置
flutter doctor
```

### 5️⃣ 连接手机

**三星 S24 Ultra 设置**:
1. 设置 → 关于手机 → 软件信息
2. 连续点击"编译编号"7次 (启用开发者选项)
3. 设置 → 开发者选项
4. 启用"USB 调试"
5. 用 USB 连接电脑
6. 手机上允许 USB 调试授权

**验证连接**:
```bash
adb devices
# 应该看到设备序列号
```

### 6️⃣ 构建 APK

**调试版 (快速测试)**:
```bash
flutter build apk --debug
# 输出：build/app/outputs/flutter-apk/app-debug.apk
```

**发布版 (正式使用)**:
```bash
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk
```

**分架构 APK (更小体积)**:
```bash
flutter build apk --split-per-abi
# 输出：
# - app-arm64-v8a-release.apk (S24 Ultra 使用这个)
# - app-armeabi-v7a-release.apk
# - app-x86_64-release.apk
```

### 7️⃣ 安装到手机

**方法 1: ADB 安装**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**方法 2: 直接传输**
```bash
# 将 APK 文件传到手机
# 在手机上点击安装
```

---

## 🔧 项目配置 (必需)

### Android 权限配置

创建/修改 `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 网络权限 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- 通知权限 (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <!-- 相机权限 (附件上传) -->
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <!-- 存储权限 (附件上传) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    
    <!-- 媒体权限 (Android 13+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    
    <application
        android:label="PawChat"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 构建配置

修改 `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.pawchat.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.1.0"
    }
}
```

---

## 📦 构建产物

**输出位置**: `build/app/outputs/flutter-apk/`

| 文件 | 大小 | 用途 |
|------|------|------|
| `app-debug.apk` | ~50MB | 调试版 (包含调试信息) |
| `app-release.apk` | ~30MB | 发布版 (优化后) |
| `app-arm64-v8a-release.apk` | ~25MB | S24 Ultra 专用 (推荐) |

---

## 🐛 常见问题

### 1. Flutter Doctor 报错

```bash
# 查看详细信息
flutter doctor -v

# 根据提示修复
```

### 2. Android 许可证未接受

```bash
flutter doctor --android-licenses
```

### 3. 设备未识别

```bash
# 检查 USB 连接
adb devices

# 重启 ADB 服务
adb kill-server
adb start-server

# 重新连接设备
```

### 4. 构建失败

```bash
# 清理构建缓存
flutter clean

# 重新获取依赖
flutter pub get

# 重新构建
flutter build apk --release
```

---

## 📱 三星 S24 Ultra 特殊配置

**设备信息**:
- 型号：SM-S9280 / SM-S928B / SM-S928U
- Android 版本：14 (One UI 6.1)
- 架构：ARM64-v8a (骁龙 8 Gen 3)

**建议配置**:
```bash
# 构建专用 APK (最小体积)
flutter build apk --split-per-abi --target-platform android-arm64

# 安装
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 🎯 快速开始 (复制粘贴)

```bash
# 1. 在 PC 上克隆项目
git clone <项目地址>
cd pawchat-android

# 2. 获取依赖
flutter pub get

# 3. 连接手机
adb devices

# 4. 构建并安装
flutter run --release

# 或构建 APK
flutter build apk --release --split-per-abi

# 5. 安装
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 📞 需要帮助？

如果遇到问题，请提供:
1. `flutter doctor -v` 输出
2. 构建错误日志
3. 手机型号和 Android 版本

---

*最后更新：2026-03-05*  
*维护者：爪爪 🐾*
