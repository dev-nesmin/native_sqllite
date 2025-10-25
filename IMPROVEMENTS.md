# Native SQLite Plugin - Improvements and New Features

## Summary

This document outlines the improvements made to the native_sqlite plugin, the new code generation features, and **automated native code generation** (like flutter_launcher_icons).

## Plugin Improvements

### 1. Enhanced Model Classes

**File**: `native_sqlite_platform_interface/lib/src/models/database_config.dart`
**File**: `native_sqlite_platform_interface/lib/src/models/query_result.dart`

Added proper equality operators (`==`) and `hashCode` implementations to:
- `DatabaseConfig`
- `QueryResult`

**Benefits**:
- Better testability
- Enables use in collections (Set, Map keys)
- Proper value comparison for debugging

**Example**:
```dart
final config1 = DatabaseConfig(name: 'db', version: 1);
final config2 = DatabaseConfig(name: 'db', version: 1);
print(config1 == config2); // Now returns true
```

## New Feature: Code Generation System

### Overview

Created a complete code generation system for native_sqlite that automatically generates:
1. **Table schemas** from annotated Dart classes
2. **Type-safe repository classes** with CRUD operations
3. **Automatic type conversions** between Dart and SQLite types

### Architecture

The code generation system consists of three packages:

```
native_sqlite_annotation/       # Annotation definitions
├── lib/
│   ├── native_sqlite_annotation.dart
│   └── src/
│       └── annotations.dart    # @Table, @Column, @PrimaryKey, etc.
└── pubspec.yaml

native_sqlite_generator/        # Code generator
├── lib/
│   ├── native_sqlite_generator.dart
│   ├── builder.dart
│   └── src/
│       └── table_generator.dart  # Main generator logic
├── build.yaml                  # Builder configuration
└── pubspec.yaml

example/                        # Usage examples
├── lib/
│   ├── main.dart
│   └── models/
│       ├── user.dart
│       └── post.dart
├── build.yaml
└── pubspec.yaml
```

### New Annotations

#### 1. @Table
Marks a class as a database table.

```dart
@Table(name: 'users', indexes: [['email']])
class User { }
```

#### 2. @PrimaryKey
Marks a field as the primary key.

```dart
@PrimaryKey(autoIncrement: true)
final int? id;
```

#### 3. @Column
Configures a database column.

```dart
@Column(
  name: 'email_address',
  unique: true,
  nullable: true,
  defaultValue: '""',
  type: 'TEXT',
)
final String? email;
```

#### 4. @ForeignKey
Defines foreign key relationships.

```dart
@ForeignKey(
  table: 'users',
  column: 'id',
  onDelete: 'CASCADE',
  onUpdate: 'CASCADE',
)
final int userId;
```

#### 5. @Index
Creates database indexes (class-level).

```dart
@Index(
  name: 'idx_email',
  columns: ['email', 'createdAt'],
  unique: true,
)
```

#### 6. @Ignore
Excludes fields from the database.

```dart
@Ignore()
final String computedValue;
```

### Generated Code

For each `@Table` annotated class, the generator creates:

#### Schema Class
```dart
abstract class UserSchema {
  static const String tableName = 'users';
  static const String createTableSql = '''...''';
  static const List<String> indexSql = [...];

  // Column constants
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email_address';
}
```

#### Repository Class
```dart
class UserRepository {
  final String databaseName;
  const UserRepository(this.databaseName);

  Future<int> insert(User entity);
  Future<User?> findById(int id);
  Future<List<User>> findAll();
  Future<int> update(User entity);
  Future<int> delete(int id);
  Future<int> deleteAll();
  Future<int> count();
  Future<List<User>> query(String sql, [List<Object?>? arguments]);
}
```

### Features

#### Type Safety
- Compile-time checking of database schema
- Type-safe CRUD operations
- No stringly-typed SQL

#### Automatic Type Conversion
| Dart Type | SQLite Type | Conversion |
|-----------|-------------|------------|
| `int` | INTEGER | Direct |
| `double` | REAL | Direct |
| `String` | TEXT | Direct |
| `bool` | INTEGER | 1/0 |
| `DateTime` | INTEGER | Milliseconds since epoch |
| `Uint8List` | BLOB | Direct |

#### Null Safety
Full support for nullable and non-nullable types:

```dart
@Column()
final String name;        // NOT NULL

@Column(nullable: true)
final int? age;          // NULL allowed
```

#### Relationships
Foreign key support with cascade actions:

