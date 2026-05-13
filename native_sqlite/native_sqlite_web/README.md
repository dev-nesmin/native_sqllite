# native_sqlite_web

Web implementation of the `native_sqlite` plugin. Powered by [sqlite3](https://pub.dev/packages/sqlite3) and [sqlite3_web](https://pub.dev/packages/sqlite3_web), which compile SQLite to WebAssembly and run it in a shared worker for persistence across tabs.

This package is automatically selected when your Flutter app runs on the web — you do not add it to your `pubspec.yaml` directly.

---

## Features

- Full CRUD, transactions, and raw SQL in the browser via sqlite3 WASM
- Persistence via IndexedDB (data survives page reloads)
- `deleteDatabase` removes the IndexedDB entry entirely

---

## Limitations

- **WAL mode** is not supported in the browser — the implementation falls back to MEMORY journal mode and emits a `debugPrint` warning in debug builds.
- Concurrent multi-tab access is serialised through the shared worker; behaviour may differ from the native WAL-backed implementations.

---

## Web setup

Add the sqlite3 WASM worker files to your `web/` directory. See the [sqlite3_web documentation](https://pub.dev/packages/sqlite3_web) for the required assets (`sqlite3.wasm`, `sqlite3.worker.dart.js`).

---

## Related packages

| Package | Role |
|---------|------|
| [`native_sqlite`](../native_sqlite/) | Main package — app-facing API |
| [`native_sqlite_platform_interface`](../native_sqlite_platform_interface/) | Abstract platform contract |
