# native_sqlite

A Flutter SQLite plugin with **code generation**, **type-safe queries**, and **native Kotlin/Swift integration**.

Write annotated Dart model classes and let the generator produce repositories, query builders, schema migrations, and native platform helpers — all without manual SQL.

---

## Package Ecosystem

```
native_sqllite/
├── native_sqlite/
│   ├── native_sqlite/               ← Main package  (add this to your app)
│   ├── native_sqlite_android/       ← Android (Kotlin) implementation
│   ├── native_sqlite_ios/           ← iOS (Swift) implementation
│   ├── native_sqlite_web/           ← Web (sqlite3 WASM) implementation
│   └── native_sqlite_platform_interface/ ← Platform abstraction layer
├── native_sqlite_annotations/       ← Annotation definitions
├── native_sqlite_generator/         ← build_runner code generator
└── native_sqlite_inspector/         ← DevTools-style database inspector
```

---

## Features

- **Declarative model mapping** — annotate any Dart class with `@DbTable` and get a full database layer generated
- **Type-safe query builder** — fluent, chainable API with per-column filter/sort methods (no stringly-typed queries)
- **Auto-generated CRUD repositories** — `insert`, `findById`, `findAll`, `update`, `delete`, `count`
- **Schema migrations** — JSON snapshot tracking, automatic SQL generation for common changes
- **Multi-platform** — Android, iOS, and Web with a unified Dart API
- **Native code generation** — Kotlin and Swift schema helpers for platform-side database access
- **WAL mode** — enabled by default for safe concurrent access from Flutter and native threads
- **Multi-database** — different tables can live in different database files
- **Freezed support** — works with `@freezed` immutable classes
- **Inspector** — web-based DevTools UI to browse and edit live database data

---

## Quick Start

### 1. Add dependencies

```yaml
# pubspec.yaml
dependencies:
  native_sqlite: ^1.0.0

dev_dependencies:
  native_sqlite_generator: ^1.0.0
  build_runner: ^2.4.0
```

### 2. Configure the generator

```yaml
# build.yaml
targets:
  $default:
    builders:
      native_sqlite_generator:table:
        options:
          default_database: 'my_app'
          # Optional: override where the schema JSON is written/read.
          # Defaults to lib/generated/native_sqlite_schema.json
          # schema_output_path: lib/generated/native_sqlite_schema.json
```

### 3. Define a model

```dart
import 'package:native_sqlite/native_sqlite.dart';

part 'user.table.dart';   // generated file

@DbTable(name: 'users', indexes: [['email'], ['created_at']])
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(nullable: false)
  final String name;

  @DbColumn(unique: true, nullable: false)
  final String email;

  @DbColumn(nullable: true)
  final String? phoneNumber;

  @DbColumn(nullable: false, defaultValue: '1')
  final bool isActive;

  @DbColumn(nullable: false)
  final DateTime createdAt;

  @Ignore()
  String? tempPassword;   // not stored in DB

  User({
    this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.isActive = true,
    DateTime? createdAt,
    this.tempPassword,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

### 4. Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `user.table.dart` containing `UserSchema`, `UserRepository`, and `UserQueryBuilder`.

### 5. Open the database and use it

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'generated/database_manager.dart';   // auto-generated

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database (auto-creates tables, runs migrations)
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

  // CRUD via generated repository
  final repo = UserRepository();

  final id = await repo.insert(
    User(name: 'Alice', email: 'alice@example.com'),
  );

  final user = await repo.findById(id);
  print(user?.name);  // Alice

  // Type-safe query builder
  final activeUsers = await UserQueryBuilder('my_app')
      .whereIsActiveEquals(true)
      .whereCreatedAtGreaterThan(DateTime(2024))
      .orderByNameAscending()
      .limit(20)
      .find();
}
```

---

## Annotation Reference

### `@DbTable`

Marks a class as a database table.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | class name → snake_case | SQL table name |
| `database` | `String?` | generator `default_database` | Database file this table belongs to |
| `indexes` | `List<List<String>>?` | `null` | Composite indexes — each inner list is one index |
| `auto` | `bool` | `true` | Include in auto-generated `DatabaseManager` |

