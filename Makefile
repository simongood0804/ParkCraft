.PHONY: help get clean clean-all run build-apk build-apk-release install uninstall analyze test test-watch format upgrade lint fix

help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ─── 依赖管理 ─────────────────────────────────────────────

get: ## 安装/更新项目依赖
	flutter pub get

upgrade: ## 升级所有依赖到最新兼容版本
	flutter pub upgrade

clean: ## 清除构建产物
	flutter clean
	@rm -rf .dart_tool/

clean-all: clean ## 深度清理（清除构建产物 + pub 缓存）
	cd android && ./gradlew clean 2>/dev/null || true
	flutter pub cache repair

# ─── 编译 ────────────────────────────────────────────────

build-apk: ## 编译 debug APK
	flutter build apk --debug

build-apk-release: ## 编译 release APK（需要签名配置）
	flutter build apk --release

build-ios: ## 编译 iOS（仅 macOS，需要 Xcode）
	flutter build ios --debug

build-ios-release: ## 编译 iOS release（仅 macOS，需要 Xcode）
	flutter build ios --release

build-web: ## 编译 Web 版本
	flutter build web

# ─── 运行与安装 ───────────────────────────────────────────

run: ## 在已连接的设备上运行
	flutter run

run-release: ## 以 release 模式运行
	flutter run --release

install: ## 安装 APK 到已连接的 Android 设备
	flutter install

uninstall: ## 从已连接的 Android 设备卸载
	@echo "正在从设备卸载 com.example.parkcraft..."
	@adb uninstall com.example.parkcraft 2>/dev/null || \
		flutter install --uninstall-only 2>/dev/null || \
		echo "卸载失败，请手动卸载。"

# ─── 代码质量 ────────────────────────────────────────────

analyze: ## 运行静态代码分析
	flutter analyze

lint: analyze ## 别名：运行静态代码分析

fix: ## 自动修复 lint 问题
	dart fix --apply

format: ## 格式化所有 Dart 代码
	dart format lib/ test/

# ─── 测试 ────────────────────────────────────────────────

test: ## 运行所有测试
	flutter test

test-watch: ## 持续运行测试（文件变更时自动重跑）
	flutter test --watch

test-coverage: ## 运行测试并生成覆盖率报告
	flutter test --coverage
	@echo "覆盖率报告已生成至 coverage/lcov.info"
	@echo "使用 genhtml coverage/lcov.info -o coverage/html 可查看 HTML 报告"

# ─── 发布 ────────────────────────────────────────────────

build-all: clean get ## 全量构建（清理 → 安装依赖 → 编译 debug APK）
	flutter build apk --debug

build-all-release: clean get ## 全量构建 release
	flutter build apk --release

# ─── 工具 ────────────────────────────────────────────────

doctor: ## 检查 Flutter 环境
	flutter doctor -v

outdated: ## 检查过时依赖
	flutter pub outdated

deps: ## 显示依赖树
	flutter pub deps
