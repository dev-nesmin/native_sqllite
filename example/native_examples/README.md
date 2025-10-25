# Native Code Examples

This directory contains example implementations showing how to use the generated database schemas from native Android (Kotlin) and iOS (Swift) code.

## Overview

These examples demonstrate the **synchronization pattern** where:

1. You define your database schema **once** in Dart using annotations
2. Run `build_runner` to generate Dart code
3. Copy the schema constants to native code
4. Use type-safe constants in both Dart and native code

This ensures your Flutter app and native background tasks use the **exact same schema** without duplication or manual synchronization errors.

## Files

### Android (Kotlin)

- **UserSchema.kt**: Schema constants mirroring the generated Dart schema
- **UserHelper.kt**: Type-safe CRUD helper class
- **LocationWorkerExample.kt**: Example WorkManager worker using the schema

### iOS (Swift)

- **UserSchema.swift**: Schema constants mirroring the generated Dart schema
- **UserHelper.swift**: Type-safe CRUD helper class
- **BackgroundTaskExample.swift**: Example Background Task using the schema

## How to Use

### 1. Generate Dart Code

From the example directory:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `lib/models/user.table.g.dart` and `lib/models/post.table.g.dart`.

### 2. Copy Schema Constants

Open the generated files (e.g., `user.table.g.dart`) and find the schema constants:

```dart
abstract class UserSchema {
  static const String tableName = 'users';
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email_address';
  // ...
}
```

Copy these constants to your native schema files:
- Android: `android/app/src/main/kotlin/.../generated/UserSchema.kt`
- iOS: `ios/Runner/Generated/UserSchema.swift`

### 3. Use in Native Code

#### Android WorkManager Example

```kotlin
class MyWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val userHelper = UserHelper("app_db")

        // Type-safe operations using constants
        val userId = userHelper.insert(User(
            name = "John Doe",
            email = "john@example.com",
            createdAt = System.currentTimeMillis()
        ))

        return Result.success()
    }
}
```

#### iOS Background Task Example

```swift
@available(iOS 13.0, *)
func handleBackgroundTask() async throws {
    let userHelper = UserHelper(databaseName: "app_db")

    // Type-safe operations using constants
    let userId = try userHelper.insert(User(
        name: "John Doe",
        email: "john@example.com",
        createdAt: Int(Date().timeIntervalSince1970 * 1000)
    ))
}
```

## Integration Steps

### For Android

1. Copy `UserSchema.kt` to `android/app/src/main/kotlin/your/package/generated/`
2. Copy `UserHelper.kt` to `android/app/src/main/kotlin/your/package/helpers/`
3. Update package names to match your project
4. Use in WorkManager, Services, or BroadcastReceivers

### For iOS

1. Copy `UserSchema.swift` to `ios/Runner/Generated/`
2. Copy `UserHelper.swift` to `ios/Runner/Helpers/`
3. Add files to your Xcode project
4. Use in Background Tasks, App Extensions, or other native code

## Benefits

✅ **Single Source of Truth**: Schema defined once in Dart annotations
✅ **Type Safety**: Compile-time checking in all languages
✅ **No Magic Strings**: IDE autocomplete for table/column names
✅ **Easy Refactoring**: Change schema in Dart, update native constants
✅ **Prevents Bugs**: No typos in SQL column names

## Workflow

When you change your Dart model:

1. Update annotations in Dart model
2. Run `dart run build_runner build`
3. Check the generated `.table.g.dart` file
4. Update native schema files (Kotlin/Swift)
5. Rebuild native code

## Testing

You can test the native helpers independently:

**Android:**
```kotlin
@Test
fun testUserHelper() {
    val userHelper = UserHelper("test_db")
    val userId = userHelper.insert(User(
        name = "Test User",
        email = "test@example.com",
        createdAt = System.currentTimeMillis()
    ))
    val user = userHelper.findById(userId)
    assertEquals("Test User", user?.name)
}
```

**iOS:**
```swift
func testUserHelper() throws {
    let userHelper = UserHelper(databaseName: "test_db")
    let userId = try userHelper.insert(User(
        name: "Test User",
        email: "test@example.com",
        createdAt: Int(Date().timeIntervalSince1970 * 1000)
    ))
    let user = try userHelper.findById(userId)
    XCTAssertEqual("Test User", user?.name)
}
```

## See Also

- [NATIVE_USAGE.md](../../NATIVE_USAGE.md) - Comprehensive guide
- [CODEGEN.md](../../CODEGEN.md) - Code generation documentation
- [example/lib/models/](../lib/models/) - Dart model definitions

## Questions?

The key principle: **Define schema in Dart, use type-safe constants everywhere.**

This pattern ensures Flutter and native code always stay in sync!
