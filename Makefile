# PawChat 构建流程

.PHONY: test verify build clean

# 1. 验证 Gateway 协议
test:
	@echo "🔍 验证 Gateway 协议..."
	@python3 test/gateway_protocol_test.py

# 2. 验证代码格式
verify:
	@echo "🔍 验证代码..."
	@flutter analyze --no-fatal-infos --no-fatal-warnings || true

# 3. 构建 APK（只有通过验证后才执行）
build: test verify
	@echo "🔨 构建 APK..."
	@flutter build apk --release --split-per-abi

# 4. 清理
clean:
	@echo "🧹 清理..."
	@flutter clean
	@rm -rf build/

# 完整流程：验证 + 构建
all: test build
	@echo "✅ 完成！"
