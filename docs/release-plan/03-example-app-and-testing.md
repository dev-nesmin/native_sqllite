# 03 — Example app and test harness

The example app has two jobs:

1. **Showcase** — what pub.dev users see first. It must demonstrate every
   feature correctly, especially the unique one: *the same database used
   by Dart and by native Kotlin/Swift code, with one migration history*.
2. **Test harness** — the place where the plugin is proven on real Android,
   iOS and web targets, locally on already-open devices and in CI.

Read [00-agent-operating-manual.md](00-agent-operating-manual.md) first
(device recipes in §5). Task format: see [README.md](README.md).
Paths below are relative to `example/` unless stated otherwise (they move
with REL-07 if the example is relocated into `native_sqlite/native_sqlite/`).

---

## 1. Current state (audited at `64d1dca`)

`flutter analyze` reports no issues, but only `flutter_lints` is enabled and
platform folders are excluded — the serious problems below are runtime
failures the analyzer can't see. Nothing in CI builds or tests the example.

| Screen (`lib/screens/`) | Shows | Verified problems |
|---|---|---|
| `home_screen.dart` | 8 cards | Promises migrations/WAL/"all features" that aren't demonstrated; top card hidden under the app bar (seen on Android and iOS screenshots) |
| `crud_demo_screen.dart` | Generated repositories (User, Category, Product) | Nullable fields can't be cleared (`copyWith` uses `??`); `setState` after `await` without `mounted`; `user.name[0]` crashes on empty names; no cascade warning |
| `order_management_screen.dart` | Orders with 2 FKs | Status is a free string; filtering/aggregation done in memory; editing silently re-prices |
| `query_builder_demo_screen.dart` | A few builder operators | No loading/error state; "pagination" is only `limit(5)` |
| `advanced_features_screen.dart` | Transactions, FK, indexes, joins, batch | **6 of 7 demos fail**: raw SQL uses camelCase columns (`createdAt`) but the real schema is snake_case (`created_at`); FK demo reports success for any error; index "benchmark" uses leading-wildcard `LIKE` |
| `json_fields_demo_screen.dart` | `@JsonField` | Opens a private database `'json_demo.db'` (becomes `json_demo.db.db` on Android, `json_demodb.db` on iOS); bypasses generated migrations |
| `manual_api_screen.dart` | Raw `NativeSqlite` API | Load/insert/update always fail (camelCase SQL, e.g. `ORDER BY createdAt` at `:38`) |
| `native_integration_screen.dart` | Channel into generated Kotlin/Swift helpers | **Crashes on web** (`dart:io` `Platform.isAndroid` in `build`, `:1,:113`); only `PlatformException` caught → buttons stay disabled after `MissingPluginException` |
| `statistics_screen.dart` | Counts, path, sample data | Name/version/WAL/FK are hard-coded literals (WAL is false on web); hand-written schema text is wrong; sample data not atomic and fails on second tap; "clear all" skips 4 tables |

Models (`lib/models/`): User, Category, Product, Order, Profile (JSON),
AdvancedUser (Duration/Uri/num/enums), FreezedAdvancedUser, StyledItem
(converters). **AdvancedUser, FreezedAdvancedUser and StyledItem are never
used by any screen or test**; enums `UserStatus`/`Priority` are declared
twice. No model exercises: UUID primary key, class-level `@Index`
(named/unique), BLOB, `@DbColumn(name:)` differing from the field, FK
actions `SET NULL`/`RESTRICT`, nullable/self-referencing FK,
`@DbTable(database:)`.

Tests: `test/generated_code_test.dart` (mock platform matching SQL by
prefix; contains leftover AI monologue comments at `:4`, `:35-60`, `:86-89`),
`test/widget_test.dart` (home cards only), `integration_test/database_test.dart`
(fresh create, Dart↔native sharing, hand-written migrations, downgrade,
FK rollback — passes on Android emulator, iOS simulator, Chrome).
**Nothing opens the screens in a test**, which is how the camelCase SQL
shipped.

