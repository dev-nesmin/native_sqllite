# Platform-interface example

App authors should use `package:native_sqlite/native_sqlite.dart` instead of
depending on this package directly. Platform implementers extend
`NativeSqlitePlatform`, implement the database operations, and register their
instance with `NativeSqlitePlatform.instance`.
