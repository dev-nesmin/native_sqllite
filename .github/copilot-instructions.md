# Native SQLite - AI Agent Instructions

## Project Overview

Native SQLite is a code-generation based Flutter/Dart SQLite plugin with multi-platform support (Android, iOS, Web). It uses build_runner to generate type-safe schemas, repositories, and query builders from annotated model classes, plus native Kotlin/Swift schemas for platform-side database access.

**Packages:**
- `native_sqlite` - Main plugin (exports annotations & platform interface)
- `native_sqlite_annotations` - Annotations (`@DbTable`, `@PrimaryKey`, `@DbColumn`, etc.)
- `native_sqlite_generator` - Build_runner code generator (generates `.table.dart` + `DatabaseManager`)
- `native_sqlite_platform_interface` - Platform channel interface
- `native_sqlite_android/ios/web` - Platform implementations
- `native_sqlite_inspector` - DevTools-style database inspector web app
- `example` - Example app demonstrating all features

## Critical Rules

### DO NOT
- ❌ **Manually create/edit `.table.dart` files** - These are auto-generated
- ❌ **Edit any generated files** (files with "GENERATED CODE - DO NOT MODIFY")
- ❌ **Create markdown documentation files after each change** unless explicitly requested
- ❌ **Create backwards compatibility code/methods** - Keep APIs clean

### DO
- ✅ Use `snake_case.dart` for model filenames (e.g., `user.dart`, `advanced_user.dart`)
- ✅ Run `dart run build_runner build --delete-conflicting-outputs` after model changes
- ✅ Use `flutter_manager.sh` script for batch operations across multiple packages
- ✅ Check generated `lib/generated/database_manager.dart` for auto-managed tables

## Essential Workflows

### 1. Creating a New Table Model

```dart
// lib/models/user.dart
import 'package:native_sqlite/native_sqlite.dart';

part 'user.table.dart';  // Generated file

@DbTable(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @DbColumn()
  final String name;
  
  @DbColumn(name: 'email_address', unique: true)
  final String email;
  
  const User({this.id, required this.name, required this.email});
}
```

Then run: `dart run build_runner build --delete-conflicting-outputs`

**Generated outputs:**
- `lib/models/user.table.dart` - Schema, QueryBuilder, Repository classes
- `lib/generated/schemas/user.schema.json` - Schema snapshot for migrations
- `lib/generated/database_manager.dart` - Auto-updated with new table

### 2. Build System Architecture

**Build phases (controlled by `build.yaml`):**
1. **`schema_registry` builder** - Scans all models, generates `DatabaseManager` (runs first)
2. **`migration` builder** - Creates schema snapshots in `lib/generated/schemas/`
3. **`table` builder** - Generates `.table.dart` files for each `@DbTable` model

**Post-build:** `native_code` runs after build_runner to generate Kotlin/Swift schemas

### 3. DatabaseManager Auto-Initialization

```dart
// App startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseManager.init(
    name: 'app_database',
    enableWAL: true,
    enableForeignKeys: true,
  );
  runApp(MyApp());
}
```

`DatabaseManager` is **automatically generated** from all `@DbTable(auto: true)` models. No manual registration needed.

### 4. Native Code Generation

Configure in `native_sqlite_config.yaml` (at project root):
```yaml
native_sqlite:
  generate_native: true
  database_name: 'example_app'
  
  android:
    enabled: true
    output_path: 'android/app/src/main/kotlin/com/example/myapp/generated'
    package: 'com.example.myapp.generated'

  ios:
    enabled: true
    output_path: 'ios/Runner/Generated'
```

Run: `dart run native_sqlite_generator`

Generates Kotlin `*Schema.kt` and Swift `*Schema.swift` files for native platform code.

## Key Patterns

### Annotations
- `@DbTable(name: 'table_name', database: 'db_name', auto: true)` - Mark class as table
- `@PrimaryKey(autoIncrement: true)` - Primary key field
- `@DbColumn(name: 'col_name', unique: true, defaultValue: '1')` - Column definition
- `@ForeignKey('referenced_table', 'referenced_column')` - Foreign key constraint
- `@EnumField(type: EnumType.name)` - Control enum storage (ordinal/name)
- `@Ignore()` - Skip field from schema

