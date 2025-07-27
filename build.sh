#!/bin/bash

# RouteX Build Script
# This script builds the RouteX application using Swift Package Manager

set -e

echo "Building RouteX..."

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "Error: Swift not found. Please install Swift."
    exit 1
fi

# Show Swift version
echo "Using Swift version:"
swift --version

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Build the project using Swift Package Manager
echo "Building with Swift Package Manager..."
swift build -c release

# Define the executable path
EXECUTABLE_PATH=".build/release/RouteX"

# Create app bundle structure
APP_PATH="$BUILD_DIR/RouteX.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

echo "Creating app bundle..."

# Create directory structure
mkdir -p "$MACOS_PATH"
mkdir -p "$RESOURCES_PATH"

# Copy executable
cp "$EXECUTABLE_PATH" "$MACOS_PATH/RouteX"

# Copy Info.plist
cp "RouteX/Info.plist" "$CONTENTS_PATH/"

# Copy assets
cp -r "RouteX/Assets.xcassets" "$RESOURCES_PATH/"

# Create .icns file from app icons
echo "Creating app icon..."
ICONSET_PATH="$RESOURCES_PATH/RouteX.iconset"
mkdir -p "$ICONSET_PATH"

# Copy icons from Assets.xcassets to iconset with proper naming
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_16x16.png" "$ICONSET_PATH/icon_16x16.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png" "$ICONSET_PATH/icon_16x16@2x.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_PATH/icon_32x32.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png" "$ICONSET_PATH/icon_32x32@2x.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" "$ICONSET_PATH/icon_128x128.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" "$ICONSET_PATH/icon_128x128@2x.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_PATH/icon_256x256.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png" "$ICONSET_PATH/icon_256x256@2x.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_PATH/icon_512x512.png"
cp "$RESOURCES_PATH/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" "$ICONSET_PATH/icon_512x512@2x.png"

# Create .icns file using iconutil
if command -v iconutil &> /dev/null; then
    iconutil -c icns "$ICONSET_PATH" -o "$RESOURCES_PATH/AppIcon.icns"
    echo "Created AppIcon.icns successfully"
else
    echo "Warning: iconutil not found, skipping .icns creation"
fi

# Clean up iconset directory
rm -rf "$ICONSET_PATH"

# Make executable
chmod +x "$MACOS_PATH/RouteX"

echo "Build completed successfully!"
echo "The app is located in: $APP_PATH"

# Optional: Open the app
read -p "Would you like to open the app now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$APP_PATH"
fi 
