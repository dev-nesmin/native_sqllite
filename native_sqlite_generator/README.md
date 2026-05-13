# native_sqlite_generator

The `build_runner` code generator for the `native_sqlite` plugin. Processes `@DbTable` annotated classes and generates:

- `<model>.table.dart` — `XxxSchema`, `XxxRepository`, `XxxQueryBuilder`
- `lib/generated/database_manager.dart` — auto-generated `DatabaseManager`
- `lib/generated/native_sqlite_schema.json` — schema version snapshot
- Kotlin/Swift helper files (optional, via `native_sqlite_config.yaml`)

---

## Installation

```yaml
dev_dependencies:
  native_sqlite_generator: ^1.0.0
  build_runner: ^2.4.0
```

---

## Running the Generator

### Dart code generation

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (re-runs on file save)
dart run build_runner watch --delete-conflicting-outputs
```

### Native Kotlin/Swift generation

```bash
# After running build_runner
dart run native_sqlite_generator
```

---

## `build.yaml` Configuration

Place `build.yaml` in the same directory as `pubspec.yaml`.

```yaml
targets:
  $default:
    builders:
      native_sqlite_generator:table:
        options:
          # Default database name for all tables.
          # Override per-table with @DbTable(database: 'other_db')
          default_database: 'my_app'

          # Format generated code with dart format (default: false)
          format: true

          # Generate helper extension methods (default: true)
          generate_helpers: true

          # Cache builds to skip unchanged tables (default: true)
          enable_cached_builds: true

          # Table name casing strategy (default: 'snake')
          # Options: 'snake', 'camel', 'pascal', 'none'
          table_name_case: 'snake'

          # Column name casing strategy (default: 'snake')
          column_name_case: 'snake'

          # Verbose logging during generation (default: false)
          verbose: false