```dart
@DbTable(
  name: 'orders',
  database: 'shop_db',
  indexes: [['user_id', 'status'], ['created_at']],
)
class Order { ... }
```

---

### `@PrimaryKey`

Marks a field as the primary key.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `autoIncrement` | `bool` | `false` | SQLite `AUTOINCREMENT` — use with `int?` fields |
| `useLocalUuid` | `bool` | `false` | Generate a UUID on insert — use with `String` fields |

```dart
@PrimaryKey(autoIncrement: true)
final int? id;

// or UUID primary key:
@PrimaryKey(useLocalUuid: true)
final String id;
```

---

### `@DbColumn`

Customises column mapping for a field. All parameters are optional.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | field name → snake_case | SQL column name |
| `nullable` | `bool?` | inferred from `Type?` | Override nullability |
| `unique` | `bool` | `false` | Add `UNIQUE` constraint |
| `defaultValue` | `String?` | `null` | SQL default expression (e.g. `'1'`, `"'unknown'"`) |
| `type` | `String?` | inferred | Override SQLite type (`'TEXT'`, `'INTEGER'`, `'REAL'`, `'BLOB'`) |
| `ignore` | `bool` | `false` | Exclude field from DB (same as `@Ignore`) |

```dart
@DbColumn(name: 'email_addr', unique: true, nullable: false)
final String email;

@DbColumn(defaultValue: '0', type: 'INTEGER')
final int score;
```

---

### `@ForeignKey`

Defines a foreign key relationship on a column.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `table` | `String` | required | Referenced table name |
| `column` | `String` | required | Referenced column name |
| `onDelete` | `String?` | `null` | Action: `'CASCADE'`, `'SET NULL'`, `'RESTRICT'`, `'NO ACTION'` |
| `onUpdate` | `String?` | `null` | Same options as `onDelete` |

```dart
@ForeignKey(table: 'users', column: 'id', onDelete: 'CASCADE')
@DbColumn(nullable: false)
final int userId;
```

---

### `@Index`

Creates a standalone index on one or more columns.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `columns` | `List<String>` | required | Columns to index |
| `name` | `String?` | auto-generated | Custom index name |
| `unique` | `bool` | `false` | Unique index |

```dart
@Index(columns: ['email'], unique: true)
@DbColumn()
final String email;
```

> **Tip:** For simple single-column indexes, use the `indexes` parameter on `@DbTable` instead.

---

### `@EnumField`

Controls how an enum field is stored in the database.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `type` | `EnumType` | `EnumType.ordinal` | Storage strategy |

**Storage strategies:**

| `EnumType` | Dart value | Stored as |
|------------|-----------|-----------|
| `ordinal` | `Status.active` (index 0) | `INTEGER` `0` |
| `name` | `Status.active` | `TEXT` `'active'` |
| `value` | (requires `@EnumValue`) | custom value |

```dart
enum Status { active, inactive, suspended }

@EnumField(type: EnumType.name)
@DbColumn()
final Status status;
```

---

### `@UseConverter`

Attaches a custom `TypeConverter` to a field.

```dart
class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();
  int toSql(Color value) => value.value;
  Color fromSql(int sqlValue) => Color(sqlValue);
}

@UseConverter(ColorConverter())
@DbColumn(type: 'INTEGER')
final Color backgroundColor;
```

---

### `@JsonField`

Stores a field as a JSON TEXT column. Supports `Map`, `List`, and any class with `toJson()`/`fromJson()`.

```dart
@JsonField()
@DbColumn(type: 'TEXT')
final Map<String, dynamic> metadata;

@JsonField()
@DbColumn(type: 'TEXT')
final Address? address;   // Address must have toJson()/fromJson()
```

---

### `@Ignore`

Excludes a field from code generation entirely.

```dart
@Ignore()
String? cachedDisplayName;
```

---

## Generated API

After `build_runner` runs, each `@DbTable` class gets three generated classes:

### `XxxSchema` — SQL constants

```dart
UserSchema.tableName        // 'users'
UserSchema.createTableSql   // full CREATE TABLE statement
UserSchema.indexSql         // list of CREATE INDEX statements
UserSchema.ID               // 'id'
UserSchema.NAME             // 'name'
UserSchema.EMAIL            // 'email'
// one constant per column
```