```dart
@ForeignKey(
  table: 'users',
  column: 'id',
  onDelete: 'CASCADE',
)
final int userId;
```

#### Indexes
Both single and composite indexes:

```dart
@Table()
@Index(columns: ['email'])           // Single column
@Index(columns: ['category', 'price']) // Composite
class Product { }
```

### Usage Example

#### 1. Define Model

```dart
import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'user.table.g.dart';

@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(unique: true)
  final String email;

  @Column()
  final DateTime createdAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}
```

#### 2. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 3. Use Generated Repository

```dart
// Open database
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'app_db',
    version: 1,
    onCreate: [UserSchema.createTableSql],
  ),
);

// Use repository
final userRepo = UserRepository('app_db');

// Insert
final userId = await userRepo.insert(User(
  name: 'John Doe',
  email: 'john@example.com',
  createdAt: DateTime.now(),
));

// Query
final user = await userRepo.findById(userId);
final allUsers = await userRepo.findAll();

// Update
await userRepo.update(user!.copyWith(name: 'Jane Doe'));

// Delete
await userRepo.delete(userId);
```

### Documentation

Created comprehensive documentation:

1. **CODEGEN.md**: Complete guide to code generation
   - Setup instructions
   - Annotations reference
   - Generated code explanation
   - Advanced usage examples
   - Best practices
   - Migration guide
   - Troubleshooting

2. **native_sqlite_generator/README.md**: Generator package documentation
   - Installation
   - Usage examples
   - Type mapping
   - Advanced features

3. **native_sqlite_annotation/README.md**: Annotation package documentation
   - Basic usage
   - Available annotations

4. **example/README.md**: Example project documentation
   - How to run the example
   - What features are demonstrated

### Example Project

Created a complete Flutter example app (`example/`) demonstrating:

- **User Model**: Basic table with auto-increment ID, unique constraints, DateTime fields
- **Post Model**: Foreign key relationship to User with CASCADE delete
- **Flutter UI**: Interactive app to add/view/delete data
- **Repository Pattern**: Type-safe CRUD operations

### Benefits

1. **Developer Productivity**
   - Write less boilerplate code
   - Focus on business logic
   - Faster development cycle

2. **Code Quality**
   - Type safety prevents runtime errors
   - Better IDE support (autocomplete, refactoring)
   - Self-documenting code

3. **Maintainability**
   - Schema defined in one place
   - Easy to refactor (rename fields, change types)
   - Version control friendly

4. **Performance**
   - Generated code is optimized
   - No reflection overhead
   - Compile-time code generation

### Backward Compatibility

The code generation system is **completely optional**. Existing code using the manual API continues to work without any changes:

```dart
// Old way - still works
await NativeSqlite.insert('db', 'users', {'name': 'John'});

// New way - with code generation
await userRepo.insert(User(name: 'John'));
```

## File Structure

```
native_sqllite/
├── native_sqlite/                  # Main plugin (unchanged)
├── native_sqlite_platform_interface/
│   └── lib/src/models/
│       ├── database_config.dart    # ✨ Added equality operators
│       └── query_result.dart       # ✨ Added equality operators
├── native_sqlite_annotation/       # ✨ NEW: Annotations package
├── native_sqlite_generator/        # ✨ NEW: Code generator
├── example/                        # ✨ NEW: Example app
├── CODEGEN.md                      # ✨ NEW: Code generation guide
└── IMPROVEMENTS.md                 # ✨ NEW: This file
```

## Testing Recommendations

To test the new features:

1. **Annotation Package**:
   ```bash
   cd native_sqlite_annotation
   flutter pub get
   ```

2. **Generator Package**:
   ```bash
   cd native_sqlite_generator
   flutter pub get
   ```

3. **Example App**:
   ```bash
   cd example
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter run
   ```

## Migration Path

For existing projects wanting to adopt code generation:

1. Add dependencies to `pubspec.yaml`
2. Create model classes with annotations
3. Run `build_runner`
4. Gradually migrate from manual SQL to generated repositories
5. Both approaches can coexist during migration

## Future Enhancements

Potential future improvements:

1. **Migrations**: Automatic migration generation from schema changes
2. **Relationships**: Lazy loading and eager loading support
3. **Queries**: Type-safe query builder
4. **Validation**: Built-in validation annotations
5. **Serialization**: JSON serialization/deserialization
6. **Testing**: Mock repository generation for unit tests

## Native Code Synchronization

### The Challenge