```

---

## Generated Files

### `<model>.table.dart`

Generated next to the model file. Contains three classes:

#### `XxxSchema` — SQL constants

```dart
class UserSchema {
  static const String tableName = 'users';
  static const String createTableSql = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      ...
    )
  ''';
  static const List<String> indexSql = [
    'CREATE INDEX IF NOT EXISTS idx_users_email ON users (email)',
  ];

  // Column name constants
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email';
}
```

#### `XxxRepository` — CRUD operations

```dart
class UserRepository {
  UserRepository([String databaseName = 'my_app']);

  Future<int> insert(User entity);        // Returns new row ID
  Future<User?> findById(int id);         // Returns null if not found
  Future<List<User>> findAll();
  Future<int> update(User entity);        // Returns rows affected
  Future<int> delete(int id);             // Returns rows deleted
  Future<int> deleteAll();                // Returns rows deleted
  Future<int> count();
  Future<List<User>> query(String sql, [List<Object?>? args]);
}
```

The repository handles:
- Dart ↔ SQL type conversion (DateTime, bool, Duration, Uri, enums, converters, JSON)
- Auto-increment / UUID primary key insertion
- Nullable field marshalling

#### `XxxQueryBuilder` — Fluent type-safe queries

```dart
class UserQueryBuilder {
  UserQueryBuilder(String databaseName);

  // Filter methods — generated per column, per type
  UserQueryBuilder whereIdEquals(int value);
  UserQueryBuilder whereNameContains(String value);
  UserQueryBuilder whereNameStartsWith(String value);
  UserQueryBuilder whereEmailEquals(String value);
  UserQueryBuilder whereIsActiveEquals(bool value);
  UserQueryBuilder whereCreatedAtGreaterThan(DateTime value);
  UserQueryBuilder whereCreatedAtBetween(DateTime from, DateTime to);

  // Sorting
  UserQueryBuilder orderByIdAscending();
  UserQueryBuilder orderByIdDescending();
  UserQueryBuilder orderByNameAscending();
  UserQueryBuilder orderByCreatedAtDescending();

  // Pagination
  UserQueryBuilder limit(int count);
  UserQueryBuilder offset(int count);

  // Execution
  Future<List<User>> find();
  Future<User?> findOne();
  Future<int> count();
  Future<int> delete();
}
```

---

### `lib/generated/database_manager.dart`

Auto-generated (no trigger file needed). Aggregates all `@DbTable(auto: true)` tables in the project.

```dart
class DatabaseManager {
  // Name of the default database
  static const String databaseName = 'my_app';

  // Current schema version (read from native_sqlite_schema.json)
  static int get schemaVersion => 3;

  // table name → CREATE TABLE SQL
  static const Map<String, String> tables = {
    'users': 'CREATE TABLE users (...)',
    'orders': 'CREATE TABLE orders (...)',
  };

  // Ordered by foreign key dependencies (parents before children)
  static List<String> get onCreateStatements => [...];

  static List<String> get tableNames => ['users', 'orders'];

  // Generated migration entries
  static const List<Map<String, dynamic>> migrations = [
    {
      'tableName': 'users',
      'className': 'User',
      'fromVersion': 2,
      'toVersion': 3,
      'sql': ['ALTER TABLE users ADD COLUMN phone TEXT'],
      'summary': 'Added columns: phone',
    },
  ];
}
```

Pass `DatabaseManager` fields directly to `AutoMigration.createConfig(...)`:

```dart
await NativeSqlite.open(
  config: AutoMigration.createConfig(
    name: DatabaseManager.databaseName,
    schemaVersion: DatabaseManager.schemaVersion,
    onCreateStatements: DatabaseManager.onCreateStatements,
    tables: DatabaseManager.tables,
    tableNames: DatabaseManager.tableNames,
    migrations: DatabaseManager.migrations,
  ),
);
```

---

### `lib/generated/native_sqlite_schema.json`

A JSON snapshot of the current schema used to detect changes between builds. Commit this file so that migrations can be computed correctly on CI.

```json
{
  "version": "3",
  "generatedAt": "2025-05-12T10:00:00.000Z",
  "tables": [
    {
      "tableName": "users",
      "dartName": "User",
      "columns": [
        { "name": "id", "dartName": "id", "type": "INTEGER", "primaryKey": true, "autoIncrement": true, "nullable": false },
        { "name": "name", "dartName": "name", "type": "TEXT", "nullable": false },
        { "name": "email", "dartName": "email", "type": "TEXT", "nullable": false, "unique": true }
      ],
      "indexes": [{ "columns": ["email"], "unique": false }]
    }
  ]
}
```

---

## CLI Commands

Run from the project root:

```bash
dart run native_sqlite_generator <command> [options]
```

### `analyze`

Lints all `@DbTable` classes in `lib/` for common issues.

```bash
dart run native_sqlite_generator analyze
dart run native_sqlite_generator analyze --verbose
```

**Checks performed:**
- Missing `@PrimaryKey` (error)
- Non-PascalCase class name (warning)
- Non-camelCase field name (warning)
- Foreign key field without an index (info)
- Field type without a converter or `@JsonField` (warning)

**Example output:**
```
🔍 Analyzing table definitions...

📊 Analysis complete:
   Files analyzed: 8
   Tables found: 5

❌ Errors:
  Table Product has no primary key
    at lib/models/product.dart
    💡 Add @PrimaryKey() annotation to an id field

⚠️  Warnings:
  Foreign key field "categoryId" would benefit from an index
    at lib/models/product.dart
    💡 Add @Index() annotation for better query performance
```

---

### `stats`

Prints schema statistics and health metrics.

```bash
dart run native_sqlite_generator stats
dart run native_sqlite_generator stats --verbose
```

**Example output:**
```
📊 Gathering table statistics...

📈 Project Statistics:

Tables & Fields:
   Total tables: 5
   Total fields: 42
   Average fields per table: 8.4

Constraints & Indexes:
   Primary keys: 5
   Foreign keys: 4
   Indexes: 7

Type Distribution:
   String          18 (42.9%)  ████████░░░░░░░░░░░░
   int             10 (23.8%)  ████░░░░░░░░░░░░░░░░
   DateTime         6 (14.3%)  ███░░░░░░░░░░░░░░░░░
   bool             4 ( 9.5%)  ██░░░░░░░░░░░░░░░░░░

Health Metrics:
   Primary key coverage: 100%
   Foreign key index coverage: 75%
   Average table complexity: Medium
```

---

### `migrate`

Generates migration SQL by comparing two schema snapshot files.

```bash
dart run native_sqlite_generator migrate \
  --from lib/generated/schemas/v1.schema.json \
  --to   lib/generated/schemas/v2.schema.json \
  --output migrations/001_v1_to_v2.sql
```

**Options:**

| Option | Required | Description |
|--------|----------|-------------|
| `--from <file>` | Yes | Path to the old schema snapshot |
| `--to <file>` | Yes | Path to the new schema snapshot |
| `--output <file>` | No | Write SQL to this file (prints to stdout if omitted) |
| `--verbose` | No | Show detailed progress |

**Example output (stdout):**
```sql
-- Migration generated: 2025-05-12T10:00:00.000Z
-- From version: v1
-- To version:   v2

BEGIN TRANSACTION;

-- Update table: users (1 changes)
ALTER TABLE users ADD COLUMN phone TEXT;

COMMIT;
```

---

### `export`

Exports all table schemas from `lib/` to a JSON or YAML file for documentation or external tooling.

```bash
dart run native_sqlite_generator export \
  --output docs/schema.json \
  --format json          # or: --format yaml
```

**Options:**

| Option | Required | Description |
|--------|----------|-------------|
| `--output <file>` | Yes | Output file path |
| `--format <fmt>` | No | `json` (default) or `yaml` |
| `--verbose` | No | List each table as it is processed |

---

### `clean-cache`

Clears the generator's build cache. Use this if you see stale generated code.

```bash
dart run native_sqlite_generator clean-cache
```

---

### `cache-stats`

Shows cache hit/miss statistics from the last build.

```bash
dart run native_sqlite_generator cache-stats
```

---

## Native Code Generation (`native_sqlite_config.yaml`)

To generate Kotlin/Swift helpers, add `native_sqlite_config.yaml` to your project root:

```yaml
native_sqlite:
  generate_native: true
  database_name: 'my_app'
  include_examples: true    # include usage comments in generated files

  models:
    - 'lib/models/*.dart'   # glob patterns for model files

  android:
    enabled: true
    output_path: 'android/app/src/main/kotlin/com/example/myapp/generated'
    package: 'com.example.myapp.generated'
    generate_helpers: true  # generate XxxHelper.kt alongside XxxSchema.kt

  ios:
    enabled: true
    output_path: 'ios/Runner/Generated'
    generate_helpers: true
```

Run the native generator after `build_runner`:

```bash
dart run native_sqlite_generator
```

### Generated Kotlin files

| File | Description |
|------|-------------|
| `UserSchema.kt` | Column constants and `CREATE TABLE` SQL |
| `UserHelper.kt` | Cursor-to-model mapping helpers |
| `SchemaVersionManager.kt` | Read/write `PRAGMA user_version` |
| `Migration_1_2.kt` | Stub migration class with helper methods |

### Generated Swift files

| File | Description |
|------|-------------|
| `UserSchema.swift` | Column constants and `CREATE TABLE` SQL |
| `UserHelper.swift` | Row-to-model mapping helpers |
| `SchemaVersionManager.swift` | Read/write `PRAGMA user_version` |
| `Migration_1_2.swift` | Stub migration class with helper methods |

### Migration stubs

The generator creates `Migration_X_Y` stub classes with three ready-to-use helper methods. You must implement the `migrate()` body:

```kotlin
// Migration_1_2.kt — fill in the migration steps
class Migration_1_2 : Migration(1, 2) {
    override fun migrate(db: SQLiteDatabase) {
        // TODO: implement migration steps
        addColumn(db, "users", "phone", "TEXT")
    }
}
```

```swift
// Migration_1_2.swift — fill in the migration steps
class Migration_1_2: Migration {
    static func migrate(_ db: OpaquePointer) {
        // TODO: implement migration steps
        addColumn(db, table: "users", column: "phone", type: "TEXT")
    }
}
```

**Available helper methods:**

| Method | Description |
|--------|-------------|
| `addColumn(db, table, column, type)` | `ALTER TABLE ADD COLUMN` |
| `renameTable(db, from, to)` | `ALTER TABLE RENAME TO` |
| `migrateTableData(db, from, to, columns)` | Copy rows between tables |

---

## How the Generator Works

```
Your model files (@DbTable classes)
          │
          ▼
   TableAnalyzer           ← Reads annotations, extracts TableInfo
          │
          ├─► SchemaGenerator       → XxxSchema (SQL constants)
          ├─► RepositoryGenerator   → XxxRepository (CRUD)
          └─► QueryBuilderGenerator → XxxQueryBuilder (fluent queries)
                    │
                    ▼
         SchemaRegistryBuilder      ← Aggregates all tables
                    │
                    ├─► DatabaseManager.dart
                    └─► native_sqlite_schema.json
                                   │
                                   ▼
                        NativeCodeGenerator     ← Reads schema JSON
                                   │
                        ├─► NativeKotlinGenerator → *.kt files
                        └─► NativeSwiftGenerator  → *.swift files
```

**Build caching:** The generator caches a fingerprint of each model file. On subsequent builds, unchanged models are skipped. Use `clean-cache` if you need a full rebuild.

---

## Known Limitations

- The schema version in generated native stubs is always `1` (versioning not yet implemented). See [MISSING_IMPLEMENTATIONS.md](../MISSING_IMPLEMENTATIONS.md) issue #7.
- The schema file path is hard-coded to `lib/generated/native_sqlite_schema.json`. See issue #8.
- Table-recreation migrations do not preserve foreign-key constraints. See issue #5.
