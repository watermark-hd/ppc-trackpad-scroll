# PPC Trackpad Scroll - Makefile
# Mac OS X 10.4 Tiger / 10.5 Leopard (PowerPC) 向けビルド
# Xcode（xcodebuild）を使わず gcc + ld で直接ビルドする

APP_NAME   = PPC Trackpad Scroll
EXEC_NAME  = PPCTrackpadScroll
APP_BUNDLE = $(APP_NAME).app
CONTENTS   = $(APP_BUNDLE)/Contents
MACOS_DIR  = $(CONTENTS)/MacOS
RESOURCES  = $(CONTENTS)/Resources
EXECUTABLE = $(MACOS_DIR)/$(EXEC_NAME)

SDKROOT    = /Developer/SDKs/MacOSX10.4u.sdk
ARCH       = ppc
CC         = gcc
CFLAGS     = -arch $(ARCH) -isysroot $(SDKROOT) -mmacosx-version-min=10.4 -Wall -fobjc-exceptions -Isrc
FRAMEWORKS = -framework Cocoa -framework ApplicationServices

SRC = src/main.m src/AppDelegate.m src/ScrollEventTap.m src/SettingsWindowController.m
LPROJS = ja.lproj en.lproj

# APP_BUNDLE はスペースを含むため、Make のターゲット/前提条件としては使えない
# （空白区切りで複数ターゲットに分割されてしまう）。実体はシェルコマンド内で
# 正しくクォートして扱い、Make 側の依存関係追跡にはスタンプファイルを使う。
STAMP = .build-stamp

.PHONY: all clean debug run

all: $(STAMP)

$(STAMP): $(SRC) Resources/Info.plist Resources/AppIcon.icns
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES)"
	$(CC) $(CFLAGS) -o "$(EXECUTABLE)" $(SRC) $(FRAMEWORKS)
	cp Resources/Info.plist "$(CONTENTS)/Info.plist"
	cp Resources/AppIcon.icns "$(RESOURCES)/AppIcon.icns"
	for d in $(LPROJS); do \
		mkdir -p "$(RESOURCES)/$$d"; \
		cp Resources/$$d/Localizable.strings "$(RESOURCES)/$$d/Localizable.strings"; \
	done
	touch $(STAMP)

# メニューバー常駐アプリを直接フォアグラウンドで実行し、NSLog を端末に出す（動作確認用）
debug: all
	"$(EXECUTABLE)"

run: all
	open "$(APP_BUNDLE)"

clean:
	rm -rf "$(APP_BUNDLE)" $(STAMP)
