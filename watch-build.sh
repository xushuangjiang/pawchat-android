#!/bin/bash
# 实时监控 GitHub Actions 构建

REPO="xsj/pawchat-android"
INTERVAL=10

echo "🔍 监控仓库：$REPO"
echo "================================"
echo ""

while true; do
    echo "🕐 $(date '+%H:%M:%S') - 检查构建状态..."
    echo ""
    
    # 获取最新运行
    RUNS=$(gh run list --repo $REPO --limit 3 --json status,conclusion,name,startedAt 2>/dev/null)
    
    if [ -z "$RUNS" ]; then
        echo "⏳ 暂无构建运行"
        echo ""
        echo "可能原因:"
        echo "1. 工作流文件未检测到"
        echo "2. Actions 未启用"
        echo "3. 推送未触发"
        echo ""
        echo "请检查:"
        echo "https://github.com/$REPO/actions"
    else
        echo "$RUNS" | jq -r '.[] | "📊 \(.name): \(.status) - \(.startedAt)"' 2>/dev/null || echo "$RUNS"
    fi
    
    echo ""
    echo "--------------------------------"
    echo "下次检查：${INTERVAL}秒后 (Ctrl+C 停止)"
    echo ""
    
    sleep $INTERVAL
done
