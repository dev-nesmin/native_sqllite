# native_sqlite

The runtime package for the native_sqlite Flutter plugin. Provides the main `NativeSqlite` API, `AutoMigration` helpers, and the DevTools Inspector connection.

> **This is a runtime package.** To generate type-safe repositories and query builders from your model classes, add `native_sqlite_generator` as a dev dependency.

---

## Installation

```yaml
dependencies:
  native_sqlite: ^0.0.1

dev_dependencies:
  native_sqlite_generator: ^0.0.1
  build_runner: ^2.4.0
```

---

## `NativeSqlite` API

`NativeSqlite.open` returns an owned `NativeSqliteDatabase` handle. All SQL
operations are instance methods on that handle, which prevents accidentally
routing an operation to the wrong database.

### Open / Close

```dart
// Open or create a database.
final db = await NativeSqlite.open(DatabaseConfig(...));
print(db.path);
print(db.version);

// Releases exactly this handle's connection reference.
await db.close();
```

### `DatabaseConfig`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `String` | required | Database identifier/file stem: ASCII letters, digits, `_`, and `-` only |
| `version` | `int` | `1` | Schema version — increment when schema changes |
| `onCreate` | `List<String>?` | `null` | SQL statements to execute when the database is created |
| `migrations` | `Map<int, List<String>>?` | `null` | Versioned steps: `migrations[v]` upgrades version `v - 1` to `v` |
| `onUpgrade` | `List<String>?` | `null` | Statements run on every upgrade, after the applicable `migrations` |
| `onConfigure` | `List<String>?` | `null` | Single-statement PRAGMAs applied after opening/migration |
| `enableWAL` | `bool` | `true` | Request WAL on Android/iOS; web uses MEMORY journal mode |
| `enableForeignKeys` | `bool` | `true` | Enable `PRAGMA foreign_keys = ON` |
| `busyTimeout` | `int` | `5000` | Milliseconds SQLite waits for a busy database |
| `readOnly` | `bool` | `false` | Open an existing, version-matched database without write permission |
| `directory` | `String?` | `null` | Absolute native directory override; unsupported on web |
| `iosAppGroup` | `String?` | `null` | iOS App Group identifier for a shared container |

```dart
final db = await NativeSqlite.open(DatabaseConfig(
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
    migrations: {
      2: ['ALTER TABLE users ADD COLUMN phone TEXT'],
    },
  ),
);
```

When an existing database at version `old` is opened, every implementation
applies the same rules: steps `old + 1 .. version` run in order, then
`onUpgrade`, in one transaction with foreign keys disabled; the migration
fails (and is rolled back) if it leaves foreign key violations. Opening a
database whose version is newer than `version` throws.

`directory` and `iosAppGroup` are mutually exclusive. An App Group must be
enabled in the iOS application's entitlements; opening fails clearly when its
container is unavailable. Pass the same location to `getDatabasePath` or
`deleteDatabase` when addressing a custom-location database.

### CRUD

```dart
// Execute one DML / DDL statement — returns SQLite's affected-row count.
final affected = await db.execute(
  'UPDATE users SET name = ? WHERE id = ?',
  ['Jane', 1],
);

// SELECT — returns QueryResult
final result = await db.query(
  'SELECT * FROM users WHERE email = ?',
  ['alice@example.com'],
);
for (final row in result.toMapList()) {
  print(row['name']);
}

// INSERT — returns new row ID
final id = await db.insert('users', {
  'name': 'Alice',
  'email': 'alice@example.com',
});

// Raw INSERT — also returns the SQLite row ID
final rawId = await db.executeInsert(
  'INSERT INTO users (name, email) VALUES (?, ?)',
  ['Bob', 'bob@example.com'],
);

// UPDATE — returns rows affected
final count = await db.update(
  'users',
  {'name': 'Alice Updated'},
  where: 'id = ?',
  whereArgs: [id],
);

// DELETE — returns rows deleted
final deleted = await db.delete(
  'users',
  where: 'id = ?',
  whereArgs: [id],
);
```

### Transactions

