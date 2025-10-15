#!/bin/bash
set -e

echo "🚀 Starting Flutter web build process..."

# Check if Flutter is already installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
    export PATH="$PATH:`pwd`/flutter/bin"
else
    echo "✅ Flutter already installed"
fi

# Check Flutter version
echo "🔍 Flutter version:"
flutter --version

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

# Clean and get dependencies
echo "📋 Getting dependencies..."
flutter clean
flutter pub get

# Build web
echo "🔨 Building web application..."
flutter build web --release

echo "✅ Flutter web build completed successfully!"

# List build directory contents
echo "📂 Build directory contents:"
ls -la build/web/