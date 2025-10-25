## Automated Native Code Generation

This guide shows how to **automatically generate** native Kotlin and Swift code from your Dart models - no manual copy-paste needed!

## Overview

Like [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons), native_sqlite can automatically generate native code files by reading a configuration file and running a simple command.

### What Gets Generated

✅ **Android (Kotlin)**:
- Schema constants (table/column names)
- Data classes matching your Dart models
- Helper classes with CRUD operations
- Files written directly to `android/app/src/main/kotlin/`

✅ **iOS (Swift)**:
- Schema constants (table/column names)
- Structs matching your Dart models
- Helper classes with CRUD operations
- Files written directly to `ios/Runner/Generated/`

## Quick Start

### 1. Create Configuration File

Create `native_sqlite_config.yaml` in your project root:

```yaml
native_sqlite:
  generate_native: true

  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/com/example/generated"
    package: "com.example.generated"
    generate_helpers: true

  ios:
    enabled: true
    output_path: "ios/Runner/Generated"
    generate_helpers: true

  models:
    - lib/models/**/*.dart

  database_name: "app_db"
  include_examples: true
```

### 2. Run the Generator

**Option A: Using the shell script (recommended)**
```bash
./scripts/generate_native.sh
```

**Option B: Using dart command directly**
```bash
# Generate Dart code first
dart run build_runner build --delete-conflicting-outputs

# Then generate native code
dart run native_sqlite_generator:generate_native
```

**Option C: Add to your Makefile**
```makefile
generate:
	dart run build_runner build --delete-conflicting-outputs
	dart run native_sqlite_generator:generate_native
```

### 3. Use Generated Code

The files are automatically created in the configured directories!

**Android**: Import and use immediately
```kotlin
import com.example.generated.UserSchema
import com.example.generated.UserHelper

val helper = UserHelper("app_db")
val userId = helper.insert(User(name = "John", email = "john@example.com"))
```

**iOS**: Add files to Xcode project, then use
```swift
import Foundation

let helper = UserHelper(databaseName: "app_db")
let userId = try helper.insert(User(name: "John", email: "john@example.com"))
```

## Configuration Reference

### Full Configuration Options

```yaml
native_sqlite:
  # Master switch - set to false to disable all generation
  generate_native: true

  # Android-specific settings
  android:
    # Enable/disable Android code generation
    enabled: true

    # Where to write Kotlin files (relative to project root)
    # Default: android/app/src/main/kotlin/generated
    output_path: "android/app/src/main/kotlin/com/example/myapp/database"

    # Package name for generated Kotlin files
    # Default: generated
    package: "com.example.myapp.database"

    # Generate helper classes with CRUD methods
    # If false, only generates schema constants
    # Default: true
    generate_helpers: true

  # iOS-specific settings
  ios:
    # Enable/disable iOS code generation
    enabled: true

    # Where to write Swift files (relative to project root)
    # Default: ios/Runner/Generated
    output_path: "ios/Runner/Database"

    # Generate helper classes with CRUD methods
    # If false, only generates schema constants
    # Default: true
    generate_helpers: true

  # Which Dart model files to process
  # Supports direct paths and glob patterns
  models:
    # Direct file paths
    - lib/models/user.dart
    - lib/models/post.dart
    - lib/models/comment.dart

    # Or use glob patterns
    # - lib/models/**/*.dart
    # - lib/database/models/*.dart

  # Database name used in generated code examples
  # Default: app_db
  database_name: "my_database"

  # Include usage examples in generated file comments
  # Default: true
  include_examples: true
```

### Alternative: Configuration in pubspec.yaml

Instead of a separate file, you can add the configuration to `pubspec.yaml`:

```yaml
name: my_app
# ... other pubspec.yaml content

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

## Generated Files

For a Dart model like this:

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

### Generated Android Files

**UserSchema.kt** (`android/app/src/main/kotlin/.../UserSchema.kt`)
```kotlin
package com.example.generated

object UserSchema {
    const val TABLE_NAME = "users"
    const val ID = "id"
    const val NAME = "name"
    const val EMAIL = "email_address"

    const val CREATE_TABLE_SQL = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email_address TEXT NOT NULL UNIQUE
        )
    """.trimIndent()
}
```

**UserHelper.kt** (`android/app/src/main/kotlin/.../UserHelper.kt`)
```kotlin
package com.example.generated

data class User(
    val id: Long? = null,
    val name: String,
    val email: String
)

class UserHelper(private val databaseName: String) {
    fun insert(entity: User): Long { /* ... */ }
    fun findById(id: Long): User? { /* ... */ }
    fun findAll(): List<User> { /* ... */ }
}
```

### Generated iOS Files

**UserSchema.swift** (`ios/Runner/Generated/UserSchema.swift`)
```swift
import Foundation

public enum UserSchema {
    public static let tableName = "users"
    public static let id = "id"
    public static let name = "name"
    public static let email = "email_address"

    public static let createTableSql = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email_address TEXT NOT NULL UNIQUE
        )
        """
}
```

**UserHelper.swift** (`ios/Runner/Generated/UserHelper.swift`)
```swift
import Foundation

