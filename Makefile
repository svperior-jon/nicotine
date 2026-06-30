.PHONY: build app run package signed-package notarized-package clean

APP_NAME := Nicotine
VERSION := 1.0.2
CONFIGURATION := release
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
BINARY := .build/$(CONFIGURATION)/$(APP_NAME)

build:
	swift build -c $(CONFIGURATION)

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS"
	mkdir -p "$(APP_DIR)/Contents/Resources"
	cp "Resources/Info.plist" "$(APP_DIR)/Contents/Info.plist"
	cp "Resources/Nicotine.icns" "$(APP_DIR)/Contents/Resources/Nicotine.icns"
	cp "$(BINARY)" "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"
	chmod +x "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"

run: app
	open "$(APP_DIR)"

package: app
	./scripts/package-release.sh "$(VERSION)"

signed-package: app
	SIGN_IDENTITY="$(SIGN_IDENTITY)" ./scripts/package-release.sh "$(VERSION)"

notarized-package: app
	SIGN_IDENTITY="$(SIGN_IDENTITY)" NOTARY_PROFILE="$(NOTARY_PROFILE)" ./scripts/package-release.sh "$(VERSION)"

clean:
	rm -rf .build "$(BUILD_DIR)" dist
