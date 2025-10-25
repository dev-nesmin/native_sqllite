# Native SQLite - Complete Usage Examples

## Example 1: Simple CRUD Operations

```dart
import 'package:native_sqlite/native_sqlite.dart';

Future<void> simpleCrudExample() async {
  // Open database
  await NativeSqlite.open(
    config: DatabaseConfig(
      name: 'todos_db',
      version: 1,
      onCreate: [
        '''
        CREATE TABLE todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          completed INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
        )
        ''',
      ],
    ),
  );

  // INSERT
  final id = await NativeSqlite.insert('todos_db', 'todos', {
    'title': 'Buy groceries',
    'description': 'Milk, eggs, bread',
    'completed': 0,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  });

  // SELECT
  final result = await NativeSqlite.query(
    'todos_db',
    'SELECT * FROM todos WHERE id = ?',
    [id],
  );
  print(result.toMapList().first);

  // UPDATE
  await NativeSqlite.update(
    'todos_db',
    'todos',
    {'completed': 1},
    where: 'id = ?',
    whereArgs: [id],
  );

  // DELETE
  await NativeSqlite.delete(
    'todos_db',
    'todos',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

## Example 2: Location Tracking from Background Worker (Android)

### Kotlin (WorkManager)

```kotlin
// LocationTrackingWorker.kt
package com.example.myapp

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.google.android.gms.location.*
import dev.nesmin.native_sqlite.NativeSqliteManager
import dev.nesmin.native_sqlite.DatabaseConfig

class LocationTrackingWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        // Initialize database
        initializeDatabase()

        // Get current location
        val location = getCurrentLocation()

        // Save to database
        saveLocation(location)

        return Result.success()
    }

    private fun initializeDatabase() {
        NativeSqliteManager.initialize(context)

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
                            accuracy REAL,
                            provider TEXT,
                            timestamp INTEGER NOT NULL,
                            synced INTEGER DEFAULT 0
                        )
                        """.trimIndent(),
                        "CREATE INDEX idx_timestamp ON locations(timestamp)",
                        "CREATE INDEX idx_synced ON locations(synced)"
                    ),
                    onUpgrade = null,
                    enableWAL = true,
                    enableForeignKeys = true
                )
            )
        }
    }

    private fun getCurrentLocation(): LocationData {
        // Your location fetching logic here
        return LocationData(
            latitude = 37.7749,
            longitude = -122.4194,
            accuracy = 10.0,
            provider = "gps"
        )
    }

    private fun saveLocation(location: LocationData) {
        val rowId = NativeSqliteManager.insert(
            "location_db",
            "locations",
            mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy,
                "provider" to location.provider,
                "timestamp" to System.currentTimeMillis(),
                "synced" to 0
            )
        )

        android.util.Log.d("LocationWorker", "Saved location with ID: $rowId")
    }
}

data class LocationData(
    val latitude: Double,
    val longitude: Double,
    val accuracy: Double,
    val provider: String
)
```

### Dart (Reading from Flutter)

```dart
// In your Flutter app
Future<void> displayLocations() async {
  final result = await NativeSqlite.query(
    'location_db',
    'SELECT * FROM locations ORDER BY timestamp DESC LIMIT 100',
  );

  for (final location in result.toMapList()) {
    print('Location: ${location['latitude']}, ${location['longitude']} '
          'at ${DateTime.fromMillisecondsSinceEpoch(location['timestamp'] as int)}');
  }
}

Future<void> syncLocations() async {
  // Get unsynced locations
  final result = await NativeSqlite.query(
    'location_db',
    'SELECT * FROM locations WHERE synced = 0',
  );

  final locations = result.toMapList();

  // Upload to server
  for (final location in locations) {
    await uploadToServer(location);

    // Mark as synced
    await NativeSqlite.update(
      'location_db',
      'locations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [location['id']],
    );
  }
}
```

## Example 3: Background Location (iOS)

### Swift (Background Task)

```swift
// LocationBackgroundTaskHandler.swift
import Foundation
import CoreLocation
import native_sqlite_ios

class LocationBackgroundTaskHandler: NSObject {

    let locationManager = CLLocationManager()

    func handleBackgroundLocationUpdate() {
        let manager = NativeSqliteManager.shared

        do {
            // Initialize database
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
                            accuracy REAL,
                            altitude REAL,
                            heading REAL,
                            speed REAL,
                            timestamp REAL NOT NULL,
                            synced INTEGER DEFAULT 0
                        )
                        """,
                        "CREATE INDEX idx_timestamp ON locations(timestamp)",
                        "CREATE INDEX idx_synced ON locations(synced)"
                    ],
                    onUpgrade: nil,
                    enableWAL: true,
                    enableForeignKeys: true
                ))
            }

            // Get location
            guard let location = locationManager.location else { return }

            // Save to database
            let rowId = try manager.insert(
                name: "location_db",
                table: "locations",
                values: [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "accuracy": location.horizontalAccuracy,
                    "altitude": location.altitude,
                    "heading": location.course,
                    "speed": location.speed,
                    "timestamp": location.timestamp.timeIntervalSince1970,
                    "synced": 0
                ]
            )

            print("Saved location with ID: \(rowId)")

            // Clean up old data (keep only last 7 days)
            let sevenDaysAgo = Date().timeIntervalSince1970 - (7 * 24 * 60 * 60)
            let deleted = try manager.delete(
                name: "location_db",
                table: "locations",
                whereClause: "timestamp < ? AND synced = 1",
                whereArgs: [sevenDaysAgo]
            )

            print("Deleted \(deleted) old synced locations")

        } catch {
            print("Database error: \(error.localizedDescription)")
        }
    }
}
```

## Example 4: Batch Operations with Transactions

```dart
Future<void> batchInsertExample() async {
  final locations = [
    {'lat': 37.7749, 'lng': -122.4194, 'time': DateTime.now().millisecondsSinceEpoch},
    {'lat': 37.7750, 'lng': -122.4195, 'time': DateTime.now().millisecondsSinceEpoch},
    {'lat': 37.7751, 'lng': -122.4196, 'time': DateTime.now().millisecondsSinceEpoch},
    // ... 100 more locations
  ];

  // Build SQL statements
  final statements = locations.map((loc) {
    return "INSERT INTO locations (latitude, longitude, timestamp) "
           "VALUES (${loc['lat']}, ${loc['lng']}, ${loc['time']})";
  }).toList();

  // Execute in a single transaction (much faster than individual inserts)
  final success = await NativeSqlite.transaction('location_db', statements);

  print('Batch insert ${success ? 'succeeded' : 'failed'}');
}
```

## Example 5: Complex Queries

```dart
Future<void> complexQueryExample() async {
  // Join query
  final result = await NativeSqlite.query(
    'location_db',
    '''
    SELECT
      l.id,
      l.latitude,
      l.longitude,
      l.timestamp,
      COUNT(p.id) as point_count
    FROM locations l
    LEFT JOIN points p ON p.location_id = l.id
    WHERE l.timestamp > ?
    GROUP BY l.id
    HAVING point_count > 5
    ORDER BY l.timestamp DESC
    LIMIT 10
    ''',
    [DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch],
  );

  for (final row in result.toMapList()) {
    print('Location ${row['id']} has ${row['point_count']} points');
  }
}
```

## Example 6: Database Migration

```dart
// Version 1
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_db',
    version: 1,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
      ''',
    ],
  ),
);

// Version 2 - Add email column
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_db',
    version: 2,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT
      )
      ''',
    ],
    onUpgrade: [
      'ALTER TABLE users ADD COLUMN email TEXT',
    ],
  ),
);

