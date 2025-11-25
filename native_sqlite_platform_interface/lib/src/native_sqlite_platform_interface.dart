import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/database_config.dart';
import 'models/query_result.dart';

/// The interface that platform-specific implementations must extend.
///
/// Platform implementations should extend this class rather than implement it as `NativeSqlite`
/// does not consider newly added methods to be breaking changes. Extending this class ensures that
/// the subclass will get the default implementation, while platform implementations that `implements`
/// this interface will be broken by newly added methods.
abstract class NativeSqlitePlatform extends PlatformInterface {
  NativeSqlitePlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeSqlitePlatform? _instance;

  /// The default instance of [NativeSqlitePlatform] to use.
  ///
  /// Defaults to `null`.
  static NativeSqlitePlatform? get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeSqlitePlatform] when
  /// they register themselves.
  static set instance(NativeSqlitePlatform? instance) {
    if (instance != null) {
      PlatformInterface.verifyToken(instance, _token);
    }
    _instance = instance;
  }

  /// Opens or creates a database with the given configuration.
  ///
  /// Returns the database path on success.
  /// Throws an exception if the database cannot be opened.
  Future<String> openDatabase(DatabaseConfig config) {
    throw UnimplementedError('openDatabase() has not been implemented.');
  }

  /// Closes the database with the given name.
  Future<void> closeDatabase(String databaseName) {
    throw UnimplementedError('closeDatabase() has not been implemented.');
  }

  /// Executes a raw SQL query.
  ///
  /// Use this for INSERT, UPDATE, DELETE, or other non-SELECT statements.
  /// Returns the number of rows affected.
  Future<int> execute(String databaseName, String sql, List<Object?>? arguments) {
    throw UnimplementedError('execute() has not been implemented.');
  }

  /// Executes a SELECT query and returns the results.
  Future<QueryResult> query(String databaseName, String sql, List<Object?>? arguments) {
    throw UnimplementedError('query() has not been implemented.');
  }

  /// Inserts a row into the specified table.
  ///
  /// Returns the row ID of the inserted row.
  Future<int> insert(String databaseName, String table, Map<String, Object?> values) {
    throw UnimplementedError('insert() has not been implemented.');
  }

  /// Updates rows in the specified table.
  ///
  /// Returns the number of rows affected.
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    throw UnimplementedError('update() has not been implemented.');
  }

  /// Deletes rows from the specified table.
  ///
  /// Returns the number of rows deleted.
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    throw UnimplementedError('delete() has not been implemented.');
  }

  /// Executes multiple SQL statements in a transaction.
  ///
  /// Returns true if the transaction was successful.
  Future<bool> transaction(String databaseName, List<String> sqlStatements) {
    throw UnimplementedError('transaction() has not been implemented.');
  }

  /// Gets the database path for a given database name.
  Future<String?> getDatabasePath(String databaseName) {
    throw UnimplementedError('getDatabasePath() has not been implemented.');
  }

  /// Deletes the database file.
  Future<void> deleteDatabase(String databaseName) {
    throw UnimplementedError('deleteDatabase() has not been implemented.');
  }
}