```dart
final orderCount = await db.transaction((txn) async {
  await txn.execute(
    'INSERT INTO orders (user_id, total) VALUES (?, ?)',
    [1, 50.00],
  );
  await txn.update(
    'users',
    {'order_count': 1},
    where: 'id = ?',
    whereArgs: [1],
  );
  final result = await txn.query('SELECT COUNT(*) FROM orders');
  return result.rows.single.single as int;
});
```

The callback commits when it returns and rolls back if it throws. Other calls
on the same database wait until it finishes. Nested transactions are rejected.

### Batch

```dart
final batch = db.batch();
for (var i = 0; i < 10000; i++) {
  batch.execute('INSERT INTO events (value) VALUES (?)', [i]);
}
final results = await batch.commit();
```

The batch is one platform-channel call and one transaction. Each result matches
its operation (`int` for writes, `QueryResult` for queries).

### Reactive queries

```dart
final subscription = db
    .watch(
      'SELECT id, name FROM users ORDER BY name',
      const ['users'],
    )
    .listen((result) => print(result.toMapList()));

await subscription.cancel();
```

Writes made through the Dart API refresh matching watches immediately. Watches
also poll and emit only distinct results, so changes made through generated
Kotlin/Swift helpers or another SQLite connection are observed. Adjust
`pollInterval` when the default 500 ms native-change latency is unsuitable.

### Error handling

SQLite engine failures throw `NativeSqliteException` on every implementation.
It exposes `resultCode`, `extendedResultCode`, the statement shape in `sql`,
and helpers such as `isUniqueViolation`, `isNotNullViolation`, and
`isForeignKeyViolation`. Bound values are never included in the exception.

```dart
try {
  await db.insert('users', {'email': 'already-used@example.com'});
} on NativeSqliteException catch (error) {
  if (error.isUniqueViolation) {
    // Resolve the duplicate.
  }
}
```

### Utilities

```dart
// Absolute path and configured schema version are available on the handle.
final path = db.path;
final version = db.version;

// The path is deterministic even before the database is opened.
final futurePath = await NativeSqlite.getDatabasePath('my_app');
final exists = await NativeSqlite.databaseExists('my_app');
final openInThisIsolate = NativeSqlite.isOpen('my_app');

// Native custom directory, or use iosAppGroup on iOS.
final sharedPath = await NativeSqlite.getDatabasePath(
  'my_app',
  directory: '/absolute/shared/directory',
);

// Delete the database file (closes it first if open)
await NativeSqlite.deleteDatabase('my_app');

// Copy a complete SQLite file from Flutter assets when it is first needed.
final bundled = await NativeSqlite.openFromAsset(
  DatabaseConfig(name: 'catalog', readOnly: true, enableWAL: false),
  'assets/catalog.db',
);

// Release every handle owned by this isolate.
await NativeSqlite.closeAll();
```

### SQLite feature baseline

Android and iOS use the SQLite library bundled by the operating system; web
uses the SQLite WASM build supplied by the app. The supported SQL baseline is
SQLite 3.18 (Android API 26), so generated migrations use table rebuilds
instead of newer operations such as `DROP COLUMN`. Features introduced after
3.18—including `RETURNING`—must be guarded by the runtime value from
`SELECT sqlite_version()`. The example's Database Statistics screen displays
that value for the device currently running the app.

Windows and Linux use the Dart-only `package:sqlite3` FFI implementation.
Databases default to `%APPDATA%\native_sqlite` on Windows and the
`native_sqlite` folder under `$XDG_DATA_HOME` (or `$HOME/.local/share`) on
Linux. Native Kotlin and Swift generation remains Android/iOS-only.

### Testing your app

Host-side Flutter tests can use a real SQLite database without an emulator or
method-channel mocks. Import the separate testing library so the FFI backend is
not part of your normal application imports:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';

late NativeSqliteFfi sqliteBackend;

setUpAll(() {
  sqliteBackend = NativeSqliteTesting.useFfi();
});

tearDownAll(() {
  sqliteBackend.dispose();
});

