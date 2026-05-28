#!/bin/bash

# Build and bundle Screenshot Sweeper as a proper macOS app

set -e

# Configuration
APP_NAME="Screenshot Sweeper"
BUNDLE_ID="com.screenshotsweeper.app"
BUILD_CONFIG="${1:-debug}"
ARCH="$(uname -m)"

echo "Building Screenshot Sweeper..."

# Clean previous builds
rm -rf "build/${APP_NAME}.app"
mkdir -p build

# Build with Swift Package Manager
if [ "$BUILD_CONFIG" = "release" ]; then
    swift build -c release
    EXECUTABLE_PATH=".build/${ARCH}-apple-macosx/release/ScreenshotSweeper"
else
    swift build
    EXECUTABLE_PATH=".build/${ARCH}-apple-macosx/debug/ScreenshotSweeper"
fi

# Create app bundle structure
APP_BUNDLE="build/${APP_NAME}.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "${EXECUTABLE_PATH}" "${APP_BUNDLE}/Contents/MacOS/ScreenshotSweeper"

# Copy Info.plist
cp "Sources/ScreenshotSweeper/Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Create PkgInfo file
echo "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Sign the app if code signing identity is available
DEVELOPER_ID_IDENTITY="$(security find-identity -p codesigning -v | awk -F '\"' '/Developer ID Application/ { print $2; exit }')"
if [ -n "${DEVELOPER_ID_IDENTITY}" ]; then
    echo "Code signing the app with ${DEVELOPER_ID_IDENTITY}..."
    codesign --force --deep --sign "${DEVELOPER_ID_IDENTITY}" "${APP_BUNDLE}"
else
    echo "No code signing identity found, signing with ad-hoc signature..."
    codesign --force --deep --sign - "${APP_BUNDLE}"
fi

echo "✅ App bundle created at: ${APP_BUNDLE}"
echo ""
echo "To run the app:"
echo "  open \"${APP_BUNDLE}\""
echo ""
echo "To install to Applications:"
echo "  cp -r \"${APP_BUNDLE}\" /Applications/"
