# native_sqlite_web

Web implementation of the `native_sqlite` plugin using SQLite WASM.

## Features

- ✅ Full SQLite compatibility via WASM (sql.js)
- ✅ Persistent storage using IndexedDB
- ✅ All CRUD operations (Create, Read, Update, Delete)
- ✅ Transaction support
- ✅ Foreign key constraints
- ✅ Database versioning and migrations
- ✅ Works in all modern browsers (Chrome, Firefox, Safari, Edge)

## How It Works

This package provides web support for `native_sqlite` by using:

1. **sqlite3 WASM**: A WebAssembly build of SQLite that runs in the browser
2. **IndexedDB**: Browser storage API used for database persistence
3. **Virtual File System**: sqlite3's VFS abstraction to store data in IndexedDB

## Browser Compatibility

Requires browsers with WASM support:
- Chrome 57+ (2017)
- Firefox 52+ (2017)
- Safari 11+ (2017)
- Edge 16+ (2017)

> **Note**: This covers ~99% of users. For legacy browsers without WASM support, consider providing a fallback or showing an upgrade message.

## Performance Characteristics

### First Load
- ~200-300ms initialization time (one-time, WASM module cached by browser)
- ~1MB WASM file download (cached after first visit)

### Runtime Performance
- Query execution: Near-native speed once initialized
- Storage: Uses IndexedDB (same as native browser storage)
- Memory: Efficient with virtual file system caching

## Differences from Native Platforms

### WAL Mode
- **Native (Android/iOS)**: Full Write-Ahead Logging support
- **Web**: Uses `MEMORY` journal mode instead
  - Provides good concurrency for web apps
  - Data still persists to IndexedDB
  - Automatic fallback to `DELETE` mode if needed

### Database Paths
- **Native**: Returns file system paths like `/data/user/.../databases/mydb.db`
- **Web**: Returns virtual paths like `indexed_db://mydb.db`

### Database Deletion
- Database connections are properly closed
- Files may persist in IndexedDB until browser storage is cleared
- This matches web platform behavior

## Setup

### 1. Add the WASM File (Optional)

The package automatically loads the WASM file from the configured location. By default, it uses `sqlite3.wasm` which is bundled with the `sqlite3_web` package.

For custom configurations, you can host the WASM file yourself:

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/sqlite3.wasm
```

### 2. No Additional Configuration Required

The plugin automatically registers the web implementation when you add it to your `pubspec.yaml`:

```yaml
dependencies:
  native_sqlite: any
```

Flutter's plugin system handles platform-specific implementations automatically.

## Usage

The API is identical across all platforms:

```dart
import 'package:native_sqlite/native_sqlite.dart';

// Open database (works on Android, iOS, and Web!)
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_app',
    version: 1,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
      )
      ''',
    ],
  ),
);

// Insert data
final userId = await NativeSqlite.insert(
  'my_app',
  'users',
  {'name': 'John', 'email': 'john@example.com'},
);

// Query data
final result = await NativeSqlite.query(
  'my_app',
  'SELECT * FROM users WHERE id = ?',
  [userId],
);

print(result.toMapList()); // [{'id': 1, 'name': 'John', 'email': 'john@example.com'}]
```

## Technical Details

### Dependencies

- `sqlite3`: Dart bindings for SQLite
- `sqlite3_web`: Web-specific WASM implementation
- `flutter_web_plugins`: Flutter's web plugin infrastructure

### Architecture

```
┌─────────────────────────────────────┐
│   Your Flutter App (Dart code)     │
└─────────────┬───────────────────────┘
              │
              ├─ Android → native_sqlite_android → SQLite (C)
              ├─ iOS     → native_sqlite_ios     → SQLite (C)
              └─ Web     → native_sqlite_web     → sqlite3 (WASM) → IndexedDB
```

### Storage Location

Web databases are stored in the browser's IndexedDB under your app's origin (domain). You can inspect them using browser DevTools:

- **Chrome**: DevTools → Application → Storage → IndexedDB
- **Firefox**: DevTools → Storage → IndexedDB
- **Safari**: Develop → Show Web Inspector → Storage → IndexedDB

## Troubleshooting

### "Failed to initialize sqlite3 WASM"

**Cause**: Browser doesn't support WASM or network issue loading the WASM file

**Solution**:
- Check browser compatibility (must be 2017 or newer)
- Check network connectivity
- Check browser console for CORS or loading errors

### Database persists after deleteDatabase()

**Cause**: Web platform behavior - IndexedDB may not immediately delete storage

**Solution**: This is normal. The browser will eventually clean up the storage, or users can clear it manually through browser settings.

### Slower than expected performance

**Cause**: First initialization loads the WASM module

**Solution**:
- This is one-time per session
- Browser caches the WASM file after first load
- Consider showing a loading indicator during first database open

## License

Same as the parent `native_sqlite` package.