test('stores a user', () async {
  final db = await NativeSqlite.open(
    DatabaseConfig(
      name: 'test',
      onCreate: ['CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)'],
    ),
  );
  final id = await db.insert('users', {'name': 'Ada'});
  expect(id, greaterThan(0));
  await db.close();
});
```

By default each installed backend owns a fresh system temporary directory.
Pass `directory:` to keep database files at a chosen test path.

### Background isolates

Capture the root token before spawning the isolate, then initialize Flutter's
background messenger and plugin registrant inside it. The inspector remains a
root-isolate service and is not registered a second time.

```dart
final token = ServicesBinding.rootIsolateToken!;
await Isolate.run(() async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  DartPluginRegistrant.ensureInitialized();
  final db = await NativeSqlite.open(DatabaseConfig(name: 'background'));
  await db.execute('INSERT INTO events (message) VALUES (?)', ['synced']);
  await db.close();
});
```

Import `dart:isolate`, `dart:ui` (for `DartPluginRegistrant`), and
`package:flutter/services.dart`. If initialization is omitted,
`NativeSqlite.open` reports these exact setup calls.

### `QueryResult`

```dart
final result = await db.query('SELECT * FROM users');

result.columns;        // List<String> — column names
result.rows;           // List<List<Object?>> — raw rows
result.toMapList();    // List<Map<String, Object?>> — convenient row maps
```

---

## `AutoMigration`

`AutoMigration` builds the `DatabaseConfig` used by the generated
`DatabaseManager`. You normally just call `DatabaseManager.init()`; use
`createConfig` directly only when opening the database yourself.

### `createConfig`

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'generated/database_manager.dart';

final db = await NativeSqlite.open(AutoMigration.createConfig(
    name: DatabaseManager.defaultDatabaseName,
    schemaVersion: DatabaseManager.schemaVersion,
    onCreateStatements: DatabaseManager.onCreateStatements,
    migrations: DatabaseManager.migrations,
    ensureSchemaStatements: DatabaseManager.ensureSchemaStatements,
  ),
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String` | required | Database name |
| `schemaVersion` | `int` | required | Current schema version |
| `onCreateStatements` | `List<String>` | required | Statements for a fresh install |
| `migrations` | `Map<int, List<String>>` | `{}` | Generated versioned steps |
| `ensureSchemaStatements` | `List<String>` | `[]` | Idempotent `CREATE ... IF NOT EXISTS` run after every upgrade |
| `enableWAL` | `bool` | `true` | WAL mode |
| `enableForeignKeys` | `bool` | `true` | Foreign key enforcement |

For data migrations the generator can't express, add a step yourself by
opening with a `DatabaseConfig` whose `migrations` include your SQL for that
version.

---

## Database Inspector

The Inspector is a Flutter DevTools extension bundled with this package. It is
automatically initialised on the root isolate when you call
`NativeSqlite.open(...)` in a debug build. The console prints only
`Open DevTools → native_sqlite`; it never prints VM-service credentials.

Disable registration or just its banner before opening a database:

```dart
InspectorConnect.enabled = false;
// Or keep the inspector enabled but silence its console banner:
InspectorConnect.printBanner = false;
```

For a build-wide kill switch, pass
`--dart-define=NATIVE_SQLITE_INSPECTOR=false`.

Open Flutter DevTools from VS Code, Android Studio/IntelliJ, or a browser,
enable `native_sqlite` in the **Extensions** menu, and select its tab. You can
also check this project-level preference into your app:

```yaml
# devtools_options.yaml
extensions:
  - native_sqlite: true
```

The extension can browse tables and views, inspect columns and indexes, export
JSON, execute SQL, and edit/delete rows. Rowid tables use their hidden rowid;
`WITHOUT ROWID` tables use the full primary-key tuple. SQL writes are opt-in,
destructive statements require confirmation, and query results are capped at
1,000 rows with a visible truncation indicator.

The Inspector is only active in **debug mode** (`kDebugMode`). No extensions
are registered in profile or release builds. Data travels only over the local
DevTools DDS/VM-service connection; no hosted inspector receives it. A DevTools
connection has full debug control of your application, so enable extensions
only from packages you trust.

If the tab is missing, confirm the app opened a database, check the DevTools
**Extensions** menu, and restart the app plus DevTools after dependency
upgrades. A reconnect banner appears while hot restart replaces the main
isolate.
