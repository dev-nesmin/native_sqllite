# 01 — Architecture and invariants

How native_sqlite works today (commit `64d1dca`) and the rules a change must
not break. Read [00-agent-operating-manual.md](00-agent-operating-manual.md)
first.

---

## 1. Product in one paragraph

native_sqlite is a federated Flutter plugin plus a build_runner code
generator. Its differentiator: **one SQLite database shared by Dart and by
native code** (Kotlin on Android, Swift on iOS — e.g. WorkManager jobs,
background tasks, widgets, extensions) with **typed, generated APIs on all
three sides** and **one migration history** that every side applies
identically. Web is supported through sqlite3 compiled to WebAssembly with
IndexedDB storage. A "Database Inspector" can browse a running debug app's
database — today a hosted web app; **decided (D-03): it moves into Flutter
DevTools as an extension** (INS-02).

---

## 2. Runtime architecture

```
Flutter app (Dart)
  NativeSqlite (static API)  ──►  NativeSqlitePlatform.instance
  DatabaseManager (generated)          │
  XxxRepository / XxxQueryBuilder      ├─ Android: MethodChannel → NativeSqlitePlugin.kt → NativeSqliteManager.Instance
  (generated)                          ├─ iOS:     MethodChannel → NativeSqlitePlugin.swift → NativeSqliteManager.shared
                                       └─ Web:     NativeSqliteWeb (Dart) → WasmSqlite3 + IndexedDbFileSystem

Native code (same process)
  Kotlin: DatabaseManager.init(context) / XxxHelper  ──►  NativeSqliteManager.Instance   (same singleton the plugin uses)
  Swift:  DatabaseManager.shared.initialize() / XxxHelper ─► NativeSqliteManager.shared  (same singleton the plugin uses)
```

- The plugin and native code share **one manager singleton per process**, so
  they share open connections. Native `DatabaseManager` init reuses a
  connection Flutter already opened.
- Databases are keyed by **name**. File locations:
  Android `context.getDatabasePath("<name>.db")` (app `databases/`);
  iOS `Library/Application Support/NativeSqlite/<sanitized name>.db`;
  web `/<name>.db` inside the IndexedDB database `native_sqlite`.
- WAL is on by default (Android via
  `SQLiteOpenHelper.setWriteAheadLoggingEnabled`, iOS via
  `PRAGMA journal_mode=WAL`); web uses MEMORY journal mode.

### 2.1 Opening and migrating (identical on Android, iOS, web)

`DatabaseConfig` (Dart, Kotlin, Swift — keep them in sync):
`name`, `version`, `onCreate`, `migrations` (`Map<int, List<String>>`:
`migrations[v]` upgrades `v-1 → v`), `onUpgrade` (statements run after the
steps on every upgrade), `enableWAL`, `enableForeignKeys`.

Open algorithm:

1. Read `PRAGMA user_version` (`current`).
2. `current > version` → fail ("downgrades are not supported").
3. `current == 0` → run `onCreate`, set `user_version = version`.
4. `0 < current < version` → run `migrations[current+1 … version]` in order,
   then `onUpgrade`.
5. Steps 3–4 run **in one transaction with foreign keys OFF**, then
   `PRAGMA foreign_key_check` must return no rows, then `user_version` is set
   and the transaction commits. Any error rolls everything back and the open
   fails.
6. Only after that are foreign keys turned on (Android `onOpen` →
   `setForeignKeyConstraintsEnabled(true)`; iOS/web `PRAGMA foreign_keys=ON`).

Implementations: `DatabaseConfig.upgradeStatements()` (Dart
`native_sqlite_platform_interface/lib/src/models/database_config.dart`),
Kotlin `DatabaseConfig.kt` + `NativeSqliteManager.DatabaseHelper`, Swift
`DatabaseConfig.swift` + `NativeSqliteManager.openDatabase`, web
`NativeSqliteWeb.openDatabase/_migrate`.

### 2.2 Values across the boundary

| SQLite | Dart | Kotlin (manager) | Swift (manager) | Channel note |
|---|---|---|---|---|
| NULL | `null` | `null` | `nil` | iOS receives `NSNull`; plugin converts |
| INTEGER | `int` | `Long` | `Int64` | `bool` is stored as 1/0 |
| REAL | `double` | `Double` | `Double` | iOS: `NSNumber` classified by CF type |
| TEXT | `String` | `String` | `String` | |
| BLOB | `Uint8List` | `ByteArray` | `Data` | iOS: `FlutterStandardTypedData` ↔ `Data` |

