# PawChat 构建流程
# ⚠️ 开发中版本，尚未经过完整测试验证

.PHONY: test verify build clean

# 1. 验证 Gateway 协议（必需通过）
test:
	@echo "🔍 验证 Gateway 协议..."
	@python3 test/gateway_protocol_test.py
	@echo "🔍 验证 WebChat 兼容性..."
	@python3 test/webchat_validation_test.py

# 2. 验证代码格式（可选）
verify:
	@echo "🔍 验证代码..."
	@flutter analyze --no-fatal-infos --no-fatal-warnings 2>/dev/null || echo "⚠️  flutter analyze 未通过或 flutter 未安装"

# 3. 构建 APK（⚠️ 开发中版本，不建议发布）
build:
	@echo "⚠️  警告：这是开发中版本，尚未经过完整测试"
	@echo "🔨 构建 APK..."
	@flutter build apk --release --split-per-abi 2>/dev/null || echo "❌ 构建失败，请检查 flutter 环境"

# 4. 清理
clean:
	@echo "🧹 清理..."
	@flutter clean 2>/dev/null || true
	@rm -rf build/

# 完整流程：验证（不自动构建，需要手动确认）
all: test
	@echo ""
	@echo "✅ 验证完成"
	@echo "⚠️  这是开发中版本 (v0.2.0-beta)"
	@echo "📋 如需构建，请手动运行: make build"
	@echo "❌ 请勿发布到应用商店"
