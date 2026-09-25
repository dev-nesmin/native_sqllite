# Error handling

SQLite execution failures are reported as `NativeSqliteException` on every
backend. The exception contains the primary and extended SQLite result codes,
the diagnostic message, and the SQL statement shape when known. Bound values
are deliberately excluded.

```dart
try {
  await users.insert(user);
} on NativeSqliteException catch (error) {
  if (error.isUniqueViolation) {
    showDuplicateEmailMessage();
  } else if (error.isForeignKeyViolation) {
    showMissingParentMessage();
  } else {
    rethrow;
  }
}
```

Convenience flags cover constraint, UNIQUE, NOT NULL, FOREIGN KEY, and syntax
errors. For other cases, inspect `resultCode` and `extendedResultCode` using
SQLite's published result-code table. The Flutter channel's envelope code is
`NATIVE_SQLITE_ERROR`; application logic should use the structured SQLite
codes instead of parsing message text.

Programming and lifecycle mistakes use Dart errors:

- `ArgumentError` or `RangeError`: invalid database name, version, location,
  or where arguments.
- `StateError`: closed handle, nested transaction, operation through a handle
  while its transaction callback is active, conflicting open configuration,
  or missing plugin registration.

Throwing from a transaction callback rolls it back and preserves the original
error and stack trace. A failed batch rolls back the complete batch.