### Generated Classes (per table)
- `UserSchema` - SQL constants (`createTableSql`, `indexSql`, column names)
- `UserQueryBuilder` - Fluent query builder (`.nameContains()`, `.ageGreaterThan()`)
- `UserRepository` - CRUD operations (`.insert()`, `.findById()`, `.update()`)

### Testing
Use `MockNativeSqlitePlatform` to mock platform interactions:
```dart
class MockNativeSqlitePlatform extends NativeSqlitePlatform 
    with MockPlatformInterfaceMixin {
  // Override insert, query, update, delete
}
```

## Common Commands

```bash
# Run build_runner (from example/ or project root)
dart run build_runner build --delete-conflicting-outputs

# Generate native Kotlin/Swift schemas
dart run native_sqlite_generator

# Batch operations across all packages
./flutter_manager.sh --pub-get --build-runner

# Analyze schemas
dart run native_sqlite_generator analyze

# Generate migration SQL
dart run native_sqlite_generator migrate --from old.json --to new.json

# Organize schema files
dart run native_sqlite_generator:organize_schemas
```

## File Organization

```
lib/
├── models/                    # User-defined models
│   ├── user.dart             # Source model
│   └── user.table.dart       # Generated (DO NOT EDIT)
└── generated/
    ├── database_manager.dart # Auto-generated manager (DO NOT EDIT)
    └── schemas/              # Schema snapshots for migrations
        └── user.schema.json  # Generated snapshot
```

## Migration Strategy

### Automatic Schema Tracking
Schema changes are tracked via JSON snapshots in `lib/generated/schemas/*.schema.json`:

```dart
// 1. Modify model (add/change fields)
@DbTable(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @DbColumn()
  final String name;
  
  @DbColumn()  // ← New field
  final String? phoneNumber;
}

// 2. Run build_runner
// dart run build_runner build --delete-conflicting-outputs

// 3. Schema snapshot auto-updates:
// - lib/generated/schemas/user.schema.json (version incremented)
// - lib/generated/database_manager.dart (schemaVersion updated)
```

### Migration Execution
The `DatabaseManager.init()` handles migrations automatically via `onCustomMigrate` callback:

```dart
await DatabaseManager.init(
  name: 'example_app',
  onCustomMigrate: (databaseName, oldVersion, newVersion) async {
    // Run custom SQL for specific schema versions
    if (oldVersion < 123456) {
      await NativeSqlite.execute(
        databaseName,
        'ALTER TABLE users ADD COLUMN avatar TEXT',
      );
    }
    if (oldVersion < 234567) {
      await NativeSqlite.execute(
        databaseName,
        'UPDATE users SET status = "active" WHERE status IS NULL',
      );
    }
  },
);
```

### Migration SQL Generation
Generate migration SQL between schema versions:

```bash
# Compare two schema snapshots and generate migration SQL
dart run native_sqlite_generator migrate \
  --from lib/generated/schemas/user.schema.v1.json \
  --to lib/generated/schemas/user.schema.v2.json \
  --output migrations/v1_to_v2.sql
```

Generated SQL handles:
- **Simple changes**: `ALTER TABLE ADD COLUMN` for new fields
- **Complex changes**: Table recreation for type changes, NOT NULL additions
- **Data preservation**: Automatic `INSERT INTO new_table SELECT ... FROM old_table`
- **Index recreation**: Drops and recreates indexes after table changes

### Native Platform Migrations
For Android/iOS native code, migration stubs are auto-generated:

```kotlin
// Android: generated/migrations/Migration_1_2.kt
object Migration_1_2 {
  fun migrate(databaseName: String) {
    db.beginTransaction()
    try {
      // Add your migration logic here
      db.execSQL("ALTER TABLE users ADD COLUMN phone TEXT")
      db.setTransactionSuccessful()
    } finally {
      db.endTransaction()
    }
  }
}
```

