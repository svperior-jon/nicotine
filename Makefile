.PHONY: build app run clean

APP_NAME := Nicotine
VERSION := 1.0.0
CONFIGURATION := release
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
BINARY := .build/$(CONFIGURATION)/$(APP_NAME)

build:
	swift build -c $(CONFIGURATION)

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS"
	cp "Resources/Info.plist" "$(APP_DIR)/Contents/Info.plist"
	cp "$(BINARY)" "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"
	chmod +x "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"

run: app
	open "$(APP_DIR)"

package: app
	./scripts/package-release.sh "$(VERSION)"

clean:
	rm -rf .build "$(BUILD_DIR)" dist
