#!/bin/bash
# Flutter + Android SDK 自动安装脚本
# 适用于树莓派/ARM64 Linux

set -e

echo "🐾 Flutter + Android SDK 自动安装"
echo "=================================="
echo ""

# 1. 安装 Java
echo "☕ 步骤 1/5: 安装 Java 17..."
apt-get update
apt-get install -y openjdk-17-jdk-headless
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
echo "✅ Java 已安装"
java -version
echo ""

# 2. 下载 Flutter
echo "📦 步骤 2/5: 下载 Flutter..."
cd ~
if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:$HOME/flutter/bin"
echo "✅ Flutter 已下载"
flutter --version
echo ""

# 3. 下载 Android SDK 工具
echo "🤖 步骤 3/5: 下载 Android SDK..."
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools

if [ ! -f "commandlinetools.zip" ]; then
    curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
fi

if [ ! -d "latest" ]; then
    unzip -q commandlinetools.zip
    mv cmdline-tools latest
fi

export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
echo "✅ Android SDK 工具已下载"
echo ""

# 4. 安装 Android SDK 组件
echo "📱 步骤 4/5: 安装 SDK 组件..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
echo "✅ SDK 组件已安装"
echo ""

# 5. 配置 Flutter
echo "🔧 步骤 5/5: 配置 Flutter..."
flutter config --android-sdk $ANDROID_HOME
flutter doctor -v
echo ""

echo "=================================="
echo "✅ 安装完成!"
echo ""
echo "环境变量 (添加到 ~/.bashrc):"
echo "  export PATH=\"\$PATH:\$HOME/flutter/bin:\$HOME/Android/Sdk/cmdline-tools/latest/bin:\$HOME/Android/Sdk/platform-tools\""
echo "  export ANDROID_HOME=\"\$HOME/Android/Sdk\""
echo "  export JAVA_HOME=\"/usr/lib/jvm/java-17-openjdk-arm64\""
echo ""
