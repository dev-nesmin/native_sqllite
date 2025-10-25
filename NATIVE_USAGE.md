# Using Generated Schemas from Native Code

This guide shows how to use the generated table schemas from native Android (Kotlin) and iOS (Swift) code, ensuring your Flutter schema and native code stay in perfect sync.

## The Problem

When you define a schema using code generation in Dart:

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

The native side needs to know:
- Table name: `'users'`
- Column names: `'id'`, `'name'`, `'email_address'`
- SQL types and constraints

**Without synchronization**, you might accidentally use wrong column names in native code, causing runtime errors.

## The Solution

The code generator creates schema constants in the generated Dart file that you can easily reference or copy to native code.

### Generated Dart Code

```dart
// user.table.g.dart
abstract class UserSchema {
  static const String tableName = 'users';
  static const String createTableSql = '''...''';

  // Column name constants
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email_address';
}
```

## Approach 1: Use String Constants (Recommended)

### Android (Kotlin)

Create a constants file that mirrors the Dart schema:

```kotlin
// android/app/src/main/kotlin/your/package/generated/UserSchema.kt
package your.package.generated

/**
 * Schema constants for User table.
 * IMPORTANT: Keep in sync with lib/models/user.dart
 * Generated table name and columns from Dart @Table annotation.
 */
object UserSchema {
    // Generated from: @Table(name: 'users')
    const val TABLE_NAME = "users"

    // Generated columns from @Column annotations
    const val ID = "id"                    // from: @PrimaryKey final int? id
    const val NAME = "name"                // from: @Column final String name
    const val EMAIL = "email_address"      // from: @Column(name: 'email_address') final String email

    // CREATE TABLE SQL (copy from user.table.g.dart)
    const val CREATE_TABLE_SQL = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email_address TEXT NOT NULL UNIQUE
        )
    """.trimIndent()
}
```

**Usage in Kotlin:**

```kotlin
import your.package.generated.UserSchema

class LocationWorker : Worker() {
    override fun doWork(): Result {
        // Initialize database
        if (!NativeSqliteManager.isDatabaseOpen("app_db")) {
            NativeSqliteManager.openDatabase(DatabaseConfig(
                name = "app_db",
                version = 1,
                onCreate = listOf(UserSchema.CREATE_TABLE_SQL)
            ))
        }

        // Insert using constants - no typos possible!
        val rowId = NativeSqliteManager.insert(
            "app_db",
            UserSchema.TABLE_NAME,  // ✅ Type-safe
            mapOf(
                UserSchema.NAME to "John Doe",
                UserSchema.EMAIL to "john@example.com"
            )
        )

        // Query using constants
        val result = NativeSqliteManager.query(
            "app_db",
            "SELECT * FROM ${UserSchema.TABLE_NAME} WHERE ${UserSchema.EMAIL} = ?",
            listOf("john@example.com")
        )

        return Result.success()
    }
}
```

### iOS (Swift)

Create a constants file that mirrors the Dart schema:

```swift
// ios/Runner/Generated/UserSchema.swift
import Foundation

/**
 * Schema constants for User table.
 * IMPORTANT: Keep in sync with lib/models/user.dart
 * Generated table name and columns from Dart @Table annotation.
 */
public enum UserSchema {
    // Generated from: @Table(name: 'users')
    public static let tableName = "users"

    // Generated columns from @Column annotations
    public static let id = "id"                     // from: @PrimaryKey final int? id
    public static let name = "name"                 // from: @Column final String name
    public static let email = "email_address"       // from: @Column(name: 'email_address') final String email

    // CREATE TABLE SQL (copy from user.table.g.dart)
    public static let createTableSql = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email_address TEXT NOT NULL UNIQUE
        )
    """
}
```

**Usage in Swift:**

```swift
import Foundation

class LocationBackgroundTask {
    func captureLocation() {
        let manager = NativeSqliteManager.shared

        do {
            // Initialize database
            if !manager.isDatabaseOpen(name: "app_db") {
                try manager.openDatabase(config: DatabaseConfig(
                    name: "app_db",
                    version: 1,
                    onCreate: [UserSchema.createTableSql]
                ))
            }

            // Insert using constants - no typos possible!
            let rowId = try manager.insert(
                name: "app_db",
                table: UserSchema.tableName,  // ✅ Type-safe
                values: [
                    UserSchema.name: "John Doe",
                    UserSchema.email: "john@example.com"
                ]
            )

            // Query using constants
            let result = try manager.query(
                name: "app_db",
                sql: "SELECT * FROM \(UserSchema.tableName) WHERE \(UserSchema.email) = ?",
                arguments: ["john@example.com"]
            )

            print("Found \((result["rows"] as? [[Any?]])?.count ?? 0) users")
        } catch {
            print("Database error: \(error)")
        }
    }
}
```

