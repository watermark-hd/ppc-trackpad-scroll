# PPC Trackpad Scroll - Makefile
# Mac OS X 10.4 Tiger / 10.5 Leopard (PowerPC) 向けビルド
# Xcode（xcodebuild）を使わず gcc + ld で直接ビルドする

APP_NAME   = PPCTrackpad
APP_BUNDLE = $(APP_NAME).app
CONTENTS   = $(APP_BUNDLE)/Contents
MACOS_DIR  = $(CONTENTS)/MacOS
RESOURCES  = $(CONTENTS)/Resources
EXECUTABLE = $(MACOS_DIR)/$(APP_NAME)

SDKROOT    = /Developer/SDKs/MacOSX10.4u.sdk
ARCH       = ppc
CC         = gcc
CFLAGS     = -arch $(ARCH) -isysroot $(SDKROOT) -mmacosx-version-min=10.4 -Wall -fobjc-exceptions -Isrc
FRAMEWORKS = -framework Cocoa -framework ApplicationServices

SRC = src/main.m src/AppDelegate.m src/ScrollEventTap.m src/SettingsWindowController.m

.PHONY: all clean debug run

all: $(APP_BUNDLE)

$(APP_BUNDLE): $(SRC) Resources/Info.plist
	mkdir -p $(MACOS_DIR) $(RESOURCES)
	$(CC) $(CFLAGS) -o $(EXECUTABLE) $(SRC) $(FRAMEWORKS)
	cp Resources/Info.plist $(CONTENTS)/Info.plist

# メニューバー常駐アプリを直接フォアグラウンドで実行し、NSLog を端末に出す（動作確認用）
debug: all
	$(EXECUTABLE)

run: all
	open $(APP_BUNDLE)

clean:
	rm -rf $(APP_BUNDLE)
