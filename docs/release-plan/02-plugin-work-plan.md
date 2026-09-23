# 02 — Plugin work plan

All work on the published packages: runtime and platform code, public API,
code generator, annotations, inspector, platform expansion, plugin-level
tests and documentation. The example app has its own plan
([03](03-example-app-and-testing.md)); packaging and CI are in
[04](04-release-and-publishing.md).

Read [00-agent-operating-manual.md](00-agent-operating-manual.md) and
[01-architecture-and-invariants.md](01-architecture-and-invariants.md)
first. Every finding below was verified against the code at `64d1dca`
(file:line references). Line numbers drift — search for the quoted code if a
line doesn't match.

**Priorities:** P0 = must be done before the first publish (bug, crash, data
risk, or an API that can't change later) · P1 = needed for a good first
release · P2 = before 1.0 · P3 = later.

**Path shortcuts:**
`AK` = `native_sqlite/native_sqlite_android/android/src/main/kotlin/dev/nesmin/native_sqlite/`,
`IS` = `native_sqlite/native_sqlite_ios/ios/native_sqlite_ios/Sources/native_sqlite_ios/`,
`WEB` = `native_sqlite/native_sqlite_web/lib/native_sqlite_web.dart`,
`NS` = `native_sqlite/native_sqlite/lib/src/`,
`PI` = `native_sqlite/native_sqlite_platform_interface/lib/src/`,
`GEN` = `native_sqlite_generator/lib/src/`.

---

## A. Tooling

### TOOL-01 · P1 · Helper scripts for agents and contributors

- Add `tool/devices.sh` (the detection snippet from the operating manual
  §5.1; prints `IOS_SIM=… ANDROID_EMU=… WEB_CHROME=…`, never physical
  devices) and `tool/test_generator.sh` (runs the generator tests with the
  direct runner, resolving the `test` package path from
  `.dart_tool/package_config.json` with `jq`).
- **Acceptance:** `eval "$(tool/devices.sh)"` sets the variables for the
  open simulator/emulator; `tool/test_generator.sh` runs all generator tests.
  Update §4.3/§5.1 of the manual to use the scripts.

---

## B. Runtime correctness (Android, iOS, web)

These are bugs in shipped behavior. Each fix needs a cross-platform
integration test (see TST-01) because the three implementations must agree.

### RT-01 · P0 · Run all SQLite work off the platform main thread

- **Evidence:** Android channel created without a task queue
  (`AK/NativeSqlitePlugin.kt:24`), so `onMethodCall`, `writableDatabase`
  and migrations run on the main looper. iOS channel created without
  `taskQueue:` (`IS/NativeSqlitePlugin.swift:14`) and the manager blocks the
  caller with `queue.sync` (`IS/NativeSqliteManager.swift`). In Flutter 3.47
  the Dart UI thread and the platform thread are merged on Android/iOS, so
  every query, fsync and first-launch migration blocks frame rendering; long
  migrations risk ANRs / watchdog kills.
- **Do:**
  - Android: one single-thread executor per database (SQLite sessions and
    `BEGIN` state are thread-bound; a generic background TaskQueue is not
    pinned to one thread). Post results back to the main thread for
    `Result`. Reference design: sqflite's database worker pool.
  - iOS: create the channel with
    `registrar.messenger().makeBackgroundTaskQueue()` and `taskQueue:`;
    never call `queue.sync` from the main thread; keep the per-database
    serial queue for writes.
  - Native callers (generated helpers) stay synchronous but must not be
    called on the main thread — document it and add a debug assertion.
- **Acceptance:** T20 in [03 §5.2](03-example-app-and-testing.md#52-test-matrix)
  — frames keep rendering (no dropped-frame burst) during a 2-second
  `WITH RECURSIVE` query on the open Android emulator and iOS simulator;
  all existing integration tests still pass.
- **Depends on:** RT-08 (handle lifecycle), API-02 (transaction ids).

### RT-02 · P0 · Android: bind arguments with their real types

- **Evidence:** `AK/NativeSqliteManager.kt:137`
  `rawQuery(sql, arguments?.map { it?.toString() })`, `:195` (update
  whereArgs), `:211` (delete whereArgs), `:274` (`else -> put(key,
  value.toString())` stores unknown types as strings). Effects: `true` binds
  as `'true'`, `Uint8List` as `"[B@…"`, `null` in query args throws,
  comparisons without column affinity (`HAVING COUNT(*) > ?`,
  `json_extract(…) = ?`) silently return wrong rows. The generated
  `xEqualTo(null)` hits the null case.
- **Do:** typed binding everywhere: `rawQueryWithFactory` with a cursor
  factory that binds `Long/Double/String/ByteArray/null`, and
  `compileStatement` + typed binds for update/delete/execute. Unsupported
  types throw `IllegalArgumentException` (never `toString()`).
- **Acceptance:** T18 — `query('SELECT typeof(?),typeof(?),typeof(?),typeof(?), ? = 1', [1, 1.5, null, Uint8List(1), true])`
  returns identical rows on Android, iOS and web.

### RT-03 · P0 · Correct `execute` return values; expose the insert rowid

- **Evidence:** Android computes the row count with a separate
  `compileStatement("SELECT changes()")` (`AK/NativeSqliteManager.kt:124`);
  in WAL mode `SQLiteDatabase` routes read-only statements to a reader
  connection, so `changes()` is per-connection and likely 0; the statement
  is never closed; the `startsWith("INSERT"|"UPDATE"|"DELETE")` check
  (`:121-123`) misses `WITH … UPDATE`, `REPLACE`, leading comments. iOS
  and web return a stale `sqlite3_changes` after DDL/SELECT.
- **Do:** Android `compileStatement(sql).use { bind; executeUpdateDelete() }`
  for DML; iOS/web report changes only if `total_changes()` moved; add
  `executeInsert()` (or make `insert`/raw INSERT return the rowid) on all
  platforms.
- **Acceptance:** T19 — `execute('UPDATE …')` returns the affected count,
  `execute('CREATE TABLE …')` returns 0, raw INSERT returns the rowid, on all
  three platforms (write the test first; it should fail on Android today).

### RT-04 · P0 · iOS: surface step errors, don't crash on empty SQL

- **Evidence:** `while sqlite3_step(statement) == SQLITE_ROW`
  (`IS/NativeSqliteManager.swift:228`, `:513`) never checks for `SQLITE_DONE`,
  so BUSY/CONSTRAINT/CORRUPT/JSON errors become empty or partial results
  reported as success; `getDatabaseVersion` returns 0 on error (would re-run
  `onCreate`); `statement!` crashes when SQL is empty/comment-only (prepare
  returns OK with a NULL statement).
- **Do:** check the final step code and throw; treat a nil statement as an
  error; `getDatabaseVersion` throws on error.
- **Acceptance:** `query("SELECT json_extract('x','$.a')")` throws on iOS
  (like Android/web); `query('', [])` throws instead of crashing.

### RT-05 · P0 · Typed, consistent errors

- **Evidence:** today:

  | Case | Android | iOS | Web |
  |---|---|---|---|
  | SQL error | `PlatformException('NATIVE_SQLITE_ERROR')`, code only in message | `PlatformException`, no code | plain `Exception('Failed…')` |
  | insert constraint violation | returns **-1** (`SQLiteDatabase.insert` swallows it, logs the values) | throws | throws |
  | `transaction` failure | returns `false`, error discarded (`AK/NativeSqliteManager.kt:228`) | throws | throws |

- **Do:** `NativeSqliteException` in the platform interface
  (`resultCode`, `extendedResultCode`, `message`, `sql` without bound
  values); native sides send `details: {code, extendedCode}`; Android uses
  `insertOrThrow` and never logs values; web maps `SqliteException`;
  `transaction` becomes `Future<void>` that throws. Export a small set of
  helpers (`isUniqueViolation`, `isForeignKeyViolation`, …).
- **Acceptance:** T11 — UNIQUE, NOT NULL, FK and syntax errors produce the
  same exception type and codes on all three platforms; no values in logs.

### RT-06 · P0 · One statement per SQL string, everywhere

- **Evidence:** web `db.execute(sql)` runs every statement in a string
  (`WEB` `execute`, `_migrate`), but with arguments only the first; Android
  `execSQL` and iOS `sqlite3_prepare_v2(…, nil)` silently run only the
  first. A two-statement `onCreate` entry creates two tables on web and one
  on mobile — and still sets the version.
- **Do:** reject multi-statement strings consistently (iOS: non-empty tail →
  error; web: `prepare(checkNoTail: true)`; Android: Dart-side check or
  `SQLiteStatement` rejection). Document it in `DatabaseConfig`.
- **Acceptance:** a two-statement string throws the same error on all
  platforms (test).

### RT-07 · P0 · Android: don't close every database when an engine detaches

- **Evidence:** `AK/NativeSqlitePlugin.kt:125-128` calls
  `databaseManager.closeAll()` in `onDetachedFromEngine` on the process-wide
  singleton. Destroying any engine (background engines of FCM/workmanager
  plugins, `FlutterEngineGroup`, activity recreation) closes databases other
  engines and native code are using.
- **Do:** remove the call (iOS never closes on detach).
- **Acceptance:** two-engine test: destroy one engine, the other keeps
  querying; native helper still works.

### RT-08 · P0 · Opening an already-open database must not close it; fix iOS handle races

- **Evidence:** `open` closes and reopens an already-open name on all
  platforms (`AK/NativeSqliteManager.kt:53-55`, iOS `openDatabase`
  `closeDatabaseLocked`, `WEB` `openDatabase` → `closeDatabase`). The
  generated Dart `DatabaseManager.init()` always calls `open`, so when native
  code opened the database first (the background use case), Dart closes it
  under native code. On iOS each operation resolves the handle in one
  `queue.sync` block and uses it in another → use-after-free window if a
  close runs in between; `getDatabase(name:) -> OpaquePointer` exposes the
  same risk publicly.
- **Do:** opening an open name returns the existing connection (reference
  counted; config must match — if it doesn't, throw a clear error instead of
  silently reopening); resolve and use the handle inside the same serialized
  block; replace the public `getDatabase` with `withConnection { db in … }`;
  use `sqlite3_close_v2`.
- **Acceptance:** T5 (native opens first, Dart `init` reuses the connection);
  an iOS stress test with native writes during repeated Dart opens under
  Thread Sanitizer shows no races.

### RT-09 · P1 · Android correctness details

- Rows > 2 MB fail to read (CursorWindow): use `SQLiteCursor.setWindow` with a
  larger window on API 28+ or chunked reads; document the limit.
- `execute` of row-returning statements (`SELECT`, `PRAGMA x = …` that
  returns a row) throws; iOS/web accept → align (run and discard rows).
- `whereArgs` without `where` → "Too many bind arguments"; align with the
  other platforms (error everywhere).
- `delete(where: '')` deletes all rows on Android/web but is a syntax error on
  iOS → treat empty `where` as no clause everywhere, document.
- `appContext` is `lateinit` (`AK/NativeSqliteManager.kt:33`): native code
  that uses the manager before `initialize` crashes with an unclear error →
  clear exception message; generated `DatabaseManager.init(context)` already
  initializes.
- Onboard `onCreate` parity: run `PRAGMA foreign_key_check` after
  `onCreate` too (iOS/web do).
- Fix the KDoc sample (`AK/NativeSqliteManager.kt:20`) — it doesn't compile.

### RT-10 · P1 · iOS correctness details

- Set `sqlite3_busy_timeout` (e.g. 5000 ms; Android defaults to 2.5 s) —
  otherwise any second connection (extension, widget, other library) gets
  `SQLITE_BUSY` immediately.
- `enableWAL: false` doesn't switch an existing WAL file back
  (`PRAGMA journal_mode=DELETE`).
- `deleteDatabase` also removes `-journal`.
- Close the handle when `openDatabase` fails before registration.
- Name sanitizing maps `a.b` and `ab` to the same file and `""` to `.db` →
  validate names instead (RT-12).
- Zero-length BLOB reads back as `nil` and TEXT with a NUL byte is truncated
  (`getColumnValue`) → use `sqlite3_column_bytes` for both.
- Doc comment claims Application Support is backed up to iCloud "only when
  the app opts in" — wrong (it is backed up by default); set
  `isExcludedFromBackup` if that's intended, or fix the comment.

### RT-11 · P1 · Web correctness details

- Writes performed through `query` (`INSERT … RETURNING`,
  `PRAGMA user_version = …`) are not flushed to IndexedDB → flush after any
  statement that changed `total_changes()`.
- Default `enableWAL: true` silently becomes MEMORY journaling and prints a
  debug notice on every open → print once; document durability.
- `dispose()` is deprecated in `sqlite3` 3.x → `close()` when upgrading (D-08).
- P3: move SQLite into a web worker with OPFS for durability and multi-tab.

### RT-12 · P1 · Database names and locations

- Validate names in Dart (`^[A-Za-z0-9_-]+$`, not empty) before calling the
  platform; today Android uses raw names (a leading `/` becomes an absolute
  path, allowing `deleteDatabase('/…/x')` to delete arbitrary `x.db` files),
  iOS sanitizes, web uses them raw. `'json_demo.db'` becomes
  `json_demo.db.db` (Android) vs `json_demodb.db` (iOS).
- Add an optional directory/path option to `DatabaseConfig`, and on iOS an
  App Group container option so app extensions and widgets can share the
  database (the generated Swift docs already mention extensions).
- Consider `:memory:`/in-memory databases for tests (see API-06).

### RT-13 · P1 · SQLite versions per platform

- Android and iOS use the system SQLite (API 26 ≈ 3.18, API 30 ≈ 3.28,
  iOS 13 ≈ 3.28); web bundles a recent build. Features like
  `ALTER TABLE … RENAME COLUMN` (3.25+), `DROP COLUMN` (3.35+), `RETURNING`
  (3.35+), JSON functions differ.
- **Do:** document the minimum SQLite per supported OS version; make sure
  generated migrations only use features available on the minimum (the
  table-rebuild path already avoids `DROP COLUMN`); add `sqlite_version()` to
  the example status card.

### RT-14 · P1 · `DatabaseConfig` / `QueryResult` value semantics

- `version` must be ≥ 1 (today iOS/web store 0 and re-run `onCreate` on every
  open; Android throws) → validate in the constructor (also name).
- `QueryResult ==` ignores row contents (`PI/models/query_result.dart:47-58`)
  and a test asserts that bug (`query_result_test.dart:96-111`);
  `DatabaseConfig ==` ignores statements/migrations → fix both or remove
  `==` overrides.

### RT-15 · P0 · Android build requirements (decision D-07)

- **Evidence:** plugin `minSdk = 26`
  (`native_sqlite/native_sqlite_android/android/build.gradle.kts:31`) —
  higher than Flutter 3.47's default (24), so a fresh app fails the manifest
  merge; nothing in the plugin needs API 26 (only the *generated* Kotlin uses
  `java.time`). The plugin uses AGP built-in Kotlin (no KGP), which requires
  apps on AGP 9 / Flutter ≥ 3.44.
- **Do (per D-07):** plugin `minSdk = 24` (or 21); document that apps
  generating native Kotlin helpers need `minSdk 26` or core library
  desugaring (or make the generator emit `Long` epoch fields when a
  `native_min_sdk < 26` option is set). Document the AGP 9 requirement, or
  support AGP 8 apps by applying the Kotlin Gradle plugin conditionally.
- **Acceptance:** a fresh `flutter create` app (minSdk 24) adds the plugin and
  builds; README states the requirements.

---

## C. Public API (settle before the first publish)

**Decided (D-09): replace the name-string API with a database handle,
interactive transactions and batch before the first publish.** The packages
are unpublished, so the API can still change freely; changing it after 0.1.0
would mean breaking releases. API-01…API-04 are therefore P0 and the
generator, native helpers and example must be migrated in the same release.

### API-01 · P0 · Database handle instead of name strings

- **Evidence:** every `NativeSqlite` method takes a database name string
  (`NS/native_sqlite.dart:52-273`); no handle, no interactive transaction,
  no batch.
- **Do:** `final db = await NativeSqlite.open(config)` returns
  `NativeSqliteDatabase` with instance methods (`execute`, `query`,
  `insert`, `update`, `delete`, `transaction`, `batch`, `close`, `path`,
  `version`). Keep static convenience functions only if they add value
  (e.g. `NativeSqlite.deleteDatabase(name)`, `databaseExists`).
  Generated repositories/query builders take a `NativeSqliteDatabase` (or
  resolve it from `DatabaseManager`), not a name.
- **Acceptance:** API reviewed by the human; generator and example migrated;
  all tests green.

### API-02 · P0 · Interactive transactions and batch with arguments

- **Evidence:** only `transaction(List<String>)` exists
  (`NS/native_sqlite.dart:242`): no bound arguments (users interpolate values
  → injection risk, the README examples do this), no reads inside the
  transaction, platform-dependent failure result.
- **Do:** `db.transaction((txn) async { … })` with commit/rollback on
  exception, implemented with a transaction id on the channel (sqflite model)
  and a per-database lock in Dart so other calls wait; nested transactions →
  savepoints or a clear error. `db.batch()` collects parameterized
  statements and executes them in one channel call inside one transaction,
  returning per-statement results. Native helpers get the same (Kotlin
  `transaction {}` / Swift `transaction { }`).
- **Acceptance:** T10 (commit/rollback parity incl. failure mid-way) on all
  targets; a batch of 10,000 inserts is one channel call.
- **Depends on:** RT-01 (thread-bound transactions on Android), API-01.

### API-03 · P0 · Narrow and clean the exports

- **Evidence:** `native_sqlite.dart` re-exports the whole platform interface
  (including `NativeSqlitePlatform` with a settable `instance`, wire-format
  `toMap/fromMap`) and all annotations. `AutoMigration.detectRemovedTables`
  returns `DROP TABLE` for every table not in the list — including
  `android_metadata`, FTS shadow tables and tables created by native code —
  and `detectNewTables` ignores its `databaseName` parameter and throws on a
  mismatch (`NS/auto_migration.dart`); neither is used by the generator or
  example.
- **Do:** `export … show DatabaseConfig, QueryResult, …`; mark wire methods
  `@internal`; delete both `detect*` helpers (and their README section);
  resolve name clashes of generic names (`Index`, `TypeConverter`,
  `DatabaseConfig`) — see D-16.
- **Acceptance:** `dart doc` of `native_sqlite` shows only intended API;
  example and generated code compile.

### API-04 · P0 · Consistent contracts

- All operations return `Future<void>` or a value and **throw** on failure
  (no `bool` success flags, no `-1` sentinels); `getDatabasePath` behaves the
  same on all platforms; `open(config)` parameter style matches the rest.
- Rename `onUpgrade` (it runs after the steps on every upgrade) to something
  explicit, e.g. `afterMigrate`, or document it prominently.
- Update the doc comments that are wrong today ("0 for non-DML",
  "returns true/false", "null if not opened").

### API-05 · P1 · Background isolates

- Works only after `BackgroundIsolateBinaryMessenger.ensureInitialized(token)`
  and `DartPluginRegistrant.ensureInitialized()`; otherwise a misleading
  `StateError` (`NS/native_sqlite.dart:55-63`). Inspector registers again
  per isolate.
- **Do:** improve the error message (say exactly which call is missing),
  document the setup, add an integration test using `Isolate.run`, register
  the inspector only in the root isolate.

### API-06 · P1 · Real SQLite backend for `flutter test` (host)

- A `NativeSqlitePlatform` implementation on `package:sqlite3` FFI (share the
  logic of the web implementation, which already uses `CommonDatabase`), e.g.
  `NativeSqliteTesting.useFfi()` in a `native_sqlite_testing` package or a
  `testing.dart` library of `native_sqlite`.
- Enables fast host tests for users and for this repo (T1, T2, T10, T11, T14
  on host). Also the base for desktop support (PLT-02).
- **Acceptance:** example host tests run against real SQLite without a
  device; README section "Testing your app".

### API-07 · P2 · Change notifications / reactive queries

- `db.watch(sql, tables)` / table-change stream. Must include changes made by
  native code (the USP): use `sqlite3_update_hook`/`PRAGMA data_version`
  polling on the connection, forwarded through an EventChannel.

### API-08 · P2 · Smaller API gaps

- `insert` conflict algorithm / upsert; `databaseExists`; `isOpen`;
  `closeAll`; read-only open; open from a prepopulated asset;
  `onConfigure`/PRAGMA hooks; busy timeout option.

### API-09 · P3 · Encryption

- Optional SQLCipher variant (separate implementation packages).

---

## D. Code generator

### GEN-01 · P0 · Generate correct code for real-world model shapes

- **Evidence:** `GEN/analyzer/table_analyzer.dart:138-146` iterates
  `element.fields`, skipping only static/ignored fields. The analyzer creates
  synthetic fields for getters/setters → `String get displayName` and
  `@override int get hashCode` become columns (`display_name`, `hash_code`)
  and constructor arguments that don't exist → **generated code doesn't
  compile**. Private fields become named arguments `_secret:`; inherited
  fields are ignored (a `required super.createdAt` parameter is never
  passed); `late` fields and fields with initializers become columns.
  `_fromMap` assumes an unnamed constructor with named parameters for every
  column (`GEN/code_gen/repository_generator.dart:267-279`, duplicated in
  `query_builder_generator.dart:507-516`).
- **Do:** only non-synthetic instance fields, including inherited ones;
  map columns to the actual constructor parameters (named or positional,
  `super.` parameters); spanned `InvalidGenerationSourceError` when a column
  has no matching parameter or a field is private without `@Ignore`; emit
  `_fromMap` once.
- **Acceptance:** golden tests (GEN-24) for: getter, `hashCode` override,
  private field, inherited fields, positional constructor, `late` field,
  initialized field — each either generates compiling code or fails with a
  clear, located error.

### GEN-02 · P0 · Watch mode deletes `database_manager.dart`

- **Evidence:** `GEN/generators/schema_registry_builder.dart:21,35-36` —
  `_hasRun` makes the builder skip on the second build of a watch/serve
  session; build_runner deletes the step's previous output before re-running
  it, so `lib/generated/database_manager.dart` disappears.
- **Do:** remove `_hasRun`.
- **Acceptance:** `build_runner watch`: edit a model twice; the file exists and
  is updated after each build.

### GEN-03 · P0 · Quote SQL identifiers everywhere

- **Evidence:** identifiers are never quoted: `schema_generator.dart:50,74`,
  `sql/schema_sql.dart`, `repository_generator.dart:101,149,167,233`,
  `query_builder_generator.dart:454,501`,
  `migration/migration_sql_generator.dart`, native SQL, and map keys passed
  to insert/update. `class Order` → table `order` → `CREATE TABLE order (` is
  a syntax error (also `group`, `index`, …).
- **Do:** one quoting helper (`"name"` with inner `"` doubled) used by every
  SQL producer (Dart, native, migrations) and the runtime helpers
  (insert/update/delete build SQL from map keys on each platform — see also
  SEC note in RT-02/RT-12). The schema hash must **not** change (it's built on
  names, not SQL text) — verify no version bump happens in the example.
- **Acceptance:** model `class Order` without `name:` builds and round-trips
  (T1); example regenerated with no new schema version; native/Dart SQL
  parity check still equal.

### GEN-04 · P0 · UUID primary keys

- **Evidence:** `repository_generator.dart:93-99` emits
  `final id = entity.id ?? _generateUuid();` followed by
  `final id = await NativeSqlite.insert(…)` in the same scope (doesn't
  compile); then returns `id as String` (the int rowid); `Random` needs
  `dart:math`, which a part file can't import;
  `test/generators/primary_key_test.dart:132-162` asserts the broken code;
  native helpers never generate UUIDs; a TEXT primary key accepts NULL.
- **Do:** separate local for the generated key; UUID generation from a helper
  exported by `package:native_sqlite` (no user imports needed); `NOT NULL` on
  non-integer primary keys (SchemaSql and SchemaGenerator); generate UUIDs in
  Kotlin (`UUID.randomUUID()`) and Swift (`UUID().uuidString`) helpers;
  decide whether the Dart field may be non-nullable (docs show `final String
  id`; the analyzer requires nullable — make both consistent).
- **Acceptance:** example `Note` model (EX-11) with UUID PK round-trips from
  Dart and from native code.

### GEN-05 · P0 · Database names: one setting; multi-database decision (D-18)

- **Evidence:** repositories default to `@DbTable(database:)` →
  `build.yaml` `default_database` → `'default_app'`
  (`table_analyzer.dart:79-82`); `DatabaseManager` opens
  `native_sqlite_config.yaml` `database_name` → `'app_database'`
  (`schema_registry_builder.dart`, `config.dart:16`) and creates **every**
  table in that one database; the snapshot has no database field, so
  migrations and native managers assume one database. With no config,
  `UserRepository()` targets `default_app` while `DatabaseManager.init()`
  opens `app_database` → runtime "Database 'default_app' is not open".
  README claims "the repositories handle routing automatically".
- **Do:** one source for the default name used by analyzer, registry and
  native generator. Then per D-18: either reject `@DbTable(database:)` in
  0.1.0 with a clear error (recommended), or implement per-database managers
  (group tables by database, one version chain per database, one native
  manager per database). With API-01, repositories take the database handle
  and no longer need a name at all.
- **Acceptance:** with and without config, repositories and `DatabaseManager`
  use the same database; `database:` either works end to end or fails the
  build with a message.

### GEN-06 · P0 · Explicit, hermetic migration workflow (decision D-19)

- **Evidence:** the migration builder writes history with `dart:io`
  relative to the current directory (`migration/schema_tracking_builder.dart`),
  the registry and native builder read config/history with `dart:io`
  (`config.dart`, `migration/migration_steps.dart`), so: building from the
  workspace root (`build_runner build --workspace`) finds no history → schema
  version restarts at 1 → installed apps fail with "downgrades are not
  supported"; editing config/history doesn't trigger rebuilds; **every
  intermediate save in watch mode that changes a model creates a new schema
  version and migration step**; history lives under `lib/generated/`, which
  teams commonly gitignore.
- **Do (recommended option of D-19):**
  - History moves to a dedicated folder at the package root (e.g.
    `native_sqlite/schemas/`), read through `buildStep` as declared inputs
    (check build_runner's default `sources`; if the folder isn't included,
    document the required `targets: $default: sources:` entry or use a folder
    that is).
  - The build **never** creates versions. If the models differ from the
    latest snapshot, the build fails with: "Schema changed. Run `dart run
    native_sqlite_generator migrations create` to record version N+1."
    An opt-in `auto_version: true` keeps today's behavior for prototyping.
  - CLI: `migrations create` (writes `vN.json` with the step from
    `MigrationSqlGenerator`), `migrations verify` (history integrity, steps
    reproduce the current schema on real SQLite), `migrations sql --from
    --to` (print steps).
  - Migrate the example's existing `lib/generated/schemas/…v1.json` into the
    new folder (the legacy correction code must keep working for old files).
- **Acceptance:** watch mode with repeated model edits creates no versions;
  `migrations create` + build produces the same Dart/Kotlin/Swift steps as
  today; `--workspace` builds from the repo root produce identical output.

### GEN-07 · P0 · Deterministic output (no timestamps, no churn)

- **Evidence:** "Generated on" header in `.table.dart` (`include_timestamp`
  defaults to true), `generatedAt`/`deletedAt` in schema files,
  `lib/generated/.native_sqlite_stamp`; every build rewrites all native files
  (Gradle/Xcode rebuild); git history has "update generated timestamps"
  commits.
- **Do:** remove timestamps (or default `include_timestamp: false`); drop the
  informational `previousSchemas` block from snapshots; write native files
  only when content changed; replace the stamp with a content hash or remove
  it.
- **Acceptance:** two consecutive builds produce zero git diff; CI job
  `codegen-up-to-date` (REL-11) can pass.

### GEN-08 · P0 · Fail loudly instead of generating wrong code

- If the schema JSON is missing/unreadable the registry still writes
  `schemaVersion = 1` (→ downgrade crash on installed apps) → fail the build.
- Native generation failures are `log.warning` (`post_build_hook.dart:63-66`)
  → fail the build.
- Analysis errors are downgraded to warnings/FINE logs
  (`schema_registry_builder.dart:88-94`) → errors.
- The native generator logs through `Logger('NativeSqliteGenerator')`, which
  nothing listens to inside build_runner → use `log` from `package:build`.
- Errors thrown as `StateError` without source spans (index errors, snapshot
  mismatch, `MigrationException`) → `InvalidGenerationSourceError(element:,
  todo:)` everywhere.

### GEN-09 · P0 · Composite primary keys: reject now

- Each `@PrimaryKey` column gets its own inline `PRIMARY KEY`
  (`schema_generator.dart:76-81`, `schema_sql.dart`) → SQLite error "table has
  more than one primary key"; repositories use only the first key. Tables
  without a primary key: native helpers use the first column for
  update/delete → can modify many rows.
- **Do:** build error for more than one `@PrimaryKey` (P2: implement
  table-level `PRIMARY KEY(a, b)` with composite-key APIs); don't generate
  id-based helpers when there is no primary key (or require one).

### GEN-10 · P1 · Index API matches its documentation

- `@DbTable(indexes:)` requires Dart field names; SQL names throw a bare
  `StateError` (`table_analyzer.dart:487-495`) — and the **root README Quick
  Start uses SQL names (`['created_at']`), so it fails to build**; same in the
  annotations README. `@Index` is read only on the class
  (`table_analyzer.dart:513`) but documented on fields, where it's silently
  ignored. `DbTable.indexes` can't express unique indexes.
- **Do:** accept Dart **or** SQL names (or raise a spanned error suggesting
  the right name); restrict `@Index` to classes with `@Target` from
  `package:meta` (or support field-level); fix all docs.

### GEN-11 · P1 · Enums

- `EnumType.value` / `@EnumValue` are documented but silently stored as
  ordinals (`table_analyzer.dart:412-434`, codecs in `helpers/type_utils.dart`,
  `query_builder_generator.dart:363-369`) → implement (value type from the
  `@EnumValue` constants, INTEGER or TEXT column) or remove and fail the
  build.
- Ordinal storage + reordering/removing constants silently corrupts data; the
  schema hash ignores `enumValues` → detect changes of ordinal enums between
  snapshots and fail (or require a migration). Default storage: D-17.

### GEN-12 · P1 · Type converters

- The column's SQL type comes from the field's Dart type instead of the
  converter's storage type `S` in `TypeConverter<D, S>`
  (`table_analyzer.dart:302-315`) — an int converter produces a TEXT column
  and `as String` reads that don't compile.
- The converter is always emitted as `const ${name}()`
  (`table_analyzer.dart:447-454`): constructor arguments, named constructors,
  generic arguments and import prefixes are dropped.
- **Do:** read `S` from the converter's supertype (`allSupertypes`); rebuild
  the constant from `ConstantReader.revive()` including arguments and prefix;
  BLOB converters shouldn't require users to import `dart:typed_data`.

### GEN-13 · P1 · Value codecs

- `DateTime` reads back as local time and loses microseconds
  (`DateTime.fromMillisecondsSinceEpoch(x)` in `type_utils.dart:171-175`) →
  decision D-20 (UTC preservation / storage format); Kotlin/Swift are already
  instant-based.
- `@DbColumn(type:)` changes only the declaration, not the codec (DateTime +
  `TEXT` stores a string; `NUMERIC` on double reads back as int) → align
  codec with declared type or reject incompatible combinations.
- Unknown SQL type names (VARCHAR, BOOLEAN, DATETIME) silently become TEXT →
  error or documented mapping.
- JSON fields: `Map<String, int>` read with an invalid cast; `List<Map>`,
  `Set`, `List<DateTime>`, `List<T?>` generate calls that don't compile;
  `@JsonField List<int>` becomes a BLOB → fix the JSON codec generation
  (decode to `Map<String, dynamic>`/`List<dynamic>` then convert) with tests
  per shape.
- Column nullability (`DbColumn.nullable`) and Dart nullability are decided
  separately → contradictions become build errors.
- Unknown custom types silently become TEXT with an `as Foo` cast → require a
  converter or `@JsonField`, else build error.

### GEN-14 · P1 · Query builder fixes

- `xEqualTo(null)` produces `= NULL` (never matches) → `IS NULL`.
- `offset()` without `limit()` is a syntax error → `LIMIT -1 OFFSET n`.
- LIKE input isn't escaped (`%`, `_` act as wildcards) → escape + `ESCAPE '\'`.
- Only one sort key is kept → support several (`thenBy…`).
- `findFirst` mutates the builder's limit → no side effects.
- Auto-increment primary keys get no filters → add them.
- `toPascalCase('userID')` → `UseriD` (method names like `sortByUseriDAsc`)
  → fix acronym handling (and the four duplicate snake_case implementations,
  GEN-22).
- Add a public `toSql()`/`debugSql` accessor (the example playground shows it).
- Native helpers `findWhere`, `deleteWhere`, `updatePartial`, `max/min/avg/sum`
  interpolate caller strings into SQL → document as trusted-input only or
  validate column names against the schema.

### GEN-15 · P1 · No imports forced on users by part files

- `.table.dart` is a `part of` the model, so it can't import; users must add
  `dart:convert` (JSON), `dart:math` (UUID), `dart:typed_data` (BLOB
  converters) themselves. → route these through helpers exported by
  `package:native_sqlite` (e.g. `NativeSqliteCodec.jsonEncode`), or fail with
  a message naming the missing import.

### GEN-16 · P1 · `@DbTable(auto: false)` applies everywhere

- Skipped by the registry, but still migrated, still in
  `ensureSchemaStatements` and native `onCreate` → database differs depending
  on who opens it first → filter in the migration builder and native output.

### GEN-17 · P1 · Migration gaps

- `ALTER TABLE ADD COLUMN` with a non-constant default (`CURRENT_TIMESTAMP`,
  `(expr)`) fails on devices → route such columns to the rebuild path
  (`MigrationSqlGenerator._canAddColumn`).
- Changing enum storage (ordinal → name) copies raw values unchanged → error
  or conversion step.
- Renames: add `@DbColumn(renamedFrom: 'old')` / `@DbTable(renamedFrom:)` →
  generate `RENAME` (respecting RT-13 minimum SQLite) or copy mapping in the
  rebuild.
- Custom steps: allow hand-written SQL per version merged into the generated
  step (e.g. `native_sqlite/schemas/v3.after.sql`), shipped to Dart and native.
- Two classes with the same table name are silently merged; duplicate column
  names aren't detected → build errors.

### GEN-18 · P1 · Native output hygiene

- Stale Kotlin/Swift files of removed/renamed models are never deleted (only
  the old `SchemaVersionManager`) → track generated files in a manifest in the
  output folder and delete the ones no longer generated.
- Member-name collisions: Kotlin constants vs `TABLE_NAME`,
  `CREATE_TABLE_SQL`, `INDEX_SQL`; Swift `tableName`, `createTableSql`,
  `indexSql` → rename generated members or detect collisions.
- Unprefixed public types (`User`, `Order`, `Priority`) in the app module can
  clash with app types → config option `native_type_prefix` (default none)
  and document.
- The Kotlin/Swift "multi-isolate" singleton API (`getInstance(isolateId)`,
  `cleanupIsolate`) means nothing on the native side → remove.
- The "Generated from:" header path is a guess → use the real source path.
- Native helper `findWhere`/aggregates: see GEN-14.

### GEN-19 · P2 · Builder scope and performance

- Both `$lib$` builders resolve every library in `lib/` on any change →
  per-library intermediate JSON (`build_to: cache`) + aggregate builders that
  only read JSON.
- All four builders use `auto_apply: dependents` → every package depending
  on the generator gets `lib/generated/` (incl. a `…_v0.json`) → aggregate
  builders only for the root package (or opt-in).

### GEN-20 · P1 · Configuration surface

- Read but useless: `enable_cached_builds` (cache never works, GEN-21);
  never read: `output_directory`, `output_path`, `schema_output_path`
  (documented!), `generate_helpers`, `class_visibility`, `custom_imports`;
  `format: false` has no effect (source_gen formats anyway; our formatter
  hard-codes language version 3.6).
- `generate_as_part_file` switches to `.g.dart`, which isn't in
  `build_extensions` and collides with json_serializable/freezed.
- Naming options must be repeated for three builders or the build fails →
  one source of options (declared config file read via `buildStep`, or
  `global_options` with YAML anchors — documented).
- `native_sqlite_config.yaml`: `models` parsed but unused; the `pubspec.yaml`
  fallback matches any `native_sqlite:` line (even the dependency); an empty
  file crashes; values not validated.
- **Do:** delete dead options, validate the rest, one documented config.

### GEN-21 · P1 · Remove the build cache

- `GEN/cache/build_cache.dart` can never hit (`canRead` of a same-phase
  output is always false, `table_generator.dart:63-67`); if it did, it would
  return a file with a duplicated header; the key ignores generator version
  and options. → delete the cache, its option and the `clean-cache` /
  `cache-stats` CLI commands; remove the `crypto` md5 use tied to it.

### GEN-22 · P1 · Dead code, duplication, leftovers

- Unused: `generators/schema_registry_generator.dart` (457 lines),
  `helpers/schema_persistence.dart`, `errors/generator_errors.dart` (never
  thrown; links to a wrong repo), `bin/organize_schemas.dart` (legacy, still
  an executable), `StatisticsGenerator.generateSummary`,
  `CodeFormatter.formatMultiple`, `GeneratorError.requireNonNull`,
  `TableInfo.hasForeignKeys`/`nonAutoIncrementColumns`, empty `test_output/`.
- `SchemaComparator` + its 22 tests only serve the broken CLI `migrate`.
- Four different snake_case implementations (NamingConventions,
  `schema_registry_builder.dart`, `native_kotlin_generator.dart`,
  `native_swift_generator.dart`; Kotlin turns `userID` into `USER_I_D`) → one.
- `IndexInfo.generateSql` and `SchemaGenerator` table SQL duplicate
  `SchemaSql` → use `SchemaSql` for Dart too (single source of truth).
- `nativeCodeBuilder` defined twice (`builder.dart:61`,
  `post_build_hook.dart:95`).
- Stale/AI comments: `repository_generator.dart:74-75,125-128`,
  `build.yaml:7`, `builder.dart:45-53`, `table_analyzer.dart:48,116`.

### GEN-23 · P1 · CLI (decision D-21)

- **Evidence:** args parsed before the logger is attached → every usage
  error exits 1 with no message (incl. `-v` after the command, as the README
  documents); unknown commands fall through to the default (native
  generation), which spawns `build_runner build --delete-conflicting-outputs`
  (removed flag); `export` looks for `@Table/@Column/@Unique` (don't exist) →
  always "No tables found"; `migrate` reads `json['tables']` (the builder
  writes `schemas`), uses a different diff engine and emits nested `BEGIN
  TRANSACTION`; `analyze` false positives (freezed, enums, Duration, Uri,
  num), suggests field-level `@Index`, reports offsets as lines, exits 0 on
  errors; `stats` counts field-level `@Index` (always 0); help links
  `github.com/your_repo`.
- **Do (recommended):** `CommandRunner` with: `generate` (native),
  `migrations create|verify|sql` (GEN-06); errors to stderr, exit code 64 for
  usage errors; delete `export`, `migrate`, `analyze`, `stats` and cache
  commands (or rebuild them on the real analyzer pipeline later).

### GEN-24 · P1 · Tests that prove generated code works

- **Evidence:** builder tests use a hand-written mock of the annotations
  (`test/utils/annotations.dart`) that has drifted from the real API (no
  `auto`, no `ignore`, positional ForeignKey/Index, no EnumField `type`,
  different UseConverter/TypeConverter) → converter, enum-by-name, ignore
  and FK paths are never exercised; assertions are `contains()` on text; the
  UUID test locks in non-compiling code. Not tested: migration/registry/native
  builders, native file writing, analyzer edge cases, multi-DB, DateTime,
  CLI, Kotlin/Swift compile.
- **Do:** use the real annotations sources in `testBuilder`
  (`readAllSourcesFromFilesystem` or load package files); compile check of
  generated Dart (resolve the output with the analyzer, zero errors); golden
  files per model shape; end-to-end on real SQLite (generate → run the SQL →
  round-trip); builder tests for migration/registry/native; Kotlin/Swift
  compile smoke tests in CI (`kotlinc`/Gradle and `swiftc -typecheck` against
  the plugin module, as done manually during development).

### GEN-25 · P1 · Logging and generated runtime noise

- Emoji log lines, `print` in builders (`table_generator.dart:35-85`,
  `build_cache.dart`, `code_formatter.dart:32`).
- Generated runtime prints `debugPrint('✅ DatabaseManager initialized')`
  and a `❌` message in all modes → remove or `kDebugMode` + opt-out; native
  managers print similarly (`print`/`Log.d`).

### GEN-26 · P1 · Public library surface of the generator

- `lib/native_sqlite_generator.dart` exports `TableGenerator` whose
  constructor takes a non-exported `GeneratorOptions` → a builder package
  should expose only `builder.dart` (and CLI via `bin/`).

---

## E. Annotations

### ANN-01 · P0 · Docs that break users' builds

- Field-level `@Index` documented but ignored (make it class-only with
  `@Target(TargetKind.classType)` from `package:meta`, or implement).
- `indexes:` examples use SQL names (fail) — fixed by GEN-10.
- UUID example uses non-null `String id` (rejected) — fixed by GEN-04.
- `@Column` / `DatabaseSchemaRegistry` / `DatabaseInitializer` references;
  `database: 'app.db'` contradicts "name without extension"; "defaults to
  field name" (real default: snake_case); `Color.value` (deprecated).
- "Must be combined with `@DbColumn`" isn't true.
- Converter requirements undocumented: const no-arg constructor (until
  GEN-12), null handling; `@JsonField` needs `dart:convert` (until GEN-15).

### ANN-02 · P1 · API shape (decision D-16, before first publish)

- Generic names re-exported by `native_sqlite` clash with other packages
  (`Index`, `Ignore`, `TypeConverter` in drift/floor/isar) → consider `DbIndex`,
  `DbIgnore` (keep `DbTable`, `DbColumn` prefix style consistent).
- Two ways to ignore (`@Ignore()` and `DbColumn(ignore: true)`) → keep one.
- Stringly-typed options (`onDelete`, `onUpdate`, `type`, `defaultValue` as
  raw SQL) → enums (`ReferenceAction`, `SqlType`) and a typed default
  (`Object?`) — the example already ships a mismatch (SQL default `'1'` vs
  Dart default `18`).
- `nullable: bool?` duplicates Dart nullability and allows contradictions →
  derive from the Dart type (GEN-13).

### ANN-03 · P1 · `EnumField` default (decision D-17)

- Default `ordinal` breaks data when constants are reordered → default `name`
  (recommended) or keep ordinal with the GEN-11 safety check.

### ANN-04 · P2 · Annotations users will expect (roadmap)

- Composite primary keys and composite UNIQUE constraints (GEN-09 P2),
  `renamedFrom` (GEN-17), `@Check`, `COLLATE`, `@CreatedAt`/`@UpdatedAt`,
  relations (`@Relation`, has-many helpers), `@Embedded`, views, FTS5,
  `STRICT` / `WITHOUT ROWID`, `@DbColumn(indexed: true)` shorthand.

### ANN-05 · P1 · Package quality

- Description ≥ 60 chars, repository/topics (REL-04), `analysis_options.yaml`,
  tests (at least constant evaluation of every annotation), `example/`,
  remove the named `library` directive, escape `Map<String, dynamic>` in
  dartdoc.

---

## F. Database Inspector

**Decided (D-03): the inspector ships as a Flutter DevTools extension inside
`native_sqlite` (INS-02). The GitHub Pages app, its deploy workflow and the
Firebase config are retired.** Until INS-02 lands, INS-01 keeps the existing
code safe.

Findings summary: the inspector is not release-ready as advertised.

- The printed link usually can't connect when the app is started from a
  terminal (the database is opened in `main()` before DDS attaches, so
  `Service.getInfo()` returns the raw VM-service address that rejects
  cross-origin pages and later redirects).
- It never works on web (`Service.getInfo` unsupported; the client looks for
  an isolate named exactly `main`, DWDS calls it `main()`).
- The SQL console renders results with the selected table's columns and
  offers delete buttons that can delete rows **from the wrong table**.
- Row identity is wrong for composite/absent primary keys and large keys.
- Export/import/row editing are advertised but not implemented.
- It is active in profile builds while docs say debug only.
- There's no protocol version.
- It hands full VM-service credentials to a page hosted on github.io.
- Its connection code closely resembles Isar Inspector (Apache-2.0) —
  provenance to confirm (D-04).

### INS-01 · P0 · Minimum safety regardless of D-03

- Guard registration with `kDebugMode` (today only `kReleaseMode`,
  `NS/inspector_connect.dart:26`); public opt-out (`enabled`, `printBanner`)
  and a `--dart-define` kill switch; register in the root isolate only.
- Don't log the token (client logs the full ws URL; SQL errors printed with
  stack traces). The hosted link goes away with INS-02 (D-03); until then
  print it with `https://`.
- Unregister databases on `close`/`deleteDatabase` (today `listDatabases`
  fails for the whole app after a close).
- Quote identifiers in `PRAGMA table_info($tableName)`/`index_list`/
  `index_info` and browsing SQL; validate table names against `sqlite_master`
  instead of a regex; isolate errors per database/table.
- Validate `pkColumn` (interpolated into WHERE today).

### INS-02 · P1 · Ship as a Flutter DevTools extension (decided, D-03)

- Connects through DDS (no origin/port-forwarding/redirect problems, works
  for devices and web), runs inside VS Code / Android Studio / browser
  DevTools, versioned with the package, no hosted page sees the token, no
  hosting workflow.
- **Steps:**
  1. `native_sqlite/native_sqlite/extension/devtools/config.yaml`
     (`name: native_sqlite`, `issueTracker`, `version`,
     `materialIconCodePoint`, `requiresConnection: true`).
  2. Inspector app: add `devtools_extensions`, wrap in `DevToolsExtension`,
     replace the raw WebSocket client with
     `serviceManager.callServiceExtensionOnMainIsolate`, listen on
     `serviceManager.service!.onExtensionEvent`, follow
     `serviceManager.isolateManager.mainIsolate` (hot restart); remove
     go_router/web_socket_channel/direct VM service code.
  3. Build: `dart run devtools_extensions build_and_copy
     --source=native_sqlite_inspector --dest=native_sqlite/native_sqlite/extension/devtools`;
     validate: `dart run devtools_extensions validate --package=native_sqlite/native_sqlite`.
  4. Root `.gitignore` ignores `build/` → add an exception for
     `extension/devtools/build/` (git and pub) and check with
     `flutter pub publish --dry-run`.
  5. Develop with `--dart-define=use_simulated_environment=true`.
  6. App side: replace the banner with one line ("Open DevTools →
     native_sqlite"); add `ext.native_sqlite.getInfo` returning
     `{protocol, package, capabilities}`.
  7. CI: build + validate the extension; fail if the committed build is stale.
  8. Docs: `devtools_options.yaml` snippet, screenshots.
- Retire the GitHub Pages app: delete `.github/workflows/deploy-inspector.yml`,
  `native_sqlite_inspector/firebase.json`, `.firebaserc`, the printed
  `dev-nesmin.github.io` link and `InspectorConnect.inspectorUrl`; ask the
  maintainer to disable any old deployment (GitHub Pages site, and
  `native-sqllite.web.app` if still live).

### INS-03 · P1 · Protocol and contract

- `getInfo` handshake with protocol version; shared typed request/response
  models used by app side and client; contract tests (handlers against a fake
  platform; client against recorded responses). Today `getSchema` returns a
  List while the client expects a Map, hidden by an unchecked `as T`.

### INS-04 · P1 · SQL console correctness

- Render the result's own columns (not the selected table's); no row actions
  on ad-hoc results; decide read vs write by whether the statement returns
  columns (PRAGMA/WITH/EXPLAIN/comments are treated as writes today); cap
  results (~1,000 rows) with a "truncated" flag; duplicate column names kept.
- Writes opt-in (toggle) with confirmation for destructive statements;
  remove the unused `query` form of `executeQuery`.

### INS-05 · P1 · Row identity for edit/delete

- rowid tables: select `rowid AS __rowid` and use it; `WITHOUT ROWID`: full
  primary-key tuple; send key values as strings (JSON loses precision above
  2^53); assert exactly one row changed inside a transaction.

### INS-06 · P1 · Implement or delete phantom features

- Export/import JSON (client calls unregistered methods), `updateRecord` UI,
  `getSchema` usage, sidebar database info (cache never filled) → implement
  or remove; every README claim must be true.

### INS-07 · P2 · Live data and robustness

- Live refresh by polling `PRAGMA data_version` (also catches native writes);
  reconnect banner; survive hot restart; empty database doesn't crash
  (`late String selectedTable`); BLOB/NULL/Infinity rendering with a detail
  viewer; views listed; stable ordering for paging; batched schema queries;
  manual connect field (if a hosted fallback remains).

### INS-08 · P1 · Inspector code quality

- Add `analysis_options.yaml` (lints aren't applied today), tests (none),
  remove unused `provider`/`google_fonts`, empty `assets/` entry, broken
  manifest icons, hard-coded "v1.0.1", stale comments; upgrade
  `go_router`/`web_socket_channel` or drop them (DevTools extension).

### INS-09 · P1 · Inspector documentation

- Supported platforms/browsers, how it connects, security note (the link or
  DevTools connection = full debug control of the app; active only in
  debug), privacy (data stays local), how to disable, troubleshooting.
  Remove false claims (row editor, schema panel, live streaming, web ✅).

---

## G. Platform expansion (decision D-10)

### PLT-01 · P2 · macOS via shared Darwin sources

- `sharedDarwinSource: true`, move Swift to `darwin/`, replace `import
  UIKit`/`Flutter` with conditional `FlutterMacOS`; add `macos` to the
  platform list and the example matrix. Gains a pub.dev platform tag.

### PLT-02 · P3 · Windows / Linux via FFI

- Dart-only implementation on `package:sqlite3` (shares code with API-06 and
  web). Native code generation stays Android/iOS only.

### PLT-03 · P2 · iOS App Groups / extensions

- See RT-12; then the example can add a widget/extension demo (EX-24).

---

## H. Plugin-level tests

### TST-01 · P0 · Cross-platform conformance suite

- One Dart test suite (in the example's `integration_test/` or a dedicated
  test app) that every platform must pass: type fidelity (T18), execute/insert
  results (T19), error parity (T11), transactions (T10), multi-statement
  rejection (RT-06), open/close/reopen semantics (RT-08), migrations (T4/T6),
  large rows, names/paths. Runs on the open Android emulator, iOS simulator
  and Chrome locally and in CI; also on host via API-06.

### TST-02 · P1 · Native unit tests

- Kotlin: `NativeSqliteManager` against a real `SQLiteDatabase`
  (Robolectric) — not only mocked plugin wiring; fix the fragile
  `error handling` test (`any(String)` doesn't match null details when
  `BuildConfig.DEBUG=false`), align the test package name with
  `dev.nesmin.native_sqlite`, drop redundant `mockito-inline`.
- Swift: XCTest for `NativeSqliteManager` (open/migrate/bind/errors), run via
  the example's `RunnerTests` or a Swift package test target.

### TST-03 · P1 · Dart unit tests that check behavior

- Mocks must assert forwarded arguments (e.g. "query with arguments passes
  them to platform" never checks them); remove the test asserting the
  `QueryResult ==` bug; add channel-contract tests per implementation
  (method names + argument maps with `TestDefaultBinaryMessengerBinding`).

---

## I. Documentation

### DOC-01 · P0 · Make every statement true

Fix (evidence in the audits; search for the quoted text):

- Root README Quick Start model fails to build (`indexes: [['email'],
  ['created_at']]`); query builder API names are wrong in root and generator
  READMEs (`whereIdEquals`, `orderBy…Ascending`, `find`, `findOne` → real:
  `xEqualTo`, `sortByXAsc`, `findAll`, `findFirst`, `deleteAll`);
  `UserRepository()` targets an unopened database; multi-database routing
  claim; `schema_output_path`; `--delete-conflicting-outputs`; `format`
  default; `generate_helpers`; build caching; `migrate` CLI example;
  architecture diagram (migration builder writes the schema JSON).
- Runtime README: install `^1.0.0`; "0 for non-DML"; `transaction` true/false;
  path null if not opened; WAL for concurrency (web uses MEMORY; iOS shares one
  connection); `detectRemovedTables` recommendation; inspector debug-only;
  platform interface README signatures that don't exist; broken relative
  links; `Manager.kt` KDoc sample; iCloud backup comment; unresolved `[name]`
  dartdoc reference.
- Annotations README: see ANN-01.
- Inspector: see INS-09.

### DOC-02 · P1 · Missing guides

- **Migrations guide:** workflow (GEN-06), what is automatic, what fails the
  build and why, custom steps, renames, testing an upgrade on an open device
  (install over the old build — manual §5.3).
- **Native usage guide:** Android (WorkManager example, threading rule,
  minSdk), iOS (BGTaskScheduler example, synchronized `Generated` folder,
  App Groups), sharing rules (who opens first, busy timeout).
- **Threading & isolates**, **error handling** (exception codes), **web
  setup** (`sqlite3.wasm`, one tab, persistence), **testing your app**
  (API-06), **SQLite versions per platform**, **troubleshooting/FAQ**.

### DOC-03 · P1 · API docs

- `public_member_api_docs` on in every package; library-level docs; code
  samples in dartdoc for the main entry points; generated code gets doc
  comments that explain regeneration.
