import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';
import 'inspector_connect.dart';

/// Main class for interacting with SQLite databases.
///
/// This class provides a simple, type-safe API for database operations.
/// The same database can be accessed concurrently from both Flutter and native code
/// (Android Kotlin or iOS Swift) thanks to WAL mode.
///
/// Example usage:
/// ```dart
/// // Open or create a database
/// await NativeSqlite.open(
///   config: DatabaseConfig(
///     name: 'my_database',
///     version: 1,
///     onCreate: [
///       '''
///       CREATE TABLE users (
///         id INTEGER PRIMARY KEY AUTOINCREMENT,
///         name TEXT NOT NULL,
///         email TEXT UNIQUE NOT NULL,
///         created_at INTEGER NOT NULL
///       )
///       ''',
///     ],
///   ),
/// );
///
/// // Insert data
/// final userId = await NativeSqlite.insert(
///   'my_database',
///   'users',
///   {
///     'name': 'John Doe',
///     'email': 'john@example.com',
///     'created_at': DateTime.now().millisecondsSinceEpoch,
///   },
/// );
///
/// // Query data
/// final result = await NativeSqlite.query(
///   'my_database',
///   'SELECT * FROM users WHERE id = ?',
///   [userId],
/// );
/// print(result.toMapList());
///
/// // Close database
/// await NativeSqlite.close('my_database');
/// ```
class NativeSqlite {
  NativeSqlite._();

  static NativeSqlitePlatform get _platform {
    final platform = NativeSqlitePlatform.instance;
    if (platform == null) {
      throw StateError(
        'No platform implementation found for NativeSqlite. '
        'Make sure you have added the platform-specific dependencies.',
      );
    }
    return platform;
  }

  /// Opens or creates a database with the given configuration.
  ///
  /// Returns the absolute path to the database file.
  ///
  /// If a database with the same name is already open, it will be closed first.
  ///
  /// The [config] parameter specifies the database name, version, and creation/upgrade scripts.
  ///
  /// WAL mode is enabled by default for concurrent access support.
  static Future<String> open({required DatabaseConfig config}) async {
    final path = await _platform.openDatabase(config);
    InspectorConnect.init(config.name);
    return path;
  }

  /// Closes the database with the given [name].
  ///
  /// After closing, the database must be reopened before it can be used again.
  static Future<void> close(String databaseName) {
    return _platform.closeDatabase(databaseName);
  }

  /// Executes a raw SQL statement (INSERT, UPDATE, DELETE, CREATE TABLE, etc.).
  ///
  /// Use [arguments] to bind values to `?` placeholders in the SQL statement.
  ///
  /// Returns the number of rows affected for DML statements (INSERT, UPDATE, DELETE).
  /// For other statements (CREATE TABLE, DROP TABLE, etc.), returns 0.
  ///
  /// Example:
  /// ```dart
  /// await NativeSqlite.execute(
  ///   'my_database',
  ///   'UPDATE users SET name = ? WHERE id = ?',
  ///   ['Jane Doe', 1],
  /// );
  /// ```
  static Future<int> execute(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _platform.execute(databaseName, sql, arguments);
  }

  /// Executes a SELECT query and returns the results.
  ///
  /// Use [arguments] to bind values to `?` placeholders in the SQL statement.
  ///
  /// Returns a [QueryResult] containing the column names and rows.
  /// Use [QueryResult.toMapList()] to convert the result to a list of maps.
  ///
  /// Example:
  /// ```dart
  /// final result = await NativeSqlite.query(
  ///   'my_database',
  ///   'SELECT * FROM users WHERE age > ?',
  ///   [18],
  /// );
  ///
  /// for (final row in result.toMapList()) {
  ///   print('User: ${row['name']}, Email: ${row['email']}');
  /// }
  /// ```
  static Future<QueryResult> query(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _platform.query(databaseName, sql, arguments);
  }

  /// Inserts a row into the specified [table].
  ///
  /// Returns the row ID of the newly inserted row.
  ///
  /// Example:
  /// ```dart
  /// final id = await NativeSqlite.insert(
  ///   'my_database',
  ///   'users',
  ///   {
  ///     'name': 'Alice',
  ///     'email': 'alice@example.com',
  ///     'created_at': DateTime.now().millisecondsSinceEpoch,
  ///   },
  /// );
  /// print('Inserted row with ID: $id');
  /// ```
  static Future<int> insert(
    String databaseName,
    String table,
    Map<String, Object?> values,
  ) {
    return _platform.insert(databaseName, table, values);
  }

  /// Updates rows in the specified [table].
  ///
  /// Use [where] and [whereArgs] to specify which rows to update.
  ///
  /// Returns the number of rows affected.
  ///
  /// Example:
  /// ```dart
  /// final count = await NativeSqlite.update(
  ///   'my_database',
  ///   'users',
  ///   {'name': 'Bob Updated'},
  ///   where: 'id = ?',
  ///   whereArgs: [5],
  /// );
  /// print('Updated $count rows');
  /// ```
  static Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _platform.update(databaseName, table, values,
        where: where, whereArgs: whereArgs);
  }

  /// Deletes rows from the specified [table].
  ///
  /// Use [where] and [whereArgs] to specify which rows to delete.
  /// If [where] is null, all rows will be deleted.
  ///
  /// Returns the number of rows deleted.
  ///
  /// Example:
  /// ```dart
  /// final count = await NativeSqlite.delete(
  ///   'my_database',
  ///   'users',
  ///   where: 'created_at < ?',
  ///   whereArgs: [DateTime.now().millisecondsSinceEpoch - 86400000], // 1 day ago
  /// );
  /// print('Deleted $count old users');
  /// ```
  static Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _platform.delete(databaseName, table,
        where: where, whereArgs: whereArgs);
  }

  /// Executes multiple SQL statements in a transaction.
  ///
  /// All statements will be executed atomically - either all succeed or all fail.
  ///
  /// Returns true if the transaction was successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await NativeSqlite.transaction('my_database', [
  ///   "INSERT INTO users (name, email) VALUES ('User 1', 'user1@example.com')",
  ///   "INSERT INTO users (name, email) VALUES ('User 2', 'user2@example.com')",
  ///   "UPDATE users SET active = 1 WHERE email LIKE '%@example.com'",
  /// ]);
  /// print('Transaction ${success ? 'succeeded' : 'failed'}');
  /// ```
  static Future<bool> transaction(
    String databaseName,
    List<String> sqlStatements,
  ) {
    return _platform.transaction(databaseName, sqlStatements);
  }

  /// Gets the absolute path to the database file.
  ///
  /// Returns null if the database doesn't exist or hasn't been opened yet.
  ///
  /// Example:
  /// ```dart
  /// final path = await NativeSqlite.getDatabasePath('my_database');
  /// print('Database located at: $path');
  /// ```
  static Future<String?> getDatabasePath(String databaseName) {
    return _platform.getDatabasePath(databaseName);
  }

  /// Deletes the database file.
  ///
  /// The database will be closed if it's currently open.
  ///
  /// Example:
  /// ```dart
  /// await NativeSqlite.deleteDatabase('my_database');
  /// print('Database deleted');
  /// ```
  static Future<void> deleteDatabase(String databaseName) {
    return _platform.deleteDatabase(databaseName);
  }
}
