#!/bin/bash
set -e

APP_NAME="TahoeMenuBar"
BUILD_DIR="$(pwd)/build"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "=== Building ${APP_NAME} for macOS ==="

rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile Swift sources with optimizations (-O)
swiftc -O \
  -target arm64-apple-macosx14.0 \
  -import-objc-header TahoeMenuBar/PrivateHeaders/TahoeMenuBar-Bridging-Header.h \
  TahoeMenuBar/main.swift \
  TahoeMenuBar/AppDelegate.swift \
  TahoeMenuBar/BackdropLayer/BackdropLayerView.swift \
  TahoeMenuBar/MenuBarWindowController.swift \
  TahoeMenuBar/NSScreen+Extension.swift \
  TahoeMenuBar/OverlayEffect.swift \
  TahoeMenuBar/ShadowLayerView.swift \
  TahoeMenuBar/ShadowWindowController.swift \
  TahoeMenuBar/Wallpaper/WallpaperManager.swift \
  TahoeMenuBar/LaunchAtLogin.swift \
  -o "${MACOS_DIR}/${APP_NAME}"

# Copy bundle metadata and icon
cp TahoeMenuBar/Info.plist "${CONTENTS_DIR}/Info.plist"
if [ -f TahoeMenuBar/AppIcon.icns ]; then
  cp TahoeMenuBar/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

# Ad-hoc code signing
codesign --force --deep --sign - --entitlements TahoeMenuBar/TahoeMenuBar.entitlements "${BUNDLE_DIR}"
xattr -cr "${BUNDLE_DIR}"

echo "=== Build complete: ${BUNDLE_DIR} ==="