Unsupported argument types must raise an error — never be stored as a
string description (that bug existed on iOS; don't reintroduce it).

---

## 3. Code generation

### 3.1 Builders (`native_sqlite_generator/build.yaml`)

| Builder | Input | Output |
|---|---|---|
| `migration` (`SchemaTrackingBuilder`) | all `@DbTable` classes in `lib/` | `lib/generated/native_sqlite_schema.json` and, when the schema changed, `lib/generated/schemas/native_sqlite_schema_vN.json` (written with `dart:io`) |
| `schema_registry` (`SchemaRegistryBuilder`) | tables + schema JSON + versioned snapshots | `lib/generated/database_manager.dart` |
| `native_code` (`post_build_hook.dart` → `NativeCodeGenerator`) | schema JSON + `native_sqlite_config.yaml` | Kotlin/Swift files into the app's `android/` / `ios/` (written with `dart:io`), stamp file `lib/generated/.native_sqlite_stamp` |
| `table` (`TableGenerator`) | each model file | `<model>.table.dart` part: `XxxSchema`, `XxxQueryBuilder`, `XxxRepository` |

### 3.2 Schema snapshot and migrations

- A snapshot column records `dartName`, real SQL `name`, `type`,
  constraints, FK, `dartType`, enum metadata (`enumType`, `enumValues`);
  indexes record `name`, `columns`, `unique`.
- Change detection compares **freshly computed** structural hashes
  (`TableSchemaSnapshot.computeHash`, sha256) of the previous and current
  snapshots — never the stored hash string.
- When anything changed, `schemaVersion` increments and the file records the
  step to that version in `migrations` (with `"migrationFormat": 2`).
  `MigrationSqlGenerator` decides per table: `CREATE TABLE` (+ indexes) for
  new tables; `ALTER TABLE ADD COLUMN` when every new column is
  nullable/defaulted and not PK/UNIQUE/FK; otherwise a table rebuild
  (create `<t>_new`, copy shared columns, drop, rename, recreate indexes);
  index diff for index-only changes. A new NOT NULL column without default
  is a **build error**. Removed models keep their tables (warning).
- `LegacySnapshotCorrection` repairs snapshots from older generator
  versions (Dart names recorded instead of SQL names) without creating a
  migration, and snapshots without `migrationFormat: 2` never contribute SQL.
- `MigrationSteps.load` collects `steps[v]` from all versioned files (plus
  the current file); `MigrationSteps.ensureSchema` builds idempotent
  `CREATE … IF NOT EXISTS` repair statements used as `onUpgrade`.
- Every CREATE statement for native code and migrations comes from
  `SchemaSql` (`lib/src/sql/schema_sql.dart`) and is identical to the Dart
  `XxxSchema.createTableSql` (verified for all example tables).

### 3.3 Native code generation

- Type mapping lives in `lib/src/native/native_column.dart` (`NativeKind`):
  `int→Long/Int64`, `double|num→Double`, `bool→Boolean/Bool` (stored 1/0,
  read `== 1`), `DateTime→Instant/Date` (epoch ms), `Duration→Duration/TimeInterval`
  (ms), `Uri→android.net.Uri/URL`, `Uint8List→ByteArray/Data`, enums → generated
  Kotlin/Swift enums honoring `EnumType.name` vs ordinal; converter/JSON/custom
  types → raw stored value (documented on the property).
- Generated per model: `XxxSchema` + `XxxHelper` (typed data class/struct +
  CRUD/query helper); per enum: one file; per app: `DatabaseManager` (Kotlin
  `object`, Swift `final class` with `shared`) embedding `SCHEMA_VERSION`,
  create statements, `migrations`, `ensureSchemaStatements`; Swift also
  `NativeSqliteGeneratedSupport.swift` (throwing row decoding).
- `database_name` in `native_sqlite_config.yaml` is the default database
  name for Dart and native managers (`NativeSqliteConfig.defaultDatabaseName`
  = `app_database` when unset). The schema version always comes from the
  schema JSON.

---

## 4. Invariants (never break these)

1. **Cross-platform parity of open/upgrade semantics** (§2.1). A change on
   one platform must be made on all three, with a test on each.
2. **Dart ↔ native schema parity:** native CREATE/INDEX SQL must equal the
   Dart schema SQL, and native value encoding must equal Dart's
   (`TypeUtils.generateSerializeExpression` /
   `generateDeserializeExpression`).
3. **Migration history is append-only** and committed. Never regenerate old
   `vN` files, never reuse a version number.
4. **Foreign keys off during create/upgrade**, `foreign_key_check` before
   commit, transactional create/upgrade.
5. **Naming options identical across builders** (`table_name_case`,
   `column_name_case`); `SchemaRegistryBuilder` fails the build if the
   snapshot and the tables disagree.
6. **Generated code is never edited by hand** and must compile warning-free
   (Kotlin, Swift, Dart).
7. **Native managers stay framework-free:** `NativeSqliteManager` (Kotlin,
   Swift) must not depend on Flutter types; the plugin classes adapt channel
   values.
8. **No silent data changes:** unsupported values raise errors; destructive
   migrations are either build errors or logged warnings.

---

## 5. State at `64d1dca` (what already works)

Verified by tests and by running on an iOS simulator, an Android emulator
(API 36) and Chrome:

- Flutter 3.47.5; Android AGP 9 / Gradle 9.3.1 / built-in Kotlin.
- Versioned migrations on all platforms (unit tests against real SQLite,
  end-to-end v1→v2 upgrade test, integration tests incl. downgrade rejection
  and FK-violation rollback).
- Typed Kotlin/Swift generation incl. enums; Swift decoding throws instead of
  crashing; generated Swift compiles into the example through the
  synchronized folder.
- iOS plugin: CocoaPods + Swift Package Manager; binding of all value types
  verified; deadlocks fixed; transactional create/upgrade.
- Web: compiles and runs (wasm + IndexedDB), migrations and FK rollback
  verified in headless Chrome.
- Example app: Android/iOS/web targets; native channel demo implemented with
  generated helpers on both platforms; integration test suite.

Known publishing blockers found by `flutter pub publish --dry-run` (details
and tasks in [04-release-and-publishing.md](04-release-and-publishing.md)):
no `LICENSE` in any package (hard error), `pub_semver` imported but not
declared in the generator (hard error), no `CHANGELOG.md`, internal
dependencies declared as `any`, generator tests import `test` without a
dev dependency.
