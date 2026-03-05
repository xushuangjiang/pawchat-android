#!/bin/bash
# 监控 GitHub Actions 构建进度

REPO="xsj/pawchat-android"
echo "🔍 监控仓库：$REPO"
echo "================================"
echo ""

# 获取最新运行
echo "📊 最新构建运行:"
gh run list --repo $REPO --limit 5 2>/dev/null || {
    echo "⚠️  无法获取运行列表"
    echo ""
    echo "可能原因:"
    echo "1. GitHub CLI 未认证"
    echo "2. 仓库不存在"
    echo "3. 尚未触发构建"
    echo ""
    echo "请手动访问:"
    echo "https://github.com/$REPO/actions"
    exit 1
}

echo ""

# 获取进行中的运行
RUNNING=$(gh run list --repo $REPO --json status,databaseId -q '.[] | select(.status=="queued" or .status=="in_progress") | .databaseId' 2>/dev/null | head -1)

if [ -n "$RUNNING" ]; then
    echo "🟡 发现进行中的构建：$RUNNING"
    echo ""
    echo "查看详细日志:"
    echo "https://github.com/$REPO/actions/runs/$RUNNING"
else
    echo "✅ 没有进行中的构建"
    echo ""
    echo "查看所有运行:"
    echo "https://github.com/$REPO/actions"
fi

echo ""
echo "================================"
echo "🕐 检查时间：$(date '+%Y-%m-%d %H:%M:%S')"
