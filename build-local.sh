#!/bin/bash
# PawChat Android - 全自动本地构建脚本
# 适用于树莓派/ARM64 设备

set -e

echo "🐾 PawChat Android - 全自动构建脚本"
echo "===================================="
echo ""

# 设置环境变量
export PATH="$PATH:$HOME/flutter/bin"
export ANDROID_HOME="$HOME/Android/Sdk"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-arm64"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

cd ~/.openclaw/workspace/pawchat-android

echo "📦 步骤 1/4: 获取依赖..."
flutter pub get
echo ""

echo "🔨 步骤 2/4: 代码分析..."
flutter analyze || echo "⚠️  分析警告（继续构建）"
echo ""

echo "🏗️  步骤 3/4: 构建 APK..."
flutter build apk --release --split-per-abi
echo ""

echo "✅ 步骤 4/4: 收集产物..."
echo ""
echo "📦 APK 文件位置:"
find build/app/outputs/flutter-apk -name "*.apk" -type f -exec ls -lh {} \;
echo ""

# 复制到方便的位置
mkdir -p ~/pawchat-apks
cp build/app/outputs/flutter-apk/app-*.apk ~/pawchat-apks/ 2>/dev/null || true

echo "📍 已复制到：~/pawchat-apks/"
ls -lh ~/pawchat-apks/
echo ""

echo "🎉 构建完成!"
echo ""
echo "📱 安装到 S24 Ultra:"
echo "   1. 复制 APK 到手机"
echo "   2. 安装 app-arm64-v8a-release.apk"
echo ""
echo "🔗 或使用 ADB:"
echo "   adb install ~/pawchat-apks/app-arm64-v8a-release.apk"