### `XxxRepository` — CRUD operations

```dart
final repo = UserRepository();            // uses default_database
final repo = UserRepository('other_db'); // explicit database

await repo.insert(user);           // returns int row ID
await repo.findById(1);            // returns User?
await repo.findAll();              // returns List<User>
await repo.update(user);           // returns rows affected
await repo.delete(1);              // returns rows deleted
await repo.deleteAll();            // returns rows deleted
await repo.count();                // returns int
await repo.query('SELECT ...');    // raw query, returns List<User>
```

### `XxxQueryBuilder` — Fluent type-safe queries

```dart
final results = await UserQueryBuilder('my_app')
    // per-column filters (generated based on your fields)
    .whereIdEquals(1)
    .whereNameContains('alice')
    .whereEmailEquals('alice@example.com')
    .whereIsActiveEquals(true)
    .whereCreatedAtGreaterThan(DateTime(2024))
    // sorting
    .orderByNameAscending()
    .orderByCreatedAtDescending()
    // pagination
    .limit(20)
    .offset(40)
    // execute
    .find();                  // List<User>

final user = await UserQueryBuilder('my_app')
    .whereEmailEquals('alice@example.com')
    .findOne();               // User?

final count = await UserQueryBuilder('my_app')
    .whereIsActiveEquals(false)
    .count();                 // int

await UserQueryBuilder('my_app')
    .whereCreatedAtLessThan(cutoff)
    .delete();                // int rows deleted
```

---

## Migration System

### How it works

1. `build_runner` generates a `native_sqlite_schema.json` snapshot after each build.
2. On the next build, the generator compares the new schema against the snapshot.
3. Changed tables produce SQL entries in `DatabaseManager.migrations`.
4. `AutoMigration.createConfig(...)` applies those entries automatically when `schemaVersion` increments.

### Simple migrations (column additions)

SQLite's `ALTER TABLE ADD COLUMN` is used when only nullable columns (or columns with defaults) are added:

```sql
ALTER TABLE users ADD COLUMN phone_number TEXT;
```

### Complex migrations (column removal, type change, rename)

SQLite does not support `DROP COLUMN` before 3.35 or column type changes, so the generator recreates the table:

```sql
CREATE TABLE users_new (...);
INSERT INTO users_new (id, name, email) SELECT id, name, email FROM users;
DROP TABLE users;
ALTER TABLE users_new RENAME TO users;
```

Foreign-key constraints (`REFERENCES … ON DELETE … ON UPDATE …`) defined via `@ForeignKey` are preserved through table recreation. `CHECK` constraints and `COLLATE` expressions are not yet carried over automatically.

### Custom migration logic

Pass `onCustomMigrate` to handle edge cases:

```dart
AutoMigration.createConfig(
  ...,
  onCustomMigrate: (dbName, oldVersion, newVersion) async {
    if (oldVersion < 3) {
      await NativeSqlite.execute(dbName, 'UPDATE users SET role = "user"');
    }
  },
);
```

### Native platform migrations (Kotlin/Swift)

After running `dart run native_sqlite_generator` the tool also generates:

- `SchemaVersionManager.kt / .swift` — reads and writes `PRAGMA user_version`
- `Migration_X_Y.kt / .swift` — stub classes with helper methods (`addColumn`, `renameTable`, `migrateTableData`) ready to be filled in

---

## CLI Tools

Run from your project root (where `pubspec.yaml` lives):

```bash
dart run native_sqlite_generator <command> [options]
```

| Command | Description |
|---------|-------------|
| `analyze` | Lint all `@DbTable` classes for missing PKs, naming issues, un-indexed FKs |
| `stats` | Print field-type distribution, constraint counts, and health metrics |
| `migrate` | Generate migration SQL between two schema snapshot files |
| `export` | Export all table schemas to a JSON or YAML file |
| `clean-cache` | Clear the build cache |
| `cache-stats` | Show cache hit/miss statistics |

### `analyze`

```bash
dart run native_sqlite_generator analyze
# Checks: missing @PrimaryKey, naming conventions, FK without index, unsupported types
```