Platform folders: `macos/` exists but the plugin has no macOS
implementation (blank window at startup); four different app names across
platforms; template placeholders in `web/index.html`/`manifest.json`
("A new Flutter project."); default Flutter icons while
`flutter_launcher_icons` is an unused dependency; personal
`DEVELOPMENT_TEAM` committed; INTERNET + cleartext enabled in the main
Android manifest; `native_sqlite_config.yaml` `models:` key is parsed but
unused.

---

## 2. Principles for the new example

1. **Never hard-code the database name or column names.** Use
   `DatabaseManager.currentDatabase`/`defaultDatabaseName` and the generated
   `XxxSchema` constants. Enforce with a CI grep
   (`git grep -nE "'example_app'|createdAt\b.*(FROM|WHERE|ORDER)" lib/` must be empty).
2. **Prefer the generated APIs** (repositories, query builders, native
   helpers). Raw SQL appears only on the "Raw API" screen, always
   parameterized.
3. **Every async action** shows loading, empty, success and error states
   through one shared widget; no `setState` after dispose.
4. **Platform-aware:** native-only features are hidden or explained on web
   (`kIsWeb`, `defaultTargetPlatform`), never `dart:io` in UI code.
5. **Honest UI:** status shown on screen is read from the database
   (`PRAGMA user_version`, `journal_mode`, `foreign_keys`), not literals.
6. **Every screen has a smoke test** (T14) and every model a round-trip test
   (T1).

---

## 3. Tasks

Priorities: **P0** must be fixed before publishing (broken or misleading) ·
**P1** needed for a publish-grade example · **P2** showcase extras.
Tasks marked *(needs plugin task X)* wait for a task in
[02-plugin-work-plan.md](02-plugin-work-plan.md).

### EX-01 · P0 · Fix all raw SQL to use real column names

- **Evidence:** `manual_api_screen.dart:38,63-64,83`,
  `advanced_features_screen.dart:58-63,106,122,176,206-212,232-233,261,273,302`,
  `statistics_screen.dart:432-519` (hand-written schema text).
- **Do:** build SQL from `XxxSchema` constants
  (`'SELECT * FROM ${UserSchema.tableName} ORDER BY ${UserSchema.createdAt} DESC LIMIT ?'`),
  bind values as arguments, delete the hand-written schema text (show
  `sqlite_master.sql` instead).
- **Acceptance:** every demo on these screens succeeds on Android, iOS and
  web (T14 smoke test proves it); the CI grep in §2 is clean.

### EX-02 · P0 · Native Integration screen must not crash on web

- **Evidence:** `native_integration_screen.dart:1,61,87,113-115`.
- **Do:** replace `dart:io` `Platform` with `kIsWeb`/`defaultTargetPlatform`;
  on web show an explanation card instead of the buttons; catch all errors
  (not only `PlatformException`) and always reset `_isLoading`.
- **Acceptance:** screen opens on web without exceptions; on Android/iOS all
  three actions work (integration test already covers the channel).

### EX-03 · P0 · Content hidden under the translucent app bar

- **Evidence:** `extendBodyBehindAppBar` + padding of only `kToolbarHeight`
  on 8 screens (`home_screen.dart:22`, `crud_demo_screen.dart:38`,
  `order_management_screen.dart:245`, `query_builder_demo_screen.dart:27`,
  `advanced_features_screen.dart:382`, `manual_api_screen.dart:153`,
  `native_integration_screen.dart:122`, `statistics_screen.dart:248`); JSON
  list has none (`json_fields_demo_screen.dart:177`). Visible in screenshots
  on both platforms.
- **Do:** pad with `MediaQuery.paddingOf(context).top` (which includes the
  full app bar height under `extendBodyBehindAppBar`) or drop
  `extendBodyBehindAppBar`.
