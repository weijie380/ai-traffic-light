.PHONY: all build bundle install clean run

APP_NAME := TrafficLightApp
BUNDLE_NAME := AI Traffic Light.app
SOURCES := $(wildcard Sources/TrafficLightApp/*.swift)
FRAMEWORKS := -framework Cocoa -framework UserNotifications -framework ServiceManagement -framework SwiftUI
SWIFT_FLAGS := -target arm64-apple-macosx13.0 -O

all: bundle

# ─── 编译 ───────────────────────────────────────
build: $(SOURCES)
	swiftc $(SWIFT_FLAGS) -o $(APP_NAME) $(SOURCES) $(FRAMEWORKS)
	@echo "✅ 编译完成: $(APP_NAME)"

# ─── 打包 .app ─────────────────────────────────
bundle: build
	rm -rf "$(BUNDLE_NAME)"
	mkdir -p "$(BUNDLE_NAME)/Contents/MacOS"
	mkdir -p "$(BUNDLE_NAME)/Contents/Resources"
	cp $(APP_NAME) "$(BUNDLE_NAME)/Contents/MacOS/"
	cp Sources/TrafficLightApp/Info.plist "$(BUNDLE_NAME)/Contents/"
	@echo "✅ 打包完成: $(BUNDLE_NAME)"

# ─── 安装到 /Applications ─────────────────────
install: bundle
	cp -r "$(BUNDLE_NAME)" /Applications/
	@echo "✅ 已安装到 /Applications/$(BUNDLE_NAME)"
	@echo ""
	@echo "  🚦  打开方式："
	@echo "   - 在 Finder 中双击 /Applications/$(BUNDLE_NAME)"
	@echo "   - 或输入: open /Applications/$(BUNDLE_NAME)"

# ─── 运行（不打包直接运行） ────────────────────
run: build
	./$(APP_NAME) &

# ─── 清理 ───────────────────────────────────────
clean:
	rm -f $(APP_NAME)
	rm -rf "$(BUNDLE_NAME)"

# ─── 压缩用于分发 ───────────────────────────────
dist: bundle
	rm -f "$(BUNDLE_NAME).zip"
	ditto -c -k --sequesterRsrc --keepParent "$(BUNDLE_NAME)" "$(BUNDLE_NAME).zip"
	@echo "✅ 分发包: $(BUNDLE_NAME).zip"
	@ls -lh "$(BUNDLE_NAME).zip"
