# Web implementation example

Applications should depend on `native_sqlite`, copy `sqlite3.wasm` into the
Flutter web directory, and open a database normally:

```dart
final db = await NativeSqlite.open(DatabaseConfig(name: 'app'));
```

The implementation persists the SQLite file in IndexedDB. Keep one active tab
per database.
