# native_sqlite_web

Web implementation of the `native_sqlite` plugin. Runs SQLite compiled to WebAssembly via [sqlite3](https://pub.dev/packages/sqlite3) and stores database files in IndexedDB.

This package is automatically selected when your Flutter app runs on the web — you do not add it to your `pubspec.yaml` directly.

---

## Features

- Full CRUD, transactions, raw SQL and versioned migrations (same rules as Android and iOS)
- Persistence in IndexedDB: every write is flushed before the call completes
- `deleteDatabase` removes the database files from IndexedDB

---

## Web setup

Download `sqlite3.wasm` from the [sqlite3 release](https://github.com/simolus3/sqlite3.dart/releases) that matches the `sqlite3` version in your `pubspec.lock` and place it in your app's `web/` directory:

```bash
curl -L -o web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<version>/sqlite3.wasm
```

---

## Limitations

- **WAL mode** is not available in the browser; MEMORY journal mode is used instead (a `debugPrint` notice is emitted in debug builds).
- **One tab per database:** each tab loads the database into memory, so two tabs writing to the same database can overwrite each other's changes.

---

## Related packages

| Package | Role |
|---------|------|
| [`native_sqlite`](../native_sqlite/) | Main package — app-facing API |
| [`native_sqlite_platform_interface`](../native_sqlite_platform_interface/) | Abstract platform contract |