```swift
// iOS: Generated/Migration_1_2.swift
public class Migration_1_2 {
  public static func migrate(databaseName: String) throws {
    try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
    // Add migration logic here
    try manager.execute(name: databaseName, sql: "COMMIT")
  }
}
```

## Native Platform Integration

### Using Generated Schemas in Native Code

Generated schemas provide type-safe constants for native Android/iOS database access:

```swift
// iOS: example/ios/Runner/AppDelegate.swift
import NativeSqlite

// Generated schema constants available
let userId = try manager.insert(
  name: "example_app",
  table: UserSchema.tableName,  // "users"
  values: [
    UserSchema.name: "Native iOS User",        // Column: "name"
    UserSchema.email: "ios@example.com",       // Column: "email"
    UserSchema.age: 30,                        // Column: "age"
    UserSchema.isActive: 1,                    // Column: "is_active"
    UserSchema.createdAt: Int(Date().timeIntervalSince1970 * 1000)
  ]
)

// Type-safe queries
let queryResult = try manager.query(
  name: "example_app",
  sql: "SELECT \(UserSchema.name), \(UserSchema.email) FROM \(UserSchema.tableName) WHERE \(UserSchema.isActive) = ?",
  args: [1]
)
```

### Generated Schema Structure

Each model generates a schema object with:
- `TABLE_NAME` / `tableName` - Table name constant
- Column name constants - All fields as `SCREAMING_SNAKE` (Kotlin) or `camelCase` (Swift)
- `CREATE_TABLE_SQL` / `createTableSql` - Full table creation SQL
- Helper methods (optional, when `generate_helpers: true`)

### Workflow
1. Define Dart models with `@DbTable`
2. Run `dart run build_runner build` → Generates Dart code
3. Run `dart run native_sqlite_generator` → Generates Kotlin/Swift schemas
4. Use generated constants in native platform code (Android `MainActivity.kt`, iOS `AppDelegate.swift`)

## Query Builder Patterns

### Fluent Query API

Generated `QueryBuilder` classes provide type-safe, chainable query methods:

```dart
final repository = const UserRepository();

// Simple queries
final activeUsers = await repository
  .queryBuilder()
  .isActiveIsTrue()
  .findAll();

// String operations
final users = await repository
  .queryBuilder()
  .nameContains('john')      // LIKE '%john%'
  .emailStartsWith('admin')  // LIKE 'admin%'
  .findAll();

// Numeric comparisons
final adults = await repository
  .queryBuilder()
  .ageGreaterThan(18)
  .ageLessThanOrEqualTo(65)
  .findAll();

// Range queries
final midAge = await repository
  .queryBuilder()
  .ageBetween(25, 40)
  .findAll();

// Null checks
final usersWithPhone = await repository
  .queryBuilder()
  .phoneNumberIsNotNull()
  .findAll();

// Complex queries with chaining
final results = await repository
  .queryBuilder()
  .isActiveIsTrue()
  .ageBetween(20, 40)
  .nameContains('smith')
  .sortByNameAsc()
  .limit(10)
  .offset(20)
  .findAll();

// Aggregation
final count = await repository
  .queryBuilder()
  .isActiveIsTrue()
  .count();
```

### Generated Methods Per Field Type

**String fields** get:
- `.fieldEqualTo(value)`
- `.fieldContains(value)` → LIKE `%value%`
- `.fieldStartsWith(value)` → LIKE `value%`
- `.fieldEndsWith(value)` → LIKE `%value`
- `.fieldIsNull()` / `.fieldIsNotNull()`

**Numeric fields** get:
- `.fieldEqualTo(value)`
- `.fieldGreaterThan(value)` / `.fieldGreaterThanOrEqualTo(value)`
- `.fieldLessThan(value)` / `.fieldLessThanOrEqualTo(value)`
- `.fieldBetween(min, max)`

**Boolean fields** get:
- `.fieldIsTrue()` / `.fieldIsFalse()`

