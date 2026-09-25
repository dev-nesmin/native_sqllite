# SQLite versions and portable SQL

Android and iOS use the operating system's SQLite library. Web uses the WASM
artifact shipped by the application, and host tests use the resolved
`package:sqlite3` native library.

The portable baseline is SQLite 3.18, corresponding to the minimum supported
Android API 26 environment. iOS 13 generally supplies SQLite 3.28 or newer,
but applications must not assume one exact patch version. Read the actual
version at runtime:

```dart
final version = (await database.query('SELECT sqlite_version()'))
    .rows.single.single as String;
```

Generated migrations use table rebuilds and avoid newer schema operations.
Features introduced after 3.18—such as `RETURNING`, `DROP COLUMN`, and some
JSON functions—must be guarded by the runtime version or avoided. The
example's Database Statistics screen displays the active version.
