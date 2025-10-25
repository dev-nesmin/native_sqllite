# Automated Native Code Generation

Generate native Kotlin and Swift code automatically from your Dart models - just like **flutter_launcher_icons**!

## Quick Start

### 1. Add Configuration

Add to your `pubspec.yaml`:

```yaml
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

### 2. Run Generator

```bash
dart run native_sqlite_generator
```

That's it! Files are automatically generated.

## What Gets Generated

For each `@Table` annotated Dart class:

✅ **Android (Kotlin)**:
- Schema constants → `android/.../UserSchema.kt`
- Helper class → `android/.../UserHelper.kt`

✅ **iOS (Swift)**:
- Schema constants → `ios/.../UserSchema.swift`
- Helper class → `ios/.../UserHelper.swift`

## Full Configuration

```yaml
native_sqlite:
  # Enable/disable generation
  generate_native: true

  # Android
  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/com/example/generated"
    package: "com.example.generated"
    generate_helpers: true  # false = only schema constants

  # iOS
  ios:
    enabled: true
    output_path: "ios/Runner/Generated"
    generate_helpers: true  # false = only schema constants

  # Which models to process
  models:
    - lib/models/user.dart
    - lib/models/post.dart
    # Or use glob:
    - lib/models/**/*.dart

  # Database name for examples
  database_name: "app_db"

  # Include usage examples in comments
  include_examples: true
```

## Example

**Dart model:**
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

**Run:**
```bash
dart run native_sqlite_generator
```

**Generated Android (`UserSchema.kt`):**
```kotlin
package com.example.generated

object UserSchema {
    const val TABLE_NAME = "users"
    const val ID = "id"
    const val NAME = "name"
    const val EMAIL = "email_address"
}

class UserHelper(private val databaseName: String) {
    fun insert(entity: User): Long { ... }
    fun findById(id: Long): User? { ... }
    fun findAll(): List<User> { ... }
}
```

**Generated iOS (`UserSchema.swift`):**
```swift
public enum UserSchema {
    public static let tableName = "users"
    public static let id = "id"
    public static let name = "name"
    public static let email = "email_address"
}

public class UserHelper {
    func insert(_ entity: User) throws -> Int { ... }
    func findById(_ id: Int) throws -> User? { ... }
    func findAll() throws -> [User] { ... }
}
```

## Workflow

1. **Define** Dart models with annotations
2. **Run** `dart run native_sqlite_generator`
3. **Use** generated code in Android/iOS

When you change models:
```bash
dart run build_runner build       # Regenerate Dart code
dart run native_sqlite_generator  # Regenerate native code
```

## CI/CD

Add to your pipeline:

```yaml
# .github/workflows/build.yml
- name: Generate code
  run: |
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    dart run native_sqlite_generator
```

## iOS Setup

After first generation, add files to Xcode:
1. Right-click **Runner** folder
2. **Add Files to "Runner"...**
3. Select `ios/Runner/Generated/`
4. Uncheck "Copy items if needed"
5. Click **Add**

After that, files update automatically when you regenerate.

## Alternative: Separate Config File

Instead of `pubspec.yaml`, create `native_sqlite_config.yaml`:

```yaml
native_sqlite:
  generate_native: true
  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/generated"
    package: "generated"
  ios:
    enabled: true
    output_path: "ios/Runner/Generated"
  models:
    - lib/models/**/*.dart
```

The generator checks both files.

## Troubleshooting

**"No configuration found"**
- Add `native_sqlite:` section to `pubspec.yaml` or create `native_sqlite_config.yaml`

**"No model files found"**
- Check `models:` paths in config
- Ensure files have `@Table` annotations

**Swift files not in Xcode**
- Add them manually once (see iOS Setup above)
- Subsequent runs update files automatically

## Summary

Just like `flutter_launcher_icons`:

```bash
# 1. Configure in pubspec.yaml
# 2. Run command
dart run native_sqlite_generator

# Done!
```

No scripts, no complexity - just one command! 🎉
