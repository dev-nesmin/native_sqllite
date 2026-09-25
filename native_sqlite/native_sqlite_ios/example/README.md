# iOS implementation example

Applications should depend on `native_sqlite`, which selects this iOS
implementation automatically. Open a handle with
`NativeSqlite.open(DatabaseConfig(name: 'app'))`; generated Swift helpers can
use `NativeSqliteManager.shared` from background tasks and App Group
extensions.
