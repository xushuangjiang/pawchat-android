#!/bin/bash
# PawChat Android - 快速推送到 GitHub
# 自动初始化 Git 仓库并推送代码

set -e

echo "🐾 PawChat Android - GitHub 推送脚本"
echo "===================================="
echo ""

# 检查 Git
if ! command -v git &> /dev/null; then
    echo "❌ Git 未安装"
    echo "请安装：sudo apt install git"
    exit 1
fi

echo "✅ Git 已安装"
git --version
echo ""

# 配置用户信息
echo "📝 配置 Git 用户信息:"
read -p "GitHub 用户名：" GITHUB_USERNAME
read -p "邮箱：" GIT_EMAIL

git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GIT_EMAIL"

echo ""
echo "✅ Git 配置完成:"
git config --global user.name
git config --global user.email
echo ""

# 进入项目目录
cd ~/.openclaw/workspace/pawchat-android

# 检查是否已初始化
if [ -d ".git" ]; then
    echo "⚠️  Git 仓库已存在"
    read -p "是否重新初始化？(y/N): " REINIT
    if [ "$REINIT" = "y" ]; then
        rm -rf .git
        echo "🗑️  已删除旧 Git 仓库"
    else
        echo "⏭️  跳过初始化"
    fi
fi

# 初始化 Git
if [ ! -d ".git" ]; then
    echo "📦 初始化 Git 仓库..."
    git init
    echo ""
fi

# 添加所有文件
echo "📂 添加文件..."
git add .
echo ""

# 首次提交
echo "💾 创建首次提交..."
git commit -m "Initial commit: PawChat Android v1.1

Features:
- WebSocket connection & messaging
- Session management
- Message caching
- Auto-reconnect
- Message search
- Attachment upload
- Push notifications

Version: 1.1.0
Date: 2026-03-05"
echo ""

# 设置主分支
git branch -M main
echo "✅ 主分支设置为 main"
echo ""

# 添加远程仓库
echo "🔗 添加远程仓库:"
REMOTE_URL="https://github.com/${GITHUB_USERNAME}/pawchat-android.git"
echo "   $REMOTE_URL"
echo ""

# 检查是否已存在
if git remote | grep -q "origin"; then
    echo "⚠️  origin 已存在"
    git remote remove origin
    echo "🗑️  已删除旧 origin"
fi

git remote add origin "$REMOTE_URL"
echo "✅ 远程仓库已添加"
echo ""

# 显示下一步指令
echo "======================================"
echo "📋 下一步操作:"
echo "======================================"
echo ""
echo "1️⃣  在 GitHub 上创建仓库:"
echo "   访问：https://github.com/new"
echo "   仓库名：pawchat-android"
echo "   可见性：Public 或 Private"
echo "   ❌ 不要初始化 README"
echo ""
echo "2️⃣  推送代码:"
echo "   git push -u origin main"
echo ""
echo "3️⃣  查看构建:"
echo "   访问：https://github.com/${GITHUB_USERNAME}/pawchat-android/actions"
echo ""
echo "4️⃣  下载 APK (构建完成后):"
echo "   - app-arm64-v8a-release.apk (三星 S24 Ultra)"
echo ""
echo "======================================"
echo ""
read -p "是否现在推送？(y/N): " PUSH_NOW

if [ "$PUSH_NOW" = "y" ]; then
    echo "🚀 推送代码到 GitHub..."
    git push -u origin main
    echo ""
    echo "✅ 推送完成!"
    echo ""
    echo "🌐 访问仓库:"
    echo "   https://github.com/${GITHUB_USERNAME}/pawchat-android"
    echo ""
    echo "📊 查看构建:"
    echo "   https://github.com/${GITHUB_USERNAME}/pawchat-android/actions"
    echo ""
else
    echo "💡 稍后手动推送:"
    echo "   git push -u origin main"
    echo ""
fi

echo "🎉 完成!"