public struct User {
    public let id: Int?
    public let name: String
    public let email: String
}

public class UserHelper {
    func insert(_ entity: User) throws -> Int { /* ... */ }
    func findById(_ id: Int) throws -> User? { /* ... */ }
    func findAll() throws -> [User] { /* ... */ }
}
```

## Workflow

### Development Workflow

1. **Define/modify your Dart model** with annotations
2. **Run the generator**:
   ```bash
   ./scripts/generate_native.sh
   ```
3. **Rebuild your app** (native code is automatically included)
4. **Use the generated code** in your native code

### When to Regenerate

Run the generator when you:
- ✅ Add a new `@Table` class
- ✅ Add/remove/rename fields
- ✅ Change column names (via `@Column(name: ...)`)
- ✅ Change table names (via `@Table(name: ...)`)
- ✅ Modify any annotation

### Git Integration

Add to your `.gitignore`:
```gitignore
# Don't commit generated files (regenerate on each machine)
android/app/src/main/kotlin/**/generated/
ios/Runner/Generated/

# Or commit them for team consistency
# (your choice - both approaches work)
```

Add to your CI/CD:
```yaml
# .github/workflows/build.yml
- name: Generate code
  run: |
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    dart run native_sqlite_generator:generate_native
```

## Integration with Build Tools

### Makefile

```makefile
.PHONY: generate clean build

generate:
	@echo "Generating code..."
	@dart run build_runner build --delete-conflicting-outputs
	@dart run native_sqlite_generator:generate_native

clean:
	@echo "Cleaning generated code..."
	@dart run build_runner clean
	@rm -rf android/app/src/main/kotlin/**/generated/
	@rm -rf ios/Runner/Generated/

build: generate
	@flutter build apk
	@flutter build ios
```

Usage:
```bash
make generate  # Generate code
make clean     # Clean generated code
make build     # Generate + build
```

### Package Scripts (pubspec.yaml)

```yaml
# Note: Flutter doesn't support scripts in pubspec.yaml natively
# Use Makefile or shell scripts instead
```

### VS Code Tasks

`.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Generate Native Code",
      "type": "shell",
      "command": "dart run build_runner build --delete-conflicting-outputs && dart run native_sqlite_generator:generate_native",
      "group": "build",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

## Troubleshooting

### "No configuration found"

**Problem**: Generator says it can't find configuration.

**Solution**:
- Create `native_sqlite_config.yaml` in project root, OR
- Add `native_sqlite:` section to `pubspec.yaml`
- See `native_sqlite_config.example.yaml` for reference

### "No model files found"

**Problem**: Generator can't find your Dart models.

**Solution**:
- Check the `models:` paths in your config
- Use absolute paths from project root
- Glob patterns need quotes: `"lib/models/**/*.dart"`
- Make sure files have `@Table` annotations

### "Directory not found" for Android

**Problem**: Android output path doesn't exist.

**Solution**:
- Generator creates the directory automatically
- Make sure path is relative to project root
- Check for typos in `output_path`

### "Swift files not in Xcode"

**Problem**: Generated Swift files aren't recognized.

**Solution**:
- In Xcode: Right-click Runner folder
- Select "Add Files to 'Runner'"
- Navigate to `ios/Runner/Generated`
- Select all `.swift` files
- Make sure "Copy items if needed" is UNCHECKED
- Click "Add"

### "Package name mismatch" (Android)

**Problem**: Kotlin package doesn't match your project.

**Solution**:
- Update `package:` in config to match your app's package
- Example: `com.yourcompany.yourapp.generated`
- Rebuild Android app after changing

## Comparison with Manual Approach

| Aspect | Manual Copy-Paste | Automated Generation |
|--------|-------------------|---------------------|
| **Setup** | None | One-time config file |
| **Speed** | Slow (manual) | Fast (automated) |
| **Errors** | High risk of typos | Zero typos |
| **Updates** | Manual sync needed | Auto-synced |
| **Team collaboration** | Inconsistent | Consistent |
| **Best for** | Simple projects | Production apps |

## Best Practices

1. **Version control**: Decide whether to commit generated files
   - ✅ Commit: Easier for team, consistent
   - ✅ Don't commit: Cleaner git history, always fresh

2. **CI/CD**: Always regenerate in CI pipeline

3. **Pre-commit hook**: Consider auto-generating before commits
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   ./scripts/generate_native.sh
   git add android/app/src/main/kotlin/**/generated/
   git add ios/Runner/Generated/
   ```

4. **Regular updates**: Run generator whenever you modify models

5. **Code reviews**: Review generated code changes when schema changes

## Summary

**Automated generation**:
- ✅ Runs with one command
- ✅ Generates Kotlin and Swift automatically
- ✅ Writes files to native directories
- ✅ No manual copy-paste needed
- ✅ Perfect synchronization guaranteed
- ✅ Like flutter_launcher_icons but for database code

**Simple workflow**:
1. Configure once in `native_sqlite_config.yaml`
2. Run `./scripts/generate_native.sh` when models change
3. Use generated code immediately

It's that easy! 🎉
