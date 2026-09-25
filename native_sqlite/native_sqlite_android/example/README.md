# Android implementation example

Applications should depend on `native_sqlite`, which selects this Android
implementation automatically. Open a handle with
`NativeSqlite.open(DatabaseConfig(name: 'app'))`; generated Kotlin helpers can
use `NativeSqliteManager` to access the same database from WorkManager,
services, or widgets on a background thread.