## Approach 2: Create Native Helper Classes

For complex models, create full helper classes with CRUD operations:

### Android Helper Class

```kotlin
// android/app/src/main/kotlin/your/package/helpers/UserHelper.kt
package your.package.helpers

import android.content.ContentValues
import your.package.generated.UserSchema
import dev.nesmin.native_sqlite.NativeSqliteManager

data class User(
    val id: Long? = null,
    val name: String,
    val email: String
)

class UserHelper(private val databaseName: String) {

    fun insert(user: User): Long {
        val values = ContentValues().apply {
            put(UserSchema.NAME, user.name)
            put(UserSchema.EMAIL, user.email)
        }
        return NativeSqliteManager.insert(
            databaseName,
            UserSchema.TABLE_NAME,
            values
        )
    }

    fun findById(id: Long): User? {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT * FROM ${UserSchema.TABLE_NAME} WHERE ${UserSchema.ID} = ? LIMIT 1",
            listOf(id)
        )

        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null

        val columns = result["columns"] as List<String>
        return fromRow(columns, rows[0])
    }

    fun findAll(): List<User> {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT * FROM ${UserSchema.TABLE_NAME}"
        )

        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()
        val columns = result["columns"] as List<String>

        return rows.map { fromRow(columns, it) }
    }

    fun update(user: User): Int {
        require(user.id != null) { "User ID cannot be null for update" }

        val values = ContentValues().apply {
            put(UserSchema.NAME, user.name)
            put(UserSchema.EMAIL, user.email)
        }

        return NativeSqliteManager.update(
            databaseName,
            UserSchema.TABLE_NAME,
            values,
            where = "${UserSchema.ID} = ?",
            whereArgs = listOf(user.id)
        )
    }

    fun delete(id: Long): Int {
        return NativeSqliteManager.delete(
            databaseName,
            UserSchema.TABLE_NAME,
            where = "${UserSchema.ID} = ?",
            whereArgs = listOf(id)
        )
    }

    private fun fromRow(columns: List<String>, row: List<Any?>): User {
        val columnMap = columns.withIndex().associate { it.value to it.index }

        return User(
            id = row[columnMap[UserSchema.ID]!!] as Long,
            name = row[columnMap[UserSchema.NAME]!!] as String,
            email = row[columnMap[UserSchema.EMAIL]!!] as String
        )
    }
}
```

**Usage:**

```kotlin
val userHelper = UserHelper("app_db")

// Insert
val userId = userHelper.insert(User(
    name = "John Doe",
    email = "john@example.com"
))

// Find
val user = userHelper.findById(userId)

// Update
user?.let {
    userHelper.update(it.copy(name = "Jane Doe"))
}

// Delete
userHelper.delete(userId)
```

### iOS Helper Class

```swift
// ios/Runner/Helpers/UserHelper.swift
import Foundation

struct User {
    let id: Int?
    let name: String
    let email: String
}

class UserHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    init(databaseName: String) {
        self.databaseName = databaseName
    }

    func insert(_ user: User) throws -> Int {
        let values: [String: Any] = [
            UserSchema.name: user.name,
            UserSchema.email: user.email
        ]

        return try manager.insert(
            name: databaseName,
            table: UserSchema.tableName,
            values: values
        )
    }

    func findById(_ id: Int) throws -> User? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(UserSchema.tableName) WHERE \(UserSchema.id) = ? LIMIT 1",
            arguments: [id]
        )

        guard let rows = result["rows"] as? [[Any?]], !rows.isEmpty,
              let columns = result["columns"] as? [String] else {
            return nil
        }

        return fromRow(columns: columns, row: rows[0])
    }

    func findAll() throws -> [User] {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(UserSchema.tableName)"
        )

        guard let rows = result["rows"] as? [[Any?]],
              let columns = result["columns"] as? [String] else {
            return []
        }

        return rows.map { fromRow(columns: columns, row: $0) }
    }

    func update(_ user: User) throws -> Int {
        guard let id = user.id else {
            throw NSError(domain: "UserHelper", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "User ID cannot be nil for update"
            ])
        }

        let values: [String: Any] = [
            UserSchema.name: user.name,
            UserSchema.email: user.email
        ]

        return try manager.update(
            name: databaseName,
            table: UserSchema.tableName,
            values: values,
            whereClause: "\(UserSchema.id) = ?",
            whereArgs: [id]
        )
    }

    func delete(_ id: Int) throws -> Int {
        return try manager.delete(
            name: databaseName,
            table: UserSchema.tableName,
            whereClause: "\(UserSchema.id) = ?",
            whereArgs: [id]
        )
    }

    private func fromRow(columns: [String], row: [Any?]) -> User {
        var columnMap: [String: Int] = [:]
        for (index, column) in columns.enumerated() {
            columnMap[column] = index
        }

        return User(
            id: row[columnMap[UserSchema.id]!] as? Int,
            name: row[columnMap[UserSchema.name]!] as! String,
            email: row[columnMap[UserSchema.email]!] as! String
        )
    }
}
```

