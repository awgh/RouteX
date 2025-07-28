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

# Build the project using Swift Package Manager for both architectures
echo "Building universal binary for Apple Silicon and Intel Macs..."

# Build for ARM64 (Apple Silicon)
echo "Building for ARM64 (Apple Silicon)..."
swift build -c release --triple arm64-apple-macosx12.0
ARM64_EXECUTABLE=".build/arm64-apple-macosx/release/RouteX"

# Build for x86_64 (Intel)
echo "Building for x86_64 (Intel)..."
swift build -c release --triple x86_64-apple-macosx12.0
X86_64_EXECUTABLE=".build/x86_64-apple-macosx/release/RouteX"

# Create universal binary
echo "Creating universal binary..."
UNIVERSAL_EXECUTABLE=".build/release/RouteX"
mkdir -p "$(dirname "$UNIVERSAL_EXECUTABLE")"

# Use lipo to create universal binary
if command -v lipo &> /dev/null; then
    lipo -create "$ARM64_EXECUTABLE" "$X86_64_EXECUTABLE" -output "$UNIVERSAL_EXECUTABLE"
    echo "Universal binary created successfully"
else
    echo "Warning: lipo not found, using ARM64 binary only"
    cp "$ARM64_EXECUTABLE" "$UNIVERSAL_EXECUTABLE"
fi

# Define the executable path
EXECUTABLE_PATH="$UNIVERSAL_EXECUTABLE"

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

# Create distribution zip file
echo "Creating distribution package..."
DIST_DIR="$BUILD_DIR/dist"
mkdir -p "$DIST_DIR"

# Copy the app bundle to the distribution directory
cp -r "$APP_PATH" "$DIST_DIR/"

# Create zip file from the distribution directory
cd "$DIST_DIR"
zip -r "../RouteX.zip" "RouteX.app"
cd - > /dev/null

echo "Distribution package created: $BUILD_DIR/RouteX.zip"
echo "This zip file will extract to a folder containing RouteX.app"

# Optional: Open the app
#read -p "Would you like to open the app now? (y/n): " -n 1 -r
#echo
#if [[ $REPLY =~ ^[Yy]$ ]]; then
#    open "$APP_PATH"
#fi 