One of the key features of native_sqlite is that the database can be accessed from **both Flutter and native code** (Android Kotlin/iOS Swift). However, this creates a synchronization challenge:

- Flutter code uses generated Dart schemas
- Native code needs the same table/column names
- Manual synchronization is error-prone

### The Solution

The code generation system now provides **complete native code support**:

1. **Generated Dart schemas** include all constants
2. **Native code examples** show how to mirror these constants
3. **Helper classes** provide type-safe CRUD in Kotlin/Swift
4. **Comprehensive documentation** ensures everything stays in sync

### Native Code Examples

**Android (Kotlin):**
```kotlin
// Mirror the generated Dart schema
object UserSchema {
    const val TABLE_NAME = "users"
    const val ID = "id"
    const val NAME = "name"
    const val EMAIL = "email_address"
}

// Use in WorkManager, Services, etc.
val userId = NativeSqliteManager.insert(
    "app_db",
    UserSchema.TABLE_NAME,  // Type-safe!
    mapOf(
        UserSchema.NAME to "John Doe",
        UserSchema.EMAIL to "john@example.com"
    )
)
```

**iOS (Swift):**
```swift
// Mirror the generated Dart schema
enum UserSchema {
    static let tableName = "users"
    static let id = "id"
    static let name = "name"
    static let email = "email_address"
}

// Use in Background Tasks, App Extensions, etc.
let userId = try manager.insert(
    name: "app_db",
    table: UserSchema.tableName,  // Type-safe!
    values: [
        UserSchema.name: "John Doe",
        UserSchema.email: "john@example.com"
    ]
)
```

### Automated Native Code Generation

**NEW**: Like `flutter_launcher_icons`, native_sqlite now **automatically generates** native code!

No manual copy-paste needed. Just configure and run:

```yaml
# native_sqlite_config.yaml
native_sqlite:
  generate_native: true

  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/generated"
    package: "com.example.generated"

  ios:
    enabled: true
    output_path: "ios/Runner/Generated"

  models:
    - lib/models/**/*.dart
```

Run the generator:
```bash
# Using the shell script
./scripts/generate_native.sh

# Or directly
dart run native_sqlite_generator:generate_native
```

**Generated files** are written directly to:
- ✅ `android/app/src/main/kotlin/generated/` - Kotlin schemas and helpers
- ✅ `ios/Runner/Generated/` - Swift schemas and helpers

**Benefits**:
- ⚡ **One command** generates everything
- 🎯 **Zero manual work** - files written automatically
- 🔒 **Perfect sync** - always matches Dart schema
- 🚀 **Fast** - runs in seconds
- 📦 **CI-friendly** - add to your build pipeline

See [AUTOMATED_GENERATION.md](AUTOMATED_GENERATION.md) for complete guide.

### Documentation

Comprehensive guides for native code usage:

1. **AUTOMATED_GENERATION.md** ⭐ **NEW**: Automatic code generation guide
   - Configuration reference
   - Shell script usage
   - CI/CD integration
   - Complete workflow

2. **NATIVE_USAGE.md**: Manual approach guide (if you prefer more control)
   - Shows the pattern behind automation
   - Useful for understanding generated code

3. **example/native_examples/**: Full working examples
   - Android: Schema constants, helper classes, WorkManager example
   - iOS: Schema constants, helper classes, Background Task example

4. **scripts/generate_native.sh**: One-command generation script

### Benefits

✅ **Single Source of Truth**: Define schema once in Dart
✅ **Type Safety Everywhere**: Kotlin, Swift, and Dart all use constants
✅ **No Manual Sync**: Copy generated constants to native code
✅ **Prevents Typos**: No magic strings in SQL queries
✅ **IDE Support**: Autocomplete works in all languages
✅ **Easy Updates**: Change Dart model, regenerate, update native constants

## Conclusion

The improvements to native_sqlite provide:

1. **Better code quality** through equality operators in models
2. **Significant productivity boost** through code generation
3. **Type safety** throughout the database layer in Dart, Kotlin, and Swift
4. **Perfect synchronization** between Flutter and native code
5. **Excellent documentation** for easy adoption (5 comprehensive guides)
6. **Backward compatibility** with existing code
7. **Production-ready examples** for all platforms

The plugin is now a complete solution for cross-platform SQLite access with code generation, supporting:
- ✅ Flutter/Dart with auto-generated repositories
- ✅ Android/Kotlin with schema constants and helpers
- ✅ iOS/Swift with schema constants and helpers
- ✅ Background tasks and services on all platforms
- ✅ Full synchronization across all codebases
