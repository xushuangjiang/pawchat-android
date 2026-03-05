#!/bin/bash
# PawChat Android - 自动验证脚本

set -e

echo "🐾 PawChat Android 验证脚本"
echo "=========================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Flutter
echo "📱 检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter 未安装${NC}"
    echo ""
    echo "请先安装 Flutter:"
    echo "  macOS: brew install --cask flutter"
    echo "  Linux: sudo snap install flutter --classic"
    echo "  详情：https://docs.flutter.dev/get-started/install"
    exit 1
fi
echo -e "${GREEN}✅ Flutter 已安装${NC}"
flutter --version | head -1
echo ""

# 检查项目目录
echo "📁 检查项目结构..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ pubspec.yaml 不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✅ pubspec.yaml 存在${NC}"

# 检查关键文件
KEY_FILES=(
    "lib/main.dart"
    "lib/core/websocket/gateway_client.dart"
    "lib/core/websocket/protocol.dart"
    "lib/features/chat/bloc/chat_bloc.dart"
    "lib/features/chat/presentation/chat_screen.dart"
)

for file in "${KEY_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✅ $file${NC}"
    else
        echo -e "${RED}  ❌ $file (缺失)${NC}"
    fi
done
echo ""

# 获取依赖
echo "📦 获取依赖..."
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 依赖获取成功${NC}"
else
    echo -e "${RED}❌ 依赖获取失败${NC}"
    exit 1
fi
echo ""

# 代码分析
echo "🔍 代码分析..."
flutter analyze --no-fatal-infos --no-fatal-warnings
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 代码分析通过${NC}"
else
    echo -e "${YELLOW}⚠️  代码分析有警告 (请查看上方输出)${NC}"
fi
echo ""

# 统计信息
echo "📊 项目统计..."
DART_FILES=$(find lib -name "*.dart" | wc -l)
echo "  Dart 文件数：$DART_FILES"

LINES_OF_CODE=$(find lib -name "*.dart" -exec cat {} \; | wc -l)
echo "  代码行数：$LINES_OF_CODE"
echo ""

# 检查 Gateway
echo "🌐 检查 OpenClaw Gateway..."
if command -v openclaw &> /dev/null; then
    if openclaw gateway status &> /dev/null; then
        echo -e "${GREEN}✅ Gateway 运行中${NC}"
    else
        echo -e "${YELLOW}⚠️  Gateway 未运行${NC}"
        echo "  启动命令：openclaw gateway start"
    fi
else
    echo -e "${YELLOW}⚠️  OpenClaw 未安装${NC}"
fi
echo ""

# 总结
echo "=========================="
echo -e "${GREEN}✅ 验证完成!${NC}"
echo ""
echo "下一步:"
echo "  1. 启动 Android 模拟器或连接真机"
echo "  2. 运行：flutter run"
echo "  3. 配置 Gateway 地址并开始聊天"
echo ""
echo "文档:"
echo "  - QUICKSTART.md  快速开始"
echo "  - README.md      完整文档"
echo "  - VERIFY.md      验证清单"
echo ""