### `stats`

```bash
dart run native_sqlite_generator stats
# Prints: table count, field type distribution, FK/index health, recommendations
```

### `migrate`

```bash
dart run native_sqlite_generator migrate \
  --from lib/generated/schemas/v1.schema.json \
  --to   lib/generated/schemas/v2.schema.json \
  --output migrations/001_v1_to_v2.sql
```

### `export`

```bash
dart run native_sqlite_generator export \
  --output docs/schema.json \
  --format json      # or: --format yaml
```

---

## Native Code Generation

To generate Kotlin/Swift helpers, add `native_sqlite_config.yaml` to your project root:

```yaml
native_sqlite:
  generate_native: true
  database_name: 'my_app'

  models:
    - 'lib/models/*.dart'

  android:
    enabled: true
    output_path: 'android/app/src/main/kotlin/com/example/myapp/generated'
    package: 'com.example.myapp.generated'
    generate_helpers: true

  ios:
    enabled: true
    output_path: 'ios/Runner/Generated'
    generate_helpers: true
```

Then run:

```bash
dart run native_sqlite_generator
```

Generated files include `UserSchema.kt`, `UserHelper.kt`, `SchemaVersionManager.kt`, and `Migration_X_Y.kt` (and Swift equivalents).

---

## Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Core CRUD | ✅ | ✅ | ✅ |
| WAL mode | ✅ | ✅ | ⚠️ Falls back to MEMORY journal mode (logged in debug builds) |
| Transactions | ✅ | ✅ | ✅ |
| Foreign keys | ✅ | ✅ | ✅ |
| `deleteDatabase` | ✅ | ✅ | ✅ Removes IndexedDB entry |
| Inspector schema panel | ✅ | ✅ | ✅ |
| Inspector edit/delete | ✅ any PK name | ✅ any PK name | ✅ any PK name |
| Native code gen | ✅ Kotlin | ✅ Swift | — |

---

## Database Inspector

When running in debug mode the plugin prints an Inspector URL to the console:

```
╔══════════════════════════════════════════════════════╗
║  Native SQLite Inspector is available at:            ║
║  http://dev-nesmin.github.io/native_sqllite/#/PORT/TOKEN ║
╚══════════════════════════════════════════════════════╝
```

Open the link in a browser to browse tables, run SQL queries, and edit/delete individual rows in your live app database.

---

## Advanced Examples

### Multi-database setup

```dart
@DbTable(name: 'users', database: 'auth_db')
class User { ... }

@DbTable(name: 'products', database: 'shop_db')
class Product { ... }
```

Each table uses its own database file. The repositories handle routing automatically.

### Freezed integration

```dart
@freezed
@DbTable(name: 'posts')
class Post with _$Post {
  const factory Post({
    @PrimaryKey(autoIncrement: true) int? id,
    @DbColumn(nullable: false) required String title,
    @DbColumn(nullable: true) String? body,
  }) = _Post;
}
```

### Custom type converter

```dart
class LatLngConverter extends TypeConverter<LatLng, String> {
  const LatLngConverter();
  String toSql(LatLng v) => '${v.lat},${v.lng}';
  LatLng fromSql(String s) {
    final parts = s.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }
}

@UseConverter(LatLngConverter())
@DbColumn(type: 'TEXT')
final LatLng location;
```

### Transactions

```dart
await NativeSqlite.transaction('my_app', [
  "INSERT INTO orders (user_id, total) VALUES (1, 99.99)",
  "UPDATE users SET order_count = order_count + 1 WHERE id = 1",
]);
```

---

## Known Limitations

- **Table-recreation migration** does not preserve `CHECK` constraints or `COLLATE` expressions (foreign keys and `ON DELETE`/`ON UPDATE` actions are now preserved).
- **Native migration stubs** (`Migration_X_Y.kt` / `.swift`) are generated but **intentionally blank** — you must implement the migration steps.
- **Web WAL mode** falls back to MEMORY journal mode; a `debugPrint` warning is emitted in debug builds.

See [MISSING_IMPLEMENTATIONS.md](MISSING_IMPLEMENTATIONS.md) for the complete historical issue log.
