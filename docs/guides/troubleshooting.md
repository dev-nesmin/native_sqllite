# Troubleshooting and FAQ

## No platform implementation found

Run `flutter pub get`, confirm the app depends on `native_sqlite`, and perform
a full restart after adding the plugin. In a background isolate, initialize
`BackgroundIsolateBinaryMessenger` and `DartPluginRegistrant` first.

## Database is already open with a different configuration

Every owner of a name must use identical version, migration statements,
location, WAL, and foreign-key settings. Generated Dart, Kotlin, and Swift
`DatabaseManager` files must come from the same generator run.

## Database is locked or busy

Keep transactions short and do not run generated native helpers on the main
thread. Ensure every owner uses the shared manager instead of opening the same
path independently. On web, close other tabs using the database.

## Web open fails

Verify `web/sqlite3.wasm` exists and matches the resolved `sqlite3` version.
Check the browser console and clear the site's IndexedDB only when discarding
local data is acceptable.

## Inspector tab is missing

Use a debug build, open a database, enable `native_sqlite` in DevTools'
Extensions menu, and restart both the app and DevTools after package updates.
Check `InspectorConnect.enabled` and the
`NATIVE_SQLITE_INSPECTOR` compile-time define.

## A migration fails

The entire migration is rolled back. Preserve the failing database, capture
the structured SQLite code, and reproduce by installing the new build over
the old one. Do not edit committed historical snapshots to make the failure
disappear.

## Generated files are stale

Run `dart run build_runner build`, then commit Dart table parts, schema
snapshots, `database_manager.dart`, and the generated Kotlin/Swift folders.
CI regenerates these files and fails on a diff.
