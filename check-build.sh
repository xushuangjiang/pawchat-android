#!/bin/bash
# 监控 Flutter 构建状态

echo "🔍 检查构建状态..."
echo ""

# 检查进程
echo "=== 进程状态 ==="
FLUTTER_PID=$(pgrep -f "flutter build")
GRADLE_PID=$(pgrep -f "gradle")

if [ -n "$FLUTTER_PID" ]; then
    echo "✅ Flutter 进程运行中 (PID: $FLUTTER_PID)"
    ps aux | grep -E "flutter" | grep -v grep | head -3
else
    echo "❌ 无 Flutter 进程"
fi

if [ -n "$GRADLE_PID" ]; then
    echo "✅ Gradle 进程运行中 (PID: $GRADLE_PID)"
else
    echo "⏳ Gradle 未运行 (可能已下载完成)"
fi

echo ""
echo "=== 最新日志 (最后 20 行) ==="
tail -20 ~/build-log.txt 2>/dev/null || echo "日志文件不存在"

echo ""
echo "=== 构建目录 ==="
ls -la ~/.openclaw/workspace/pawchat-android/build/app/outputs/ 2>/dev/null | head -10 || echo "构建目录不存在"

echo ""
echo "=== APK 文件 ==="
find ~/.openclaw/workspace/pawchat-android/build -name "*.apk" 2>/dev/null | head -5 || echo "暂无 APK"
