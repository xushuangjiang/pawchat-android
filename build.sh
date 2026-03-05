#!/bin/bash
# PawChat Android 快速构建脚本
# 用于在 PC 上快速构建 APK

set -e

echo "🐾 PawChat Android 构建脚本"
echo "=========================="
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装"
    echo "请先安装 Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter 已安装"
flutter --version
echo ""

# 检查 Android 许可证
if ! flutter config --android-sdk &> /dev/null; then
    echo "⚠️  Android SDK 未配置"
    echo "请安装 Android Studio 并配置 SDK"
    exit 1
fi

echo "✅ Android SDK 已配置"
echo ""

# 获取依赖
echo "📦 获取依赖..."
flutter pub get
echo ""

# 清理构建
echo "🧹 清理旧构建..."
flutter clean
echo ""

# 构建 APK
echo "🔨 构建发布版 APK..."
flutter build apk --release --split-per-abi
echo ""

# 显示输出
echo "✅ 构建完成!"
echo ""
echo "📦 APK 文件位置:"
echo "   - app-arm64-v8a-release.apk (三星 S24 Ultra 使用这个)"
echo "   - app-armeabi-v7a-release.apk"
echo "   - app-x86_64-release.apk"
echo ""
echo "📍 完整路径:"
ls -lh build/app/outputs/flutter-apk/*.apk
echo ""

# 检查 ADB 设备
if command -v adb &> /dev/null; then
    echo "📱 检测到的设备:"
    adb devices || echo "   无设备连接"
    echo ""
    echo "💡 安装命令:"
    echo "   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
fi

echo ""
echo "🎉 完成!"
