#!/bin/bash

# Native SQLite Code Generator
# Generates native Kotlin and Swift code from Dart models

set -e

echo "🔧 Native SQLite Code Generator"
echo "================================"
echo ""

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found."
    echo "   Please run this script from your Flutter project root."
    exit 1
fi

# Check if configuration exists
if [ ! -f "native_sqlite_config.yaml" ] && ! grep -q "native_sqlite:" pubspec.yaml; then
    echo "⚠️  No configuration found."
    echo "   Please create native_sqlite_config.yaml or add native_sqlite section to pubspec.yaml"
    echo "   See native_sqlite_config.example.yaml for reference."
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get > /dev/null 2>&1

echo "🏗️  Generating Dart code..."
dart run build_runner build --delete-conflicting-outputs

echo "🔧 Generating native code..."
dart run native_sqlite_generator:generate_native "$@"

echo ""
echo "✅ Code generation complete!"
echo ""
echo "📱 Next steps:"
echo "   • Android: Rebuild your app to include the generated Kotlin files"
echo "   • iOS: Add generated Swift files to your Xcode project"
echo "     (Right-click Runner folder → Add Files to \"Runner\")"
echo ""
