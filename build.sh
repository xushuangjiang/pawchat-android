#!/bin/bash
# PawChat 构建脚本
# 需要在安装 Flutter 的环境中运行

set -e

echo "================================"
echo "PawChat 构建脚本"
echo "================================"
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: 未找到 Flutter"
    echo "请安装 Flutter SDK: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✓ Flutter 版本:"
flutter --version
echo ""

# 检查依赖
echo "🔍 检查依赖..."
flutter pub get
echo ""

# 运行测试
echo "🔍 运行协议验证测试..."
python3 test/gateway_protocol_test.py
if [ $? -ne 0 ]; then
    echo "❌ 协议验证失败"
    exit 1
fi
echo ""

echo "🔍 运行 WebChat 兼容性测试..."
python3 test/webchat_validation_test.py
if [ $? -ne 0 ]; then
    echo "❌ 兼容性测试失败"
    exit 1
fi
echo ""

# 代码分析
echo "🔍 运行 Flutter 分析..."
flutter analyze || true
echo ""

# 构建 APK
echo "🔨 构建 release APK..."
flutter build apk --release --split-per-abi

echo ""
echo "================================"
echo "✅ 构建完成!"
echo "================================"
echo ""
echo "输出文件:"
ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || echo "APK 文件未找到"
echo ""
echo "安装命令:"
echo "  adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
