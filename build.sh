#!/bin/bash

# RouteX Build Script
# This script builds the RouteX application using xcodebuild

set -e

echo "Building RouteX..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Please install Xcode Command Line Tools."
    exit 1
fi

# Create a consistent build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Build the project with a specific derived data path
xcodebuild -project RouteX.xcodeproj \
           -scheme RouteX \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR/DerivedData" \
           build

# Define the app path
APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/RouteX.app"

echo "Build completed successfully!"
echo "The app is located in: $APP_PATH"

# Optional: Open the app
read -p "Would you like to open the app now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$APP_PATH"
fi 
