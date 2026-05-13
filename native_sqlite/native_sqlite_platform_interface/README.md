# native_sqlite_platform_interface

Platform interface for the `native_sqlite` plugin. This package defines the abstract API that all platform implementations must satisfy.

You do **not** depend on this package directly in your app — it is used internally by `native_sqlite_android`, `native_sqlite_ios`, and `native_sqlite_web`.

---

## Purpose

This package follows the [federated plugin](https://docs.flutter.dev/packages-and-plugins/developing-packages#federated-plugins) pattern. It contains:

- `NativeSqlitePlatform` — the abstract base class all platform implementations extend
- Shared method signatures for `open`, `execute`, `query`, `transaction`, `deleteDatabase`, and schema inspection

---

## For platform implementors

Extend `NativeSqlitePlatform` and register your implementation:

```dart
class MyPlatformSqlite extends NativeSqlitePlatform {
  static void registerWith() {
    NativeSqlitePlatform.instance = MyPlatformSqlite();
  }

  @override
  Future<void> open(DatabaseConfig config) async { ... }

  @override
  Future<List<Map<String, dynamic>>> query(String dbName, String sql, [List<Object?> args = const []]) async { ... }

  // implement remaining methods ...
}
```

---

## Related packages

| Package | Role |
|---------|------|
| [`native_sqlite`](../native_sqlite/) | Main package — app-facing API |
| [`native_sqlite_android`](../native_sqlite_android/) | Android implementation |
| [`native_sqlite_ios`](../native_sqlite_ios/) | iOS implementation |
| [`native_sqlite_web`](../native_sqlite_web/) | Web implementation |
