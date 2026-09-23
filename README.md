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
import 'package:flutter/widgets.dart';
import 'generated/database_manager.dart';   // auto-generated

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Creates the tables on first launch and applies pending migrations on
  // upgrade (database name comes from native_sqlite_config.yaml).
  await DatabaseManager.init();

  // CRUD via generated repository
  final repo = UserRepository(DatabaseManager.currentDatabase);

  final id = await repo.insert(
    User(name: 'Alice', email: 'alice@example.com'),
  );

  final user = await repo.findById(id);
  print(user?.name);  // Alice

  // Type-safe query builder
  final activeUsers = await UserQueryBuilder(DatabaseManager.currentDatabase)
      .isActiveIsTrue()
      .createdAtAfter(DateTime(2024))
      .sortByNameAsc()
      .limit(20)
      .findAll();
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

1. Every build writes the current schema to `lib/generated/native_sqlite_schema.json`.
   When a table changes, the schema version increases and a versioned snapshot
   `lib/generated/schemas/native_sqlite_schema_vN.json` records the **step** from
   version `N-1` to `N`. Commit these files — they are the migration history.
2. The generated `DatabaseManager` (Dart, Kotlin and Swift) embeds the schema
   version, the create statements and every step as `migrations[N]`.
3. When a database is opened, the platform (Android, iOS or web) runs only the
   steps between the stored version and the current one, in order, in **one
   transaction** with foreign keys disabled, verifies `PRAGMA foreign_key_check`,
   and only then bumps the version. Any failure rolls everything back.
4. Dart and native code use the same generated steps, so it makes no
   difference which side opens the database first after an app update.
   Opening a database that is newer than the app (a downgrade) fails.

### Column additions

`ALTER TABLE ADD COLUMN` is used when every new column is nullable or has a
default (and isn't `UNIQUE`, a primary key or a foreign key):

```sql
ALTER TABLE users ADD COLUMN phone_number TEXT
```

A new `NOT NULL` column **without** a default fails the build with an
explanation, because existing rows would have no value for it.

### Other changes (removal, type/constraint change, unique, foreign keys)

The table is rebuilt with SQLite's recommended procedure; shared columns are
copied and the table's indexes are recreated:

```sql
CREATE TABLE users_new (...);
INSERT INTO users_new (id, name, email) SELECT id, name, email FROM users;
DROP TABLE users;
ALTER TABLE users_new RENAME TO users;
CREATE INDEX idx_users_email ON users (email);
```

Foreign keys are disabled during the migration, so rebuilding a parent table
never cascade-deletes child rows. The build logs a warning when data is
dropped (removed columns; a renamed column is treated as removed + added).

### Indexes and removed models

Added, removed or changed indexes are migrated with `CREATE INDEX` /
`DROP INDEX`. When a model is deleted its table is **kept** (with its data) and
the build logs a warning.

### Snapshots from older generator versions

Earlier versions recorded Dart field names (`userId`) instead of the real
column names (`user_id`) and their migrations were never executed. The builder
corrects such snapshots in place — without creating a migration — and ignores
their old migration SQL.

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

The `native_code` builder regenerates these files on every `build_runner` build
(or run `dart run native_sqlite_generator`). Per model you get `XxxSchema` and
`XxxHelper` (typed data class/struct and CRUD helper), plus one file per enum
and a `DatabaseManager` that opens and migrates the database exactly like the
Dart one:

```kotlin
// Android (e.g. in a WorkManager worker)
DatabaseManager.init(context)
val users = UserHelper(DatabaseManager.currentDatabase)
val id = users.insert(User(name = "Ada", email = "ada@example.com", age = 36, isActive = true, createdAt = Instant.now()))
```

```swift
// iOS (e.g. in a BGTaskScheduler task)
try DatabaseManager.shared.initialize()
let users = UserHelper(databaseName: try DatabaseManager.shared.currentDatabase)
let id = try users.insert(User(name: "Ada", email: "ada@example.com", age: 36, isActive: true, createdAt: Date()))
```

Dart types map to `Instant`/`Date`, `Duration`/`TimeInterval`, `Uri`/`URL` and
generated enums; fields using a `TypeConverter` or `@JsonField` are exposed as
their stored SQLite value.

**iOS:** add the output folder to the Runner target once as a *synchronized
folder* (Xcode 16+: drag `ios/Runner/Generated` into the Runner group and
choose "Create folders"). Files the generator adds or removes later are then
picked up automatically.

---

## Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Core CRUD | ✅ | ✅ | ✅ |
| WAL mode | ✅ | ✅ | ⚠️ Falls back to MEMORY journal mode (logged in debug builds) |
| Transactions | ✅ | ✅ | ✅ |
| Foreign keys | ✅ | ✅ | ✅ |
| Persistence | ✅ | ✅ | ✅ IndexedDB (requires `web/sqlite3.wasm`) |
| Versioned migrations | ✅ | ✅ | ✅ |
| `deleteDatabase` | ✅ | ✅ | ✅ |
| Inspector schema panel | ✅ | ✅ | ✅ |
| Inspector edit/delete | ✅ any PK name | ✅ any PK name | ✅ any PK name |
| Native code gen | ✅ Kotlin | ✅ Swift (CocoaPods and Swift Package Manager) | — |

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

- **Table rebuilds** don't carry over `CHECK` constraints or `COLLATE` expressions (not supported by the annotations either).
- **Column renames** are migrated as remove + add, so the column's data is dropped (the build warns). Rename data manually if needed.
- **Web** has no WAL mode (MEMORY journal instead) and supports **one tab per database**: each tab loads the database into memory, so two tabs writing to the same database can overwrite each other's changes.