- **Acceptance:** screenshots (manual §5.4) on the open iOS simulator
  (notched) and Android emulator show the first card fully visible;
  golden tests (T15) at 360/800/1280 wide.

### EX-04 · P0 · Remove `macos/` (or wait for macOS support)

- **Evidence:** plugin declares only android/ios/web
  (`native_sqlite/native_sqlite/pubspec.yaml:14-20`); `DatabaseManager.init`
  throws before `runApp` on macOS.
- **Do:** delete `example/macos/` unless plugin task PLT-01 (macOS via shared
  Darwin sources) is scheduled for the same release; then keep it and add it
  to the test matrix.
- **Acceptance:** `flutter devices` targets offered by the example all work.

### EX-05 · P0 · One source of truth for the database name; honest status

- **Evidence:** literal `'example_app'` 14× in screens; repositories default
  to `build.yaml` `default_database`, `DatabaseManager` to
  `native_sqlite_config.yaml` `database_name` — two settings that can drift
  (`build.yaml:8` vs `native_sqlite_config.yaml:3`); statistics literals
  `statistics_screen.dart:286-290`.
- **Do:** use `DatabaseManager.currentDatabase` everywhere (pass it to
  repositories and query builders); status card reads `PRAGMA user_version`,
  `journal_mode`, `foreign_keys`, `sqlite_version()` and lists
  `DatabaseManager.tableNames` with row counts. Generator task GEN-05
  unifies the two settings.
- **Acceptance:** changing `database_name` and regenerating changes every
  screen's database; statistics show `wal` on Android/iOS and `memory` on web.

### EX-06 · P0 · Transactions and batch demos teach safe code *(needs plugin API-02)*

- **Evidence:** demos interpolate values into SQL
  (`advanced_features_screen.dart:58-63,299-306`) because
  `NativeSqlite.transaction` only accepts `List<String>`; failure behavior
  differs (Android returns `false`, iOS/web throw).
- **Do:** after the plugin gains parameterized transactions/batch, rewrite:
  "place order" = one transaction (insert order + decrement stock) that
  demonstrably rolls back on failure; "batch insert 1,000 rows" with bound
  arguments.
- **Acceptance:** T10 (transaction parity) passes on all targets; the rollback
  demo shows unchanged stock after a forced failure.

### EX-07 · P1 · App architecture and UX foundation

- go_router with URL routes per screen (web back/forward and deep links),
  adaptive navigation (NavigationBar ↔ NavigationRail), max content width
  ~900 dp on wide screens.
- Light + dark theme from one `ColorScheme`; remove the 89 hard-coded
  `Colors.*`.
- Shared `AsyncView` widget (loading / empty / error / data), shared
  snackbar + confirm dialog helpers (today duplicated ×5–6).
- Accessibility: tooltips on icon buttons, semantics labels, text-scale 2.0
  without overflow, decimal keyboard for prices.
- `mounted` guards; enable `unawaited_futures`, `discarded_futures`,
  `strict-casts` in `analysis_options.yaml`.
- **Acceptance:** analyzer clean with the stricter options; goldens (T15)
  pass light/dark × text scale 1/2 × widths 360/800/1280.

### EX-08 · P1 · CRUD screen correctness

- Clearing nullable fields works (fix `copyWith` to distinguish "unset" from
  `null`, e.g. with a sentinel or `ValueGetter<T?>?`) — `user.dart:81`,
  `category.dart:32`, `product.dart:82`, `order.dart:92`.
- Delete shows how many dependent rows cascade (query counts first).
- UNIQUE violations show a friendly message *(needs plugin RT-05 typed
  exceptions)*.
- Search and sort through the query builder; offset pagination.

### EX-09 · P1 · Orders & transactions screen

- `Order.status` becomes an enum stored by name (`@EnumField(type:
  EnumType.name)`) — the natural enum showcase.
