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
  native_sqlite_generator: ^0.0.1
  build_runner: ^2.4.0
```

---

## Running the Generator

### Dart code generation

```bash
# One-time build
flutter pub run build_runner build

# Watch mode (re-runs on file save)
flutter pub run build_runner watch
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
        options: &native_sqlite_options
          table_name_case: 'snake'
          column_name_case: 'snake'
          verbose: false
      native_sqlite_generator:migration:
        options: *native_sqlite_options
      native_sqlite_generator:schema_registry:
        options: *native_sqlite_options
```

Use this single YAML anchor for every builder that analyzes models. This keeps
`table_name_case` and `column_name_case` identical; generation fails rather
than producing a mismatched schema if they diverge. Supported values for both
are `snake`, `camel`, `pascal`, and `none`. Unknown options and invalid values
are build errors. The database name and native output settings belong only in
`native_sqlite_config.yaml`.

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
  UserQueryBuilder(NativeSqliteDatabase database);

  // Filter methods — generated per column, per type
  UserQueryBuilder idEqualTo(int value);
  UserQueryBuilder nameContains(String value);
  UserQueryBuilder nameStartsWith(String value);
  UserQueryBuilder emailEqualTo(String value);
  UserQueryBuilder isActiveIsTrue();
  UserQueryBuilder createdAtAfter(DateTime value);
  UserQueryBuilder createdAtBetween(DateTime from, DateTime to);

  // Sorting
  UserQueryBuilder sortByIdAsc();
  UserQueryBuilder sortByIdDesc();
  UserQueryBuilder sortByNameAsc();
  UserQueryBuilder thenByCreatedAtDesc();

  // Pagination
  UserQueryBuilder limit(int count);
  UserQueryBuilder offset(int count);

  // Execution
  Future<List<User>> findAll();
  Future<User?> findFirst();
  Future<int> count();
  Future<int> deleteAll();
}
```

---

### `lib/generated/database_manager.dart`

Auto-generated (no trigger file needed). Aggregates all `@DbTable(auto: true)` tables in the project. Everything is embedded at build time — nothing is read from disk at runtime, so it works on devices and the web.

```dart
class DatabaseManager {
  static const int schemaVersion = 3;
  static const String defaultDatabaseName = 'my_app'; // database_name in native_sqlite_config.yaml

  static const tables = <String, String>{ 'users': UserSchema.createTableSql, ... };
  static List<String> get onCreateStatements => [...]; // tables (FK order) + indexes
  static List<String> get tableNames => ['users', 'orders'];

  // migrations[v] upgrades version v - 1 to v
  static const Map<int, List<String>> migrations = {
    2: ['ALTER TABLE users ADD COLUMN phone TEXT'],
    3: ['CREATE TABLE orders (...)', 'CREATE INDEX ...'],
  };

  // Run after every upgrade: creates any missing table or index
  static const List<String> ensureSchemaStatements = [...];

  static Future<void> init({String name = defaultDatabaseName, bool enableWAL = true, bool enableForeignKeys = true});
  static Future<void> close();
}
```

Call `await DatabaseManager.init()` at startup. The generated Kotlin and Swift
`DatabaseManager`s embed the same data, so the database is migrated identically
whichever side opens it first.

---

### `lib/generated/native_sqlite_schema.json`

The current schema, and — when the schema changed — the migration step to its
`schemaVersion`. Each version is also saved as
`lib/generated/schemas/native_sqlite_schema_vN.json`; these files are the
migration history, so **commit them** (CI and every developer must build from
the same history).

```json
{
  "schemaVersion": 3,
  "migrationFormat": 2,
  "schemas": [
    {
      "className": "User",
      "tableName": "users",
      "columns": [
        { "dartName": "phoneNumber", "name": "phone_number", "type": "TEXT", "nullable": true, "dartType": "String?" }
      ],
      "indexes": [{ "name": "idx_users_email", "columns": ["email"], "unique": false }]
    }
  ],
  "migrations": [
    { "tableName": "users", "sql": ["ALTER TABLE users ADD COLUMN phone_number TEXT"], "summary": "Added columns: phone_number" }
  ]
}
```

How changes are migrated:

| Change | Migration |
|--------|-----------|
| New table | `CREATE TABLE` + its indexes |
| New nullable column, or with a default | `ALTER TABLE ADD COLUMN` |
| New `NOT NULL` column without default | **Build error** (existing rows have no value) |
| Removed column, type/constraint/FK change, new `UNIQUE`/FK column | Table rebuild (copy shared columns, recreate indexes); removed data is logged as a warning |
| Index added/removed/changed | `CREATE INDEX` / `DROP INDEX` |
| Model removed | Table kept (warning) |

Snapshots written by older generator versions (Dart names instead of column
names, migrations that never ran) are corrected automatically without creating
a migration.

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

## Native Code Generation (`native_sqlite_config.yaml`)

To generate Kotlin/Swift helpers, add `native_sqlite_config.yaml` to your project root:

```yaml
native_sqlite:
  generate_native: true
  database_name: 'my_app'
  include_examples: true    # include usage comments in generated files
  native_type_prefix: 'App' # optional: AppUser, AppUserHelper, AppUserStatus

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

The `native_code` builder regenerates the files on every `build_runner` build;
`dart run native_sqlite_generator` does the same from the command line.
`native_type_prefix` defaults to empty and prefixes model-derived native
types only, avoiding clashes with types already in the Android/iOS app. Each
output folder contains a manifest; files from the prior manifest that are no
longer generated are removed only when they retain the generated-code marker.

### Generated Kotlin files

| File | Description |
|------|-------------|
| `UserSchema.kt` | Column constants, `CREATE_TABLE_SQL`, `INDEX_SQL` |
| `UserHelper.kt` | Typed `User` data class (`Instant`, `Duration`, `Uri`, enums) and CRUD/query helper |
| `UserStatus.kt` | One enum class per Dart enum used by a model |
| `DatabaseManager.kt` | `init(context)` — opens and migrates like `DatabaseManager.dart` |

### Generated Swift files

| File | Description |
|------|-------------|
| `UserSchema.swift` | Column constants, `createTableSql`, `indexSql` |
| `UserHelper.swift` | Typed `User` struct (`Date`, `TimeInterval`, `URL`, enums) and CRUD/query helper; row decoding throws on bad data |
| `UserStatus.swift` | One enum per Dart enum used by a model |
| `NativeSqliteGeneratedSupport.swift` | Row decoding shared by the helpers |
| `DatabaseManager.swift` | `initialize()` — opens and migrates like `DatabaseManager.dart` |

Fields with a `@UseConverter` or `@JsonField` are exposed as their stored
SQLite value (documented on the property). The files `import native_sqlite_ios`;
add `ios/Runner/Generated` to the Runner target once as a synchronized folder
(Xcode 16+), so new files are picked up automatically.

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

## Known Limitations

- Column renames are migrated as remove + add (the build warns that the column's data is dropped).
- The schema file path is fixed to `lib/generated/native_sqlite_schema.json`.
