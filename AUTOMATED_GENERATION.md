# Automated Native Code Generation

Generate native Kotlin and Swift code automatically - **even simpler than flutter_launcher_icons**!

## Quick Start

### Configuration

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.4.13
  native_sqlite_generator:
    path: ../native_sqlite_generator

native_sqlite:
  generate_native: true

  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/com/example/generated"
    package: "com.example.generated"

  ios:
    enabled: true
    output_path: "ios/Runner/Generated"

  models:
    - lib/models/**/*.dart
```

### Generate Code

**Option 1: One command does everything (Recommended)**

```bash
dart run build_runner build --delete-conflicting-outputs
```

This automatically:
1. ✅ Generates Dart code (`.table.g.dart`)
2. ✅ **Automatically triggers native code generation via post-build hook**
3. ✅ Generates Kotlin files in `android/.../generated/`
4. ✅ Generates Swift files in `ios/Runner/Generated/`

**Everything in ONE command!**

**Option 2: Run native generator separately**

```bash
dart run native_sqlite_generator
```

This:
1. ✅ **Automatically checks if build_runner needs to run first**
2. ✅ Runs `build_runner build` if `.table.g.dart` files are missing or stale
3. ✅ Generates native code

**Smart! It ensures Dart code is generated before creating native files.**

## How It Works

### Automatic Integration with build_runner

The native code generator is integrated as a **post-process builder** that runs automatically after build_runner completes:

```bash
dart run build_runner build
```

**What happens internally:**
1. build_runner generates `.table.g.dart` files from your models
2. Post-build hook detects the generated files
3. Native code generator runs automatically (only once per build session)
4. Kotlin and Swift files are created

**Works with watch mode too:**
```bash
dart run build_runner watch
```
- Watches for file changes
- Regenerates Dart code on save
- Automatically triggers native code generation

### Smart Dependency Checking

When you run the generator directly:

```bash
dart run native_sqlite_generator
```

It intelligently checks:
- ✅ Do `.table.g.dart` files exist for all models?
- ✅ Are source files newer than generated files?

If any check fails, it **automatically runs build_runner first**, then generates native code.

**You can't forget to run build_runner!**

## Complete Workflow

### Development

```bash
# Modify your Dart models
# Then run ONE command:

dart run build_runner build

# Done! Everything is generated:
# ✓ Dart repositories
# ✓ Kotlin schemas and helpers
# ✓ Swift schemas and helpers
```

### Watch Mode (for continuous development)

```bash
dart run build_runner watch
```

This watches for changes and regenerates:
- ✅ Dart code on every save
- ✅ Native code automatically after Dart generation

### Alternative: Direct Native Generation

```bash
# This checks dependencies automatically
dart run native_sqlite_generator

# If build_runner hasn't run, it runs it first
# Then generates native code
```

## What Gets Generated

For this Dart model:

```dart
@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(name: 'email_address', unique: true)
  final String email;
}
```

**One command generates**:

✅ **Dart** (`lib/models/user.table.g.dart`):
```dart
abstract class UserSchema { ... }
class UserRepository { ... }
```

✅ **Kotlin** (`android/.../UserSchema.kt`, `UserHelper.kt`):
```kotlin
object UserSchema { ... }
data class User { ... }
class UserHelper { ... }
```

✅ **Swift** (`ios/.../UserSchema.swift`, `UserHelper.swift`):
```swift
enum UserSchema { ... }
struct User { ... }
class UserHelper { ... }
```

## Configuration Options

```yaml
native_sqlite:
  # Enable/disable (default: false)
  generate_native: true

  # Android
  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/com/example/generated"
    package: "com.example.generated"
    generate_helpers: true  # false = only schemas

  # iOS
  ios:
    enabled: true
    output_path: "ios/Runner/Generated"
    generate_helpers: true  # false = only schemas

  # Which models to process
  models:
    - lib/models/user.dart
    - lib/models/post.dart
    # Or use glob:
    - lib/models/**/*.dart

  # Database name in examples
  database_name: "app_db"

  # Include usage examples
  include_examples: true
```

## CI/CD Integration

```yaml
# .github/workflows/build.yml
- name: Generate code
  run: |
    flutter pub get
    # One command does everything!
    dart run build_runner build --delete-conflicting-outputs

# That's it! Native code is auto-generated
```

## iOS Setup

After first generation, add files to Xcode **once**:

1. Right-click **Runner** folder
2. **Add Files to "Runner"...**
3. Select `ios/Runner/Generated/`
4. ✅ Uncheck "Copy items if needed"
5. Click **Add**

After that, files update automatically when you regenerate!

## Comparison with flutter_launcher_icons

| Feature | flutter_launcher_icons | native_sqlite_generator |
|---------|----------------------|-------------------------|
| Config in pubspec | ✅ | ✅ |
| One command | `dart run flutter_launcher_icons` | `dart run build_runner build` |
| Auto-runs dependencies | - | ✅ Runs build_runner if needed |
| Post-build integration | - | ✅ Auto-runs after build_runner |
| CI/CD friendly | ✅ | ✅ |

**Even better than flutter_launcher_icons** - it integrates with build_runner and checks dependencies!

## Examples

### Simple Usage

```bash
# 1. Configure in pubspec.yaml
# 2. Run build
dart run build_runner build

# Done! Everything generated.
```

### With Watch Mode

```bash
# Start watch mode
dart run build_runner watch

# Edit models, save
# → Dart code regenerates
# → Native code regenerates
# All automatic!
```

### Clean and Rebuild

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

**"No configuration found"**
- Add `native_sqlite:` to `pubspec.yaml`

**"No model files found"**
- Check `models:` paths in config
- Ensure files have `@Table` annotations

**Native code not generating**
- Make sure `generate_native: true`
- Check `enabled: true` for android/ios

**Build runner not auto-running**
- Run `dart run native_sqlite_generator` directly
- It will check and run build_runner if needed

**Native code not generating with build_runner**
- Ensure `native_sqlite_generator` is in `dev_dependencies`
- Check that `generate_native: true` in config
- Try running `dart run build_runner clean` then rebuild
- The post-build hook triggers on `.table.g.dart` files

**Watch mode issues**
- The generator runs once per build session automatically
- If files aren't updating, check the console output for errors
- Try stopping and restarting watch mode

## Testing the Integration

A test script is provided to verify everything works correctly:

```bash
./test_integration.sh
```

This script:
1. Cleans all generated files
2. Runs `dart run build_runner build`
3. Verifies Dart, Kotlin, and Swift files were generated
4. Tests the direct generator call with dependency checking

**Manual testing:**

```bash
# Clean everything
dart run build_runner clean
rm -rf android/app/src/main/kotlin/*/generated
rm -rf ios/Runner/Generated

# Test build_runner integration
dart run build_runner build

# Check for generated files:
# - lib/models/*.table.g.dart
# - android/app/src/main/kotlin/.../generated/*.kt
# - ios/Runner/Generated/*.swift

# Test direct generator with auto-detection
touch lib/models/user.dart  # Make source file newer
dart run native_sqlite_generator  # Should auto-run build_runner
```

## Summary

**Simplest workflow ever**:

```bash
# ONE command does EVERYTHING
dart run build_runner build
```

Generates:
- ✅ Dart repositories
- ✅ Kotlin schemas and helpers
- ✅ Swift schemas and helpers

**Or run native generator separately** - it's smart enough to run build_runner first if needed:

```bash
dart run native_sqlite_generator
```

**Better than flutter_launcher_icons** because:
- Integrates with build_runner
- Auto-checks dependencies
- One command for everything

🎉 **Zero manual work, maximum automation!**