- Totals and grouping via SQL (`GROUP BY` / aggregates) instead of in-memory.
- Place-order transaction (EX-06).
- Editing never silently re-prices; missing referenced rows don't crash the
  dropdown.

### EX-10 · P1 · Query Builder playground

- One control per generated operator (EqualTo, NotEqualTo, GreaterThan,
  LessThan, Between, Contains, StartsWith, EndsWith, IsNull, IsNotNull,
  In/NotIn if generated, DateTime After/Before, bool IsTrue/IsFalse, enum
  filters), sort, limit/offset, `findFirst`, `count`, builder `deleteAll`.
- Show the SQL and arguments the builder produced (needs a public
  `toSql()`/debug accessor — generator task GEN-14).
- "No results" differs from "no query yet".
- **Acceptance:** T2 covers every operator (SQL + args + results).

### EX-11 · P1 · Model gallery — every supported type and annotation

- One screen listing each model; for each: create a sample, save, read back,
  show equality check ✓/✗.
- Uses AdvancedUser, FreezedAdvancedUser, StyledItem (today unused) and adds
  new models: `Note` with UUID primary key (`useLocalUuid`), `Attachment`
  with a BLOB (`Uint8List`) column, `Tag` with class-level `@Index(unique:
  true, name: …)` and `@DbColumn(name: 'label_text')`, `Comment` with a
  nullable self-referencing FK (`ON DELETE SET NULL`).
- Remove duplicate enum declarations (share one file).
- Fix `StyledItem` converters (use `toARGB32()`; JSON for tags instead of
  comma-joined strings).
- JSON demo moves into the main database (drop `'json_demo.db'`).
- **Acceptance:** T1 round-trip passes on Android, iOS and web for every
  model; each native helper round-trips the same rows (T7).

### EX-12 · P1 · Raw API & errors screen

- Every `NativeSqlite` method (execute, query, insert, update, delete,
  transaction, batch, getDatabasePath, close, deleteDatabase) with
  parameterized examples built from schema constants.
- Error showcase: UNIQUE, NOT NULL, FK violation, syntax error — shows the
  typed exception and its code *(needs plugin RT-05)*; results must be
  identical on all platforms (T11).

### EX-13 · P1 · Sample data and reset

- "Generate sample data" in one transaction with unique suffixes; can be run
  repeatedly.
- "Reset database": `deleteDatabase` + `DatabaseManager.init()` (fresh create).
- Covers all tables (today 4 are skipped).

### EX-14 · P1 · Platform metadata and branding

- One app name everywhere ("native_sqlite example"): `main.dart`,
  `AndroidManifest.xml`, `Info.plist`, `web/index.html`, `manifest.json`;
  real descriptions instead of "A new Flutter project."
- App icon via `flutter_launcher_icons` (or remove the dependency);
  remove unused `cupertino_icons`.
