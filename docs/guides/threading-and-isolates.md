# Threading and Dart isolates

Android and iOS execute Flutter-channel database operations on a serial,
database-specific worker queue. Work for different databases can proceed in
parallel. A transaction owns that database queue until commit or rollback, so
use the callback's transaction object and keep the callback short.

Generated Kotlin and Swift helpers are synchronous and must be called from a
background thread or queue. Debug native builds reject main-thread access.

## Background Dart isolates

Capture the root-isolate token before spawning work. Initialize the binary
messenger and plugin registrant inside the background isolate before opening a
database:

```dart
final token = ServicesBinding.rootIsolateToken!;
await Isolate.run(() async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  DartPluginRegistrant.ensureInitialized();

  final database = await NativeSqlite.open(DatabaseConfig(name: 'app'));
  await database.execute(
    'INSERT INTO events (message) VALUES (?)',
    ['background complete'],
  );
  await database.close();
});
```

Import `dart:isolate`, `dart:ui`, and `package:flutter/services.dart`. The
DevTools inspector registers only on the root isolate. If setup is omitted,
`NativeSqlite.open` names the missing initialization calls in its error.

Handles are isolate-local Dart objects; open and close a handle inside each
isolate rather than sending a handle through a port. Native connection
reference counting ensures matching configurations share the platform
connection safely.
