#!/bin/bash

# Test script to verify build_runner integration with native code generation

set -e

echo "════════════════════════════════════════════════════════════════"
echo "  Testing Native SQLite Generator Integration"
echo "════════════════════════════════════════════════════════════════"
echo ""

cd example

echo "📦 Step 1: Getting dependencies..."
flutter pub get
echo ""

echo "🧹 Step 2: Cleaning previous builds..."
dart run build_runner clean
rm -rf .dart_tool/build
rm -rf android/app/src/main/kotlin/com/example/native_sqlite_example/generated
rm -rf ios/Runner/Generated
echo ""

echo "🔨 Step 3: Running build_runner build..."
echo "   This should automatically trigger native code generation!"
echo ""
dart run build_runner build --delete-conflicting-outputs
echo ""

echo "📊 Step 4: Verifying generated files..."
echo ""

# Check Dart generated files
if [ -f "lib/models/user.table.g.dart" ]; then
  echo "✅ Dart: lib/models/user.table.g.dart"
else
  echo "❌ FAILED: lib/models/user.table.g.dart not found"
  exit 1
fi

if [ -f "lib/models/post.table.g.dart" ]; then
  echo "✅ Dart: lib/models/post.table.g.dart"
else
  echo "❌ FAILED: lib/models/post.table.g.dart not found"
  exit 1
fi

# Check Android generated files
if [ -f "android/app/src/main/kotlin/com/example/native_sqlite_example/generated/UserSchema.kt" ]; then
  echo "✅ Android: UserSchema.kt"
else
  echo "❌ FAILED: Android UserSchema.kt not found"
  exit 1
fi

if [ -f "android/app/src/main/kotlin/com/example/native_sqlite_example/generated/PostSchema.kt" ]; then
  echo "✅ Android: PostSchema.kt"
else
  echo "❌ FAILED: Android PostSchema.kt not found"
  exit 1
fi

# Check iOS generated files
if [ -f "ios/Runner/Generated/UserSchema.swift" ]; then
  echo "✅ iOS: UserSchema.swift"
else
  echo "❌ FAILED: iOS UserSchema.swift not found"
  exit 1
fi

if [ -f "ios/Runner/Generated/PostSchema.swift" ]; then
  echo "✅ iOS: PostSchema.swift"
else
  echo "❌ FAILED: iOS PostSchema.swift not found"
  exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ✅ Integration Test PASSED!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "All files generated successfully:"
echo "  • Dart code (.table.g.dart)"
echo "  • Android code (Kotlin .kt)"
echo "  • iOS code (Swift .swift)"
echo ""
echo "The integration is working correctly!"
echo ""

# Test scenario 2: Direct native generator call
echo "════════════════════════════════════════════════════════════════"
echo "  Testing dart run native_sqlite_generator"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Modify a model file to make it newer than generated file
touch lib/models/user.dart

echo "🔧 Running native_sqlite_generator directly..."
echo "   This should detect stale files and auto-run build_runner!"
echo ""
dart run native_sqlite_generator
echo ""

echo "✅ Direct generator call test PASSED!"
echo ""