// Version 3 - Add index
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_db',
    version: 3,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT
      )
      ''',
      'CREATE INDEX idx_email ON users(email)',
    ],
    onUpgrade: [
      'CREATE INDEX IF NOT EXISTS idx_email ON users(email)',
    ],
  ),
);
```

## Example 7: Using from Foreground Service (Android)

```kotlin
// LocationForegroundService.kt
class LocationForegroundService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start foreground service
        startForeground(NOTIFICATION_ID, createNotification())

        // Initialize database
        NativeSqliteManager.initialize(applicationContext)

        // Start location updates
        startLocationUpdates()

        return START_STICKY
    }

    private fun onLocationUpdate(location: Location) {
        // Save directly to database from service
        val rowId = NativeSqliteManager.insert(
            "location_db",
            "locations",
            mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy,
                "timestamp" to System.currentTimeMillis()
            )
        )

        Log.d("ForegroundService", "Saved location: $rowId")

        // Your Flutter app can read this data in real-time!
    }
}
```

## Best Practices Summary

1. **Open database once** - Reuse connections
2. **Use transactions for batch operations** - Much faster
3. **Create indexes** - For columns used in WHERE/ORDER BY
4. **Clean up old data** - Keep database size manageable
5. **Handle errors gracefully** - Wrap in try-catch
6. **Use parameterized queries** - Prevent SQL injection
7. **Enable WAL mode** - For concurrent access
8. **Close database when done** - Free resources
9. **Test migrations thoroughly** - Version changes can break data
10. **Monitor database size** - Large databases slow down queries
