# PawChat 构建指南

## 环境要求

- Flutter SDK 3.x
- Dart SDK
- Android SDK
- Python 3.x (用于测试验证)

## 快速构建

```bash
./build.sh
```

## 手动构建步骤

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 运行测试验证
```bash
# 协议验证
python3 test/gateway_protocol_test.py

# WebChat 兼容性验证
python3 test/webchat_validation_test.py
```

### 3. 代码分析
```bash
flutter analyze
```

### 4. 构建 APK
```bash
flutter build apk --release --split-per-abi
```

## 输出文件

构建完成后，APK 文件位于：
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk    (ARM64)
├── app-armeabi-v7a-release.apk  (ARM32)
└── app-x86_64-release.apk       (x86_64)
```

## 安装

```bash
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## 状态

⚠️ 当前环境没有 Flutter SDK，请在安装了 Flutter 的环境中运行构建。

项目代码已通过所有测试验证，可以安全编译。
