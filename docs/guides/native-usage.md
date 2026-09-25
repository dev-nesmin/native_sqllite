# Native Android and iOS usage

Generated Kotlin and Swift helpers open the same named database as Dart. The
first caller opens and migrates it; later callers with the same complete
configuration retain the existing connection. A different version, migration
set, location, WAL setting, or foreign-key setting fails instead of replacing
the live connection.

## Android

Generated helpers are synchronous. Call them from a worker thread, not the
Android main thread. The plugin's Flutter channel already uses a
database-specific background task queue. Generated helpers use `java.time`, so
an application targeting below API 26 must enable core-library desugaring.

```kotlin
class SyncWorker(
    context: Context,
    parameters: WorkerParameters,
) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        DatabaseManager.init(applicationContext)
        val events = SyncEventHelper(DatabaseManager.currentDatabase)
        events.insert(
            SyncEvent(
                source = "workmanager",
                message = "completed",
                createdAt = Instant.now(),
            )
        )
        DatabaseManager.close()
        Result.success()
    }
}
```

Use unique work for manual runs and periodic work for production scheduling.
The example exposes a “run task body now” action so database behavior can be
tested without waiting for WorkManager's scheduler.

## iOS

Add `ios/Runner/Generated` to the Runner target as an Xcode synchronized
folder. Generated helpers and `NativeSqliteManager.withConnection` are
synchronous; invoke them on a background `DispatchQueue` or from a
`BGTaskScheduler` handler.

```swift
BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "dev.example.refresh",
  using: nil
) { task in
  DispatchQueue.global(qos: .utility).async {
    do {
      try DatabaseManager.shared.initialize()
      let name = try DatabaseManager.shared.currentDatabase
      let events = SyncEventHelper(databaseName: name)
      _ = try events.insert(SyncEvent(
        source: "bgtask",
        message: "completed",
        createdAt: Date()
      ))
      task.setTaskCompleted(success: true)
    } catch {
      task.setTaskCompleted(success: false)
    }
  }
}
```

Add the identifier to `BGTaskSchedulerPermittedIdentifiers` and enable the
`fetch` or `processing` background mode as appropriate. Scheduler launches do
not run normally in the simulator; keep a debug “run body now” path. On a
debugged device, Apple development tooling also supports:

```text
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"dev.example.refresh"]
```

## App Groups and ownership

Set `DatabaseConfig.iosAppGroup` for both the app and extension, and give both
targets the same App Group entitlement. Do not also set `directory`. Each
owner closes only its own reference. WAL improves process overlap, but does
not replace application-level coordination; use a sensible busy timeout and
keep write transactions short.