**All queries** support:
- `.sortByFieldAsc()` / `.sortByFieldDesc()`
- `.limit(count)` / `.offset(count)`
- `.findAll()` - Returns `List<Model>`
- `.findFirst()` - Returns `Model?`
- `.count()` - Returns `int`

## Multi-Database Support

### Per-Table Database Configuration

Each table can target a different database:

```dart
// Default database from build.yaml
@DbTable(name: 'users')
class User { /* ... */ }

// Specific database override
@DbTable(name: 'logs', database: 'analytics_db')
class AppLog { /* ... */ }

// Cache database
@DbTable(name: 'cached_items', database: 'cache_db')
class CacheEntry { /* ... */ }
```

### Configuration Hierarchy

Database name resolution (in order of priority):
1. `@DbTable(database: 'explicit_db')` - Annotation parameter
2. `build.yaml` `default_database: 'config_db'` - Build configuration
3. `'default_app'` - Fallback default

```yaml
# example/build.yaml
targets:
  $default:
    builders:
      native_sqlite_generator:table:
        options:
          default_database: 'example_app'  # Applies to all tables
```

### Repository Usage with Multiple Databases

Generated repositories accept database name parameter:

```dart
// Using default database (from annotation/config)
final userRepo = const UserRepository();

// Override database at runtime
final analyticsRepo = const AppLogRepository('analytics_db');
final cacheRepo = const CacheEntryRepository('cache_db');

// Initialize multiple databases
await DatabaseManager.init(name: 'main_app');
await NativeSqlite.open(name: 'analytics_db');
await NativeSqlite.open(name: 'cache_db');
```

### Use Cases
- **Separation of concerns**: User data vs analytics vs cache
- **Different WAL/journal modes**: Production DB (WAL) vs temp cache (DELETE)
- **Independent versioning**: Migrate databases separately
- **Security boundaries**: Encrypted user DB, unencrypted logs

**Note**: `DatabaseManager.init()` manages only tables with `auto: true` in a single database. For multi-database apps with auto-management, initialize each database separately using `NativeSqlite.open()`.

## SQLite Inspector Tool

### Development-Time Database Inspection

The `native_sqlite_inspector` package provides a web-based database inspector (similar to Chrome DevTools):

**Access during development:**
1. Run your Flutter app in debug mode
2. Inspector auto-connects via VM Service
3. Navigate to `http://localhost:<port>/<secret>` (printed in console)

### Features
- **Live database browsing** - View all tables and schemas
- **Data grid** - Browse, search, and filter table data
- **Query builder** - Execute custom SQL queries
- **Real-time updates** - See data changes as they happen
- **Multi-database support** - Switch between databases

### Usage in Your App
The inspector is automatically enabled in debug builds when using `DatabaseManager.init()`. No additional setup required.

**For custom integration:**
```dart
import 'package:native_sqlite/native_sqlite.dart';

// Inspector automatically registers VM service extensions
// Access via: ext.native_sqlite.getTables, ext.native_sqlite.queryTable
```

### Deployment
The inspector is a standalone web app (`native_sqlite_inspector/build/web/`) that can be:
- Hosted for team access during development
- Integrated into internal admin tools
- Run locally via `flutter run -d chrome` in the inspector package

## Dependencies & Build Configuration

Key dependencies in `pubspec.yaml`:
```yaml
dependencies:
  native_sqlite: ^x.x.x
  native_sqlite_annotations: ^x.x.x

dev_dependencies:
  build_runner: ^2.10.1
  native_sqlite_generator: ^x.x.x
```

`build.yaml` controls generator behavior (table name case, column name case, verbosity).

## Debugging

- Generated code issues → Check model annotations match expected patterns
- Build failures → Run with `--verbose` flag or check `logs/` directory
- Platform errors → Verify `native_sqlite_config.yaml` paths are correct
- Missing tables in `DatabaseManager` → Ensure `@DbTable(auto: true)` is set
- Query builder compilation errors → Regenerate after model changes
- Native schema mismatch → Re-run `dart run native_sqlite_generator`
