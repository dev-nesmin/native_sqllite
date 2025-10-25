# Native SQLite

A simple yet powerful SQLite plugin for Flutter that's accessible from **both native code (Android Kotlin/Swift) and Flutter/Dart**, with **Write-Ahead Logging (WAL)** mode enabled for safe concurrent access.

## Features

- **Concurrent Access**: WAL mode allows both native and Flutter code to read/write simultaneously
- **Native Access**: Direct database access from Android (Kotlin) and iOS (Swift) without method channels
- **Simple API**: Easy-to-use API for common database operations
- **Type-Safe**: Strongly typed with clear error handling
- **Federated Plugin**: Clean architecture with platform-specific implementations
- **Thread-Safe**: Built-in synchronization for multi-threaded access
- **Lightweight**: No heavy dependencies, uses native SQLite

## Why This Plugin?

Most Flutter SQLite plugins (including `sqflite`) are **Flutter-only** and cannot be accessed from native code. This becomes a problem when:

- Your **WorkManager** (Android) or **Background Task** (iOS) needs to write location data
- Your **Foreground Service** needs to log events
- Your **App Extension** needs to access shared data
- You need **concurrent access** from both native background tasks and Flutter UI

**Native SQLite** solves this by providing a **shared database** accessible from all contexts.

## Installation

Add this to your plugin's `pubspec.yaml`:

```yaml
dependencies:
  native_sqlite:
    path: ../native_sqlite
```

## Usage

### Flutter/Dart Usage

```dart
import 'package:native_sqlite/native_sqlite.dart';

// 1. Open or create a database
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'location_db',
    version: 1,
    onCreate: [
      '''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
      ''',
      'CREATE INDEX idx_timestamp ON locations(timestamp)',
      'CREATE INDEX idx_synced ON locations(synced)',
    ],
    enableWAL: true,  // Enable WAL mode (default: true)
    enableForeignKeys: true,  // Enable foreign keys (default: true)
  ),
);

// 2. Insert data
final id = await NativeSqlite.insert(
  'location_db',
  'locations',
  {
    'latitude': 37.7749,
    'longitude': -122.4194,
    'accuracy': 10.5,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'synced': 0,
  },
);
print('Inserted location with ID: $id');

// 3. Query data
final result = await NativeSqlite.query(
  'location_db',
  'SELECT * FROM locations WHERE synced = ? ORDER BY timestamp DESC LIMIT 10',
  [0],
);

for (final row in result.toMapList()) {
  print('Location: ${row['latitude']}, ${row['longitude']} at ${row['timestamp']}');
}

// 4. Update data
final updated = await NativeSqlite.update(
  'location_db',
  'locations',
  {'synced': 1},
  where: 'id = ?',
  whereArgs: [id],
);
print('Updated $updated rows');

// 5. Delete data
final deleted = await NativeSqlite.delete(
  'location_db',
  'locations',
  where: 'timestamp < ?',
  whereArgs: [DateTime.now().millisecondsSinceEpoch - 86400000], // 1 day ago
);
print('Deleted $deleted old locations');

// 6. Transaction
final success = await NativeSqlite.transaction('location_db', [
  "INSERT INTO locations (latitude, longitude, timestamp) VALUES (37.7749, -122.4194, ${DateTime.now().millisecondsSinceEpoch})",
  "UPDATE locations SET synced = 1 WHERE synced = 0",
]);

// 7. Close database (when done)
await NativeSqlite.close('location_db');
```

### Android (Kotlin) Usage

Access the **same database** from native Android code (e.g., WorkManager, Service, BroadcastReceiver):

```kotlin
import dev.nesmin.native_sqlite.NativeSqliteManager
import dev.nesmin.native_sqlite.DatabaseConfig

class LocationWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        // Initialize if needed (usually done by plugin)
        NativeSqliteManager.initialize(applicationContext)

        // Open database (or reuse if already open)
        if (!NativeSqliteManager.isDatabaseOpen("location_db")) {
            NativeSqliteManager.openDatabase(
                DatabaseConfig(
                    name = "location_db",
                    version = 1,
                    onCreate = listOf(
                        """
                        CREATE TABLE locations (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            latitude REAL NOT NULL,
                            longitude REAL NOT NULL,
                            timestamp INTEGER NOT NULL
                        )
                        """.trimIndent()
                    ),
                    onUpgrade = null,
                    enableWAL = true,
                    enableForeignKeys = true
                )
            )
        }

        // Insert location data
        val rowId = NativeSqliteManager.insert(
            "location_db",
            "locations",
            mapOf(
                "latitude" to 37.7749,
                "longitude" to -122.4194,
                "timestamp" to System.currentTimeMillis()
            )
        )
        Log.d("LocationWorker", "Inserted location with ID: $rowId")

        // Query data
        val result = NativeSqliteManager.query(
            "location_db",
            "SELECT * FROM locations WHERE timestamp > ?",
            listOf(System.currentTimeMillis() - 3600000) // Last hour
        )

        val rows = result["rows"] as List<List<Any?>>
        Log.d("LocationWorker", "Found ${rows.size} locations")

        // Update data
        val updated = NativeSqliteManager.update(
            "location_db",
            "locations",
            mapOf("synced" to 1),
            where = "id = ?",
            whereArgs = listOf(rowId)
        )

        return Result.success()
    }
}
```

### iOS (Swift) Usage

Access the **same database** from native iOS code (e.g., Background Task, App Extension):