**Usage:**

```swift
let userHelper = UserHelper(databaseName: "app_db")

do {
    // Insert
    let userId = try userHelper.insert(User(
        id: nil,
        name: "John Doe",
        email: "john@example.com"
    ))

    // Find
    if let user = try userHelper.findById(userId) {
        // Update
        try userHelper.update(User(
            id: user.id,
            name: "Jane Doe",
            email: user.email
        ))
    }

    // Delete
    try userHelper.delete(userId)
} catch {
    print("Error: \(error)")
}
```

## Keeping Native Code in Sync

### 1. After Schema Changes

When you modify your Dart model:

1. Run `dart run build_runner build`
2. Check the generated `.table.g.dart` file
3. Update your native schema constants (Kotlin/Swift)
4. Update CREATE TABLE SQL if structure changed

### 2. Automated Script (Optional)

Create a script to extract and update constants:

```bash
#!/bin/bash
# scripts/sync_schemas.sh

echo "Regenerating Dart code..."
dart run build_runner build --delete-conflicting-outputs

echo "✅ Schemas generated!"
echo "⚠️  Remember to update native schema files:"
echo "   - Android: android/app/src/main/kotlin/*/generated/*Schema.kt"
echo "   - iOS: ios/Runner/Generated/*Schema.swift"
echo ""
echo "Compare with generated files in lib/models/*.table.g.dart"
```

### 3. Code Review Checklist

When reviewing schema changes:

- [ ] Dart model updated with annotations
- [ ] `build_runner` executed
- [ ] Android schema constants updated
- [ ] iOS schema constants updated
- [ ] Native helper classes updated (if used)
- [ ] Database version incremented (if needed)
- [ ] Migration SQL added (if needed)

## Type Conversion Reference

| Dart Type | SQLite Type | Kotlin Type | Swift Type | Conversion |
|-----------|-------------|-------------|------------|------------|
| `int` | INTEGER | Long | Int | Direct |
| `double` | REAL | Double | Double | Direct |
| `String` | TEXT | String | String | Direct |
| `bool` | INTEGER | Boolean | Bool | 1/0 |
| `DateTime` | INTEGER | Long | Int | Milliseconds since epoch |
| `int?` | INTEGER NULL | Long? | Int? | Nullable |

### DateTime Handling

**Dart:**
```dart
@Column()
final DateTime createdAt;

// Stored as: createdAt.millisecondsSinceEpoch
```

**Kotlin:**
```kotlin
// Store
put("created_at", System.currentTimeMillis())

// Read
val timestamp = row[columnMap["created_at"]!!] as Long
val date = Date(timestamp)
```

**Swift:**
```swift
// Store
values["created_at"] = Date().timeIntervalSince1970 * 1000

// Read
let timestamp = row[columnMap["created_at"]!] as! Int
let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
```

### Boolean Handling

**Dart:**
```dart
@Column()
final bool isActive;

// Stored as: isActive ? 1 : 0
```

**Kotlin:**
```kotlin
// Store
put("is_active", if (isActive) 1 else 0)

// Read
val isActive = (row[columnMap["is_active"]!!] as Long) == 1L
```

**Swift:**
```swift
// Store
values["is_active"] = isActive ? 1 : 0

// Read
let isActive = (row[columnMap["is_active"]!] as! Int) == 1
```

## Complete Example

See the [example/native](example/native) directory for:
- **Android WorkManager** example using generated schemas
- **iOS Background Task** example using generated schemas
- Full helper class implementations
- Integration with Flutter code

## Summary

✅ **Benefits of this approach:**
- Single source of truth (Dart annotations)
- Type-safe constants in all languages
- No magic strings or typos
- Easy to keep in sync
- IDE autocomplete support
- Compiler catches errors

✅ **Best practices:**
- Always use schema constants, never hardcode strings
- Update native schemas after Dart model changes
- Use helper classes for complex models
- Include schema sync in code review checklist
- Consider automated tests to verify schema compatibility

The key insight: **You manage the schema in Flutter with annotations, and the native side uses type-safe constants derived from the generated Dart code.** This ensures everything stays in perfect sync!