- Remove `DEVELOPMENT_TEAM` (REL-07/D-12); consistent bundle ids.
- INTERNET/cleartext only in `debug`/`profile` manifests (the inspector uses
  the VM service; release doesn't need it).
- Remove the unused `models:` key from `native_sqlite_config.yaml` (or
  implement it — GEN-20).
- Record where `web/sqlite3.wasm` comes from and which `sqlite3` version it
  matches (README + a check script comparing with `pubspec.lock`).

### EX-15 · P1 · Code hygiene

- Delete AI monologue comments in `test/generated_code_test.dart`
  (`:4,:35-60,:86-89`); rewrite the test on the real-SQLite host backend (T1)
  or delete it.
- Fix wrong `@Table` comments (`query_builder_demo_screen.dart:15`,
  `advanced_features_screen.dart:17`, `statistics_screen.dart:18`).
- Remove leftovers: `// Force rebuild 4` (`user.dart:5`), migration-test
  comments in `advanced.dart:22-41`, "testing migration" in `profile.dart:48`.
- `User.age`: SQL default `'1'` vs Dart default `18` → make them agree.
- `dart format` the example (5 files differ today).

### EX-16 · P1 · Example README and `example.md`

- `example/README.md`: prerequisites (Flutter 3.47.5+, Xcode/CocoaPods or
  SPM, Android minSdk), `flutter pub get`, `build_runner`, what
  `native_sqlite_config.yaml` does, `web/sqlite3.wasm`, iOS synchronized
  `Generated` folder, running on already-open devices (link to operating
  manual §5), running tests, inspector usage.
- `example/example.md` (pana shows it first): 60–100 lines — model → build →
  `DatabaseManager.init()` → repository/query builder → Kotlin & Swift
  helper snippet → migration explanation.

### EX-17 · P1 · Migrations Lab (real schema evolution)

- Commit a real **schema v2** of the example: one `ADD COLUMN` (e.g.
  `Category.icon`) and one table rebuild (e.g. `Order.trackingCode` UNIQUE).
  This creates `lib/generated/schemas/native_sqlite_schema_v2.json` — keep it
  forever.
- Screen shows `DatabaseManager.schemaVersion`, the device's
  `PRAGMA user_version`, and the step SQL for each version.
- Debug-only "simulate v1 install" button: `deleteDatabase`, open with a
  `DatabaseConfig(version: 1, onCreate: <v1 fixture>)`, seed rows, close, run
  `DatabaseManager.init()` and show the upgrade result.
- **Acceptance:** T4 and T5 pass.

### EX-18 · P1 · Background Sync — native writes while the app is closed (the USP)

- **Android:** add WorkManager; a `CoroutineWorker` calls
  `DatabaseManager.init(context)` and inserts rows through the generated
  helpers with `source = "native-worker"`; schedule from the app (periodic +
  "run now").
- **iOS:** `BGAppRefreshTask`/`BGProcessingTask` with identifiers in
  `Info.plist` (`BGTaskSchedulerPermittedIdentifiers`,
  `UIBackgroundModes: fetch, processing`); handler uses
  `DatabaseManager.shared.initialize()` and the generated helpers.
  BGTaskScheduler doesn't run on the simulator — provide a debug "run task
  body now" path and document the LLDB command
  `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"<id>"]`
  for real devices.
- Flutter refreshes on resume (`AppLifecycleListener`) and highlights rows
  written natively.
- *(needs plugin RT-01 threading, RT-08 idempotent open)*
- **Acceptance:** T9 passes on the Android emulator (force-stop app, run job,
  relaunch, rows visible) and the iOS simulator (debug task path).

### EX-19 · P2 · Native opens first

- Android `Application.onCreate` (debug flag) or a native button calls
  `DatabaseManager.init(context)` before Flutter; Dart `init()` must reuse the
  open database (no close/reopen) *(needs plugin RT-08)*.
- **Acceptance:** T5.

### EX-20 · P2 · Web persistence demo

- Launch counter stored in the database; "Reload page" button; warning banner
  when a second tab opens (BroadcastChannel), explaining the one-tab limit.
- **Acceptance:** T12, T13.

### EX-21 · P2 · Inspector card (debug only)

- Shows how to open the inspector in Flutter DevTools (decided D-03:
  DevTools extension, INS-02) — VS Code / Android Studio / browser DevTools
  steps, with screenshots; notes for emulators and devices.
- Hidden in release builds.

### EX-22 · P2 · Benchmarks screen (profile mode)

- Insert N rows: loop vs one transaction vs batch vs native `insertBatch`;
  query with/without index incl. `EXPLAIN QUERY PLAN` output; frame timing
  while a long query runs (proves RT-01).
- **Acceptance:** runs in `--profile` on the open Android emulator; results
  table readable; no jank warnings during queries after RT-01.

### EX-23 · P2 · Background Dart isolate demo *(needs plugin API-05)*

- `Isolate.run` that initializes
  `BackgroundIsolateBinaryMessenger.ensureInitialized(token)` +
  `DartPluginRegistrant.ensureInitialized()` and writes rows.
- **Acceptance:** covered by an integration test on Android and iOS.

### EX-24 · P2 · Android home-screen widget (optional)

- Glance/AppWidget reading the latest orders through generated helpers.
  iOS widget/extension requires plugin App Group support (RT-12) — list as
  follow-up.

---

## 4. Target structure (after EX tasks)

| # | Route | Screen | Acceptance summary |
|---|---|---|---|
| 1 | `/` | Home / Quick start with live DB status chip | every card is a route; no overflow 360–1440 dp |
| 2 | `/crud` | CRUD | nullable clearing; cascade counts; friendly UNIQUE errors |
| 3 | `/query` | Query Builder playground | every operator has a test; SQL shown |
| 4 | `/orders` | Orders & transactions | enum status; transactional order; SQL aggregates |
| 5 | `/models` | Model gallery | every model/type round-trips on A/i/W |
| 6 | `/native` | Native bridge (hidden on web) | off main thread; Dart reads back native writes |
| 7 | `/background` | Background sync | rows appear after app was closed |
| 8 | `/migrations` | Migrations Lab | v1→vN Dart-first and native-first |
| 9 | `/web` | Web persistence (web only) | reload persistence; second-tab warning |
| 10 | `/raw` | Raw API & errors | parameterized; identical errors on all platforms |
| 11 | `/bench` | Benchmarks | profile mode; EXPLAIN QUERY PLAN |
| 12 | `/inspector` | Inspector (debug only) | instructions + link |
| 13 | `/settings` | Settings | DB path, reset, theme |

---

## 5. Test harness

### 5.1 Layers

1. **Host tests with real SQLite (fast, CI on every push).** Add a
   `NativeSqlitePlatform` implementation backed by `package:sqlite3` (FFI)
   for tests — plugin task API-06 in
   [02-plugin-work-plan.md](02-plugin-work-plan.md) (the web
   implementation already targets `CommonDatabase`; share its logic). Then
   repositories, query builders, migrations and screens can be tested with
   `flutter test` and real SQL, no device needed.
2. **Widget/golden tests** with the host backend: every screen opens, every
   demo button runs without error text.
3. **Device integration tests** (`integration_test/`) on the Android emulator,
   iOS simulator and Chrome — only for what needs the real platform:
   channel, native code, file locations, persistence, threading.
4. **Native unit tests:** Gradle JUnit for the Kotlin manager (real
   `SQLiteDatabase` via Robolectric or instrumented tests) and XCTest for the
   Swift manager and generated Swift helpers.

### 5.2 Test matrix

● add · ◐ exists partly · – not applicable. "A" = Android emulator (API 26
and 36 in CI; locally the open emulator), "i" = iOS simulator, "W" = Chrome.

| ID | Scenario | Host | A | i | W |
|---|---|---|---|---|---|
| T1 | Repository round-trip for every model and type (incl. UUID, BLOB, enums by name/ordinal, Duration, Uri, converters, JSON, freezed) | ● | ● | ● | ● |
| T2 | Query-builder SQL + args + results for every operator | ● | | | |
| T3 | Fresh create: tables, indexes, `user_version`, `journal_mode`, `foreign_keys` | | ◐ | ◐ | ◐ |
| T4 | Generated upgrade v1 fixture → current, Dart opens first | ● | ● | ● | ● |
| T5 | Same upgrade, native `DatabaseManager` opens first, then Dart `init` reuses it | | ● | ● | – |
| T6 | Hand-written steps, downgrade rejected, FK-violation rollback | | ◐ | ◐ | ◐ |
| T7 | Dart ↔ native sharing: every model written natively reads back in Dart and vice versa | | ◐ | ◐ | – |
| T8 | Native writer thread while Dart reads/writes (no `SQLITE_BUSY`, no crash) | | ● | ● | – |
| T9 | Native write while the app is closed (WorkManager / BGTask) | | ● | ● | – |
| T10 | Transaction commit/rollback parity (incl. failure in the middle) | ● | ● | ● | ● |
| T11 | Error shape parity: UNIQUE, NOT NULL, FK, syntax → same typed exception + code | ● | ● | ● | ● |
| T12 | Web reload persistence | | | | ● |
| T13 | Web second tab warning | | | | ● |
| T14 | Screen smoke: open every screen, press every demo, assert no error text | ● | ● | ● | ● |
| T15 | Goldens: 360/800/1280 × light/dark × text scale 1/2 | ● | | | |
| T16 | Inspector protocol via `vm_service` (or DevTools extension contract test) | ● | ● | | |
| T17 | Generated Kotlin/Swift compile + helper unit tests | | ● gradle | ● xcodebuild | – |
| T18 | Type fidelity: `SELECT typeof(?)…` for int/double/bool/null/blob/large int | ● | ● | ● | ● |
| T19 | `execute` return values (DML count, DDL 0), `insert` rowid | ● | ● | ● | ● |
| T20 | Frames keep rendering during a 2 s query (threading, after RT-01) | | ● | ● | – |

### 5.3 Key test designs

**T4 / T5 — generated migration upgrade**
1. EX-17 committed a real v2; store the v1 `onCreateStatements` as a test
   fixture (`integration_test/fixtures/schema_v1.dart`).
2. `deleteDatabase`; open `DatabaseConfig(version: 1, onCreate: fixture)`;
   seed rows through raw inserts; close.
3. T4: `DatabaseManager.init()`. T5: first invoke the native
   `DatabaseManager.init` via the example's method channel, then Dart
   `init()`.
4. Assert: `user_version == DatabaseManager.schemaVersion`;
   `PRAGMA foreign_key_check` empty; seeded rows readable through the
   repositories; new columns (`pragma_table_info`) and indexes exist; for T5,
   the database was not closed/reopened by Dart (connection id or a TEMP
   table survives).

**T9 — native write while the app is closed**
- Android instrumented test: `TestListenableWorkerBuilder` runs the worker;
  end-to-end locally: `adb shell am force-stop com.example.native_sqlite_example`,
  `adb shell cmd jobscheduler run -f com.example.native_sqlite_example <jobId>`
  (or the WorkManager test driver), relaunch (§5.3 of the manual), assert via
  the pulled database (§5.7) or an integration test.
- iOS: XCTest calls the task body directly (no Flutter engine); then launch
  the app and assert rows.

**T12 — web persistence**
- In-test: write, `close`, create a fresh `NativeSqliteWeb()` instance,
  reopen, read.
- End-to-end in CI: `flutter build web` + a Playwright script that writes,
  `page.reload()`, and asserts the counter.

**T14 — smoke test**
- Host version: pump the app with the host SQLite backend, visit every route,
  tap every demo button, assert no `Error`/`Exception` text and no uncaught
  exceptions.
- Device version: same flow in `integration_test/smoke_test.dart` on A/i/W.

### 5.4 Running the tests on already-open devices

From the example directory, after detecting devices (manual §5.1):

```bash
puro flutter test                                   # host + widget + golden
puro flutter test integration_test -d "$IOS_SIM"    # uninstalls the app afterwards
puro flutter test integration_test -d "$ANDROID_EMU"
# web: chromedriver on :4444, then
puro flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/<file>.dart -d web-server --browser-name=chrome --headless
```

Native unit tests:

```bash
cd android && ./gradlew :native_sqlite_android:testDebugUnitTest   # + app unit tests
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination "id=$IOS_SIM"                                         # XCTest on the open simulator
```

### 5.5 CI mapping

Host/widget/golden → `test-dart`; integration A → `android-integration`
(API 26 + 36); integration i → `ios-integration`; integration W → `web`;
T17 → `android` + `ios` jobs. See REL-11 in
[04-release-and-publishing.md](04-release-and-publishing.md).