```swift
import native_sqlite_ios

class LocationBackgroundTask {

    func captureLocation() {
        let manager = NativeSqliteManager.shared

        do {
            // Open database (or reuse if already open)
            if !manager.isDatabaseOpen(name: "location_db") {
                try manager.openDatabase(config: DatabaseConfig(
                    name: "location_db",
                    version: 1,
                    onCreate: [
                        """
                        CREATE TABLE locations (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            latitude REAL NOT NULL,
                            longitude REAL NOT NULL,
                            timestamp INTEGER NOT NULL
                        )
                        """
                    ],
                    onUpgrade: nil,
                    enableWAL: true,
                    enableForeignKeys: true
                ))
            }

            // Insert location data
            let rowId = try manager.insert(
                name: "location_db",
                table: "locations",
                values: [
                    "latitude": 37.7749,
                    "longitude": -122.4194,
                    "timestamp": Date().timeIntervalSince1970
                ]
            )
            print("Inserted location with ID: \(rowId)")

            // Query data
            let result = try manager.query(
                name: "location_db",
                sql: "SELECT * FROM locations WHERE timestamp > ?",
                arguments: [Date().timeIntervalSince1970 - 3600] // Last hour
            )

            if let rows = result["rows"] as? [[Any?]] {
                print("Found \(rows.count) locations")
            }

            // Update data
            let updated = try manager.update(
                name: "location_db",
                table: "locations",
                values: ["synced": 1],
                whereClause: "id = ?",
                whereArgs: [rowId]
            )
            print("Updated \(updated) rows")

        } catch {
            print("Database error: \(error)")
        }
    }
}
```

## Architecture

This is a **federated plugin** with clean separation of concerns:

```
native_sqlite/                          # Main plugin (app-facing)
├── lib/native_sqlite.dart              # Public API

native_sqlite_platform_interface/      # Platform interface
├── lib/
│   ├── models/
│   │   ├── database_config.dart       # Database configuration
│   │   └── query_result.dart          # Query result models
│   └── native_sqlite_platform_interface.dart

native_sqlite_android/                  # Android implementation
├── android/src/main/kotlin/
│   ├── NativeSqlitePlugin.kt          # Method channel handler
│   └── NativeSqliteManager.kt         # Database manager (accessible from native)
└── lib/native_sqlite_android.dart

native_sqlite_ios/                      # iOS implementation
├── ios/Classes/
│   ├── NativeSqlitePlugin.swift       # Method channel handler
│   └── NativeSqliteManager.swift      # Database manager (accessible from native)
└── lib/native_sqlite_ios.dart
```

## Key Features Explained

### WAL Mode (Write-Ahead Logging)

WAL mode allows:
- **Multiple readers** simultaneously
- **One writer** while others are reading
- **No blocking** between readers and writers

This is essential when both native background tasks and Flutter UI need database access.

### Thread Safety

- **Android**: Uses `ConcurrentHashMap` and `synchronized` blocks
- **iOS**: Uses `DispatchQueue` with barriers for thread-safe access
- Both platforms handle concurrent access safely

### Database Lifecycle

The database remains open across:
- **Flutter app lifecycle** (hot reload, hot restart)
- **Native background tasks** (WorkManager, Background Tasks)
- **App state changes** (background/foreground)

You should call `close()` only when completely done with the database.

## Best Practices

1. **Open once**: Open the database once and reuse it
2. **Use transactions**: Batch multiple writes in a transaction for performance
3. **Create indexes**: Index columns used in WHERE clauses
4. **Clean up old data**: Regularly delete old records to keep database size manageable
5. **Handle errors**: Wrap database calls in try-catch blocks
6. **Use prepared statements**: Always use `?` placeholders to prevent SQL injection

## Example: Background Location Plugin Integration

```dart
// In your background_location plugin:

class BackgroundLocationDatabase {
  static const _dbName = 'background_location';

  static Future<void> initialize() async {
    await NativeSqlite.open(
      config: DatabaseConfig(
        name: _dbName,
        version: 1,
        onCreate: [
          '''
          CREATE TABLE location_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            altitude REAL,
            heading REAL,
            speed REAL,
            timestamp INTEGER NOT NULL,
            is_mock INTEGER DEFAULT 0,
            synced_to_server INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL
          )
          ''',
          'CREATE INDEX idx_timestamp ON location_logs(timestamp)',
          'CREATE INDEX idx_synced ON location_logs(synced_to_server)',
        ],
        enableWAL: true,
      ),
    );
  }

  static Future<int> saveLocation(LocationData location) {
    return NativeSqlite.insert(_dbName, 'location_logs', {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'timestamp': location.timestamp,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    final result = await NativeSqlite.query(
      _dbName,
      'SELECT * FROM location_logs WHERE synced_to_server = 0 ORDER BY timestamp ASC',
    );
    return result.toMapList();
  }
}
```

## Performance Considerations

- **Batch inserts**: Use transactions for multiple inserts
- **Index properly**: Create indexes for frequently queried columns
- **Vacuum regularly**: Run `VACUUM` to reclaim space after large deletes
- **Connection pooling**: Reuse database connections instead of opening/closing frequently
- **WAL checkpoint**: WAL mode automatically checkpoints, but you can manually trigger it if needed

## Troubleshooting

### Database locked errors
- Make sure WAL mode is enabled (`enableWAL: true`)
- Check that you're not holding long-running transactions
- Ensure proper cleanup of database connections

### Cannot access from native code
- Android: Make sure `NativeSqliteManager.initialize(context)` is called
- iOS: The manager is a singleton, no initialization needed
- Verify the database name matches exactly

### Migration issues
- Increment the `version` number when schema changes
- Provide `onUpgrade` SQL statements
- Test migrations thoroughly

## License

This plugin is part of the background_location package.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
