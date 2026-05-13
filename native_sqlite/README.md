# native_sqlite

The runtime package for the native_sqlite Flutter plugin. Provides the main `NativeSqlite` API, `AutoMigration` helpers, and the DevTools Inspector connection.

> **This is a runtime package.** To generate type-safe repositories and query builders from your model classes, add `native_sqlite_generator` as a dev dependency.

---

## Installation

```yaml
dependencies:
  native_sqlite: ^1.0.0

dev_dependencies:
  native_sqlite_generator: ^1.0.0
  build_runner: ^2.4.0
```

---

## `NativeSqlite` API

All methods are static. The database name is always the first argument and corresponds to the `name` you pass to `open()`.

### Open / Close

```dart
// Open or create a database. Returns the absolute path to the file.
final path = await NativeSqlite.open(config: DatabaseConfig(...));

// Close the database.
await NativeSqlite.close('my_app');
```

### `DatabaseConfig`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `String` | required | Database identifier (also the file name) |
| `version` | `int` | required | Schema version — increment when schema changes |
| `onCreate` | `List<String>` | required | SQL statements to execute on first open |
| `onMigrateCallback` | `Future<List<String>> Function(int old, int new)?` | `null` | Called when version increases; return SQL to execute |
| `enableWAL` | `bool` | `true` | Enable Write-Ahead Logging for concurrent access |
| `enableForeignKeys` | `bool` | `true` | Enable `PRAGMA foreign_keys = ON` |

```dart
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_app',
    version: 2,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
      )
      ''',
    ],
    onMigrateCallback: (oldVersion, newVersion) async {
      if (oldVersion < 2) {
        return ['ALTER TABLE users ADD COLUMN phone TEXT'];
      }
      return [];
    },
  ),
);
```

### CRUD

```dart
// Execute DML / DDL — returns rows affected (0 for non-DML)
final affected = await NativeSqlite.execute(
  'my_app',
  'UPDATE users SET name = ? WHERE id = ?',
  ['Jane', 1],
);

// SELECT — returns QueryResult
final result = await NativeSqlite.query(
  'my_app',
  'SELECT * FROM users WHERE email = ?',
  ['alice@example.com'],
);
for (final row in result.toMapList()) {
  print(row['name']);
}

// INSERT — returns new row ID
final id = await NativeSqlite.insert('my_app', 'users', {
  'name': 'Alice',
  'email': 'alice@example.com',
});

// UPDATE — returns rows affected
final count = await NativeSqlite.update(
  'my_app', 'users',
  {'name': 'Alice Updated'},
  where: 'id = ?',
  whereArgs: [id],
);

// DELETE — returns rows deleted
final deleted = await NativeSqlite.delete(
  'my_app', 'users',
  where: 'id = ?',
  whereArgs: [id],
);
```

### Transactions

```dart
// All statements execute atomically — returns true on success
final ok = await NativeSqlite.transaction('my_app', [
  "INSERT INTO orders (user_id, total) VALUES (1, 50.00)",
  "UPDATE users SET order_count = order_count + 1 WHERE id = 1",
]);
```

### Utilities

```dart
// Absolute path to the database file (null if not opened yet)
final path = await NativeSqlite.getDatabasePath('my_app');

// Delete the database file (closes it first if open)
await NativeSqlite.deleteDatabase('my_app');
```

### `QueryResult`

```dart
final result = await NativeSqlite.query('my_app', 'SELECT * FROM users');

result.columns;        // List<String> — column names
result.rows;           // List<List<Object?>> — raw rows
result.toMapList();    // List<Map<String, Object?>> — convenient row maps
```

---

## `AutoMigration`

`AutoMigration` bridges the generated `DatabaseManager` with `NativeSqlite.open()`. Use it instead of constructing `DatabaseConfig` manually when you have a generated schema registry.

### `createConfig`

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'generated/database_manager.dart';

await NativeSqlite.open(
  config: AutoMigration.createConfig(
    name: DatabaseManager.databaseName,
    schemaVersion: DatabaseManager.schemaVersion,
    onCreateStatements: DatabaseManager.onCreateStatements,
    tables: DatabaseManager.tables,
    tableNames: DatabaseManager.tableNames,
    migrations: DatabaseManager.migrations,

    // Optional: drop tables removed from your schema
    dropRemovedTables: false,
    deletedTableNames: DatabaseManager.deletedTableNames,

    // Optional: run custom SQL after auto-migrations
    onCustomMigrate: (dbName, oldVersion, newVersion) async {
      if (oldVersion < 3) {
        await NativeSqlite.execute(dbName, 'UPDATE users SET role = "user"');
      }
    },
  ),
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String` | required | Database name |
| `schemaVersion` | `int` | required | Current schema version |
| `onCreateStatements` | `List<String>` | required | Statements for fresh install |
| `tables` | `Map<String, String>` | required | Table name → `CREATE TABLE` SQL |
| `tableNames` | `List<String>` | required | Ordered list of table names |
| `migrations` | `List<Map<String, dynamic>>` | required | Generated migration entries |
| `deletedTableNames` | `List<String>` | `[]` | Tables to drop when `dropRemovedTables` is true |
| `dropRemovedTables` | `bool` | `false` | Drop tables removed from schema on migrate |
| `enableWAL` | `bool` | `true` | WAL mode |
| `enableForeignKeys` | `bool` | `true` | Foreign key enforcement |
| `onCustomMigrate` | `Future<void> Function(String, int, int)?` | `null` | Custom migration hook |

### `detectNewTables` / `detectRemovedTables`

Use these after opening a database to reconcile the live schema with the expected schema:

```dart
final queryFn = (String sql) async {
  final result = await NativeSqlite.query('my_app', sql);
  return result.toMapList();
};

// Find tables present in schema but missing from the DB
final newStatements = await AutoMigration.detectNewTables(
  databaseName: 'my_app',
  tables: DatabaseManager.tables,
  tableNames: DatabaseManager.tableNames,
  queryFn: queryFn,
);
for (final sql in newStatements) {
  await NativeSqlite.execute('my_app', sql);
}

// Find tables present in the DB but removed from schema
final dropStatements = await AutoMigration.detectRemovedTables(
  tableNames: DatabaseManager.tableNames,
  queryFn: queryFn,
);
for (final sql in dropStatements) {
  await NativeSqlite.execute('my_app', sql);
}
```

---

## Database Inspector

The Inspector is automatically initialised when you call `NativeSqlite.open(...)`. In debug builds it prints a clickable URL to the console:

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║  Native SQLite Inspector is available at:                            ║
║  http://dev-nesmin.github.io/native_sqllite/#/PORT/TOKEN             ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```

Open the URL in a browser to:
- Browse all open databases and their tables
- View table columns, types, and indexes (full schema returned for any database)
- Paginate and search rows
- Execute raw SQL
- Edit and delete rows — works with any primary key column name, not just `id`

The Inspector is only active in **debug mode** (`kDebugMode`). No extensions are registered in release builds.
