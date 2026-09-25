import 'dart:io';
import 'dart:typed_data';

import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' hide DatabaseConfig;

/// Installs a real SQLite backend for host-side `flutter test` processes.
///
/// ```dart
/// late NativeSqliteFfi backend;
/// setUpAll(() => backend = NativeSqliteTesting.useFfi());
/// tearDownAll(() => backend.dispose());
/// ```
abstract final class NativeSqliteTesting {
  /// Replaces the registered platform backend with an FFI-backed test backend.
  ///
  /// When [directory] is omitted, databases are placed in a new system temp
  /// directory owned by the returned backend. Call [NativeSqliteFfi.dispose]
  /// in `tearDownAll` to close connections and remove that directory.
  static NativeSqliteFfi useFfi({String? directory}) {
    final backend = NativeSqliteFfi(directory: directory);
    NativeSqlitePlatform.instance = backend;
    return backend;
  }
}

/// A synchronous SQLite connection set exposed through the async plugin API.
///
/// This backend is intended for host tests, not application deployment.
class NativeSqliteFfi extends NativeSqlitePlatform {
  NativeSqliteFfi({String? directory})
    : _directory = directory == null
          ? Directory.systemTemp.createTempSync('native_sqlite_test_')
          : Directory(directory),
      _ownsDirectory = directory == null {
    _directory.createSync(recursive: true);
  }

  final Directory _directory;
  final bool _ownsDirectory;
  final Map<String, Database> _databases = {};
  final Map<String, DatabaseConfig> _configs = {};
  final Map<String, int> _references = {};
  final Map<String, String> _activeTransactions = {};

  static String _quoteIdentifier(String identifier) =>
      '"${identifier.replaceAll('"', '""')}"';

  @override
  Future<String> openDatabase(DatabaseConfig config) async {
    final existing = _databases[config.name];
    if (existing != null) {
      if (!_configs[config.name]!.hasSameOpenConfiguration(config)) {
        throw StateError(
          "Database '${config.name}' is already open with a different "
          'configuration.',
        );
      }
      _references[config.name] = _references[config.name]! + 1;
      return _path(config.name, directory: config.directory);
    }

    Database? database;
    try {
      if (config.iosAppGroup != null) {
        throw UnsupportedError('iosAppGroup is only supported on iOS.');
      }
      if (config.directory != null) {
        Directory(config.directory!).createSync(recursive: true);
      }
      database = sqlite3.open(
        _path(config.name, directory: config.directory),
        mode: config.readOnly ? OpenMode.readOnly : OpenMode.readWriteCreate,
      );
      _executeSingle(database, 'PRAGMA busy_timeout = ${config.busyTimeout}');
      if (config.enableWAL && !config.readOnly) {
        _executeSingle(database, 'PRAGMA journal_mode = WAL');
      }

      final currentVersion = _databaseVersion(database);
      if (currentVersion > config.version) {
        throw StateError(
          'Database is at version $currentVersion, newer than the requested '
          'version ${config.version}; downgrades are not supported.',
        );
      }
      if (config.readOnly && currentVersion != config.version) {
        throw StateError(
          'Read-only database is at version $currentVersion, expected '
          '${config.version}.',
        );
      } else if (currentVersion == 0) {
        _migrate(database, config.onCreate ?? const [], config.version);
      } else if (currentVersion < config.version) {
        _migrate(
          database,
          config.upgradeStatements(currentVersion),
          config.version,
        );
      }
      if (config.enableForeignKeys) {
        _executeSingle(database, 'PRAGMA foreign_keys = ON');
      }
      for (final sql in config.onConfigure ?? const <String>[]) {
        _executeSingle(database, sql);
      }

      _databases[config.name] = database;
      _configs[config.name] = config;
      _references[config.name] = 1;
      return _path(config.name, directory: config.directory);
    } catch (_) {
      database?.dispose();
      rethrow;
    }
  }

  @override
  Future<void> closeDatabase(String databaseName) async {
    final references = _references[databaseName];
    if (references == null) return;
    if (_activeTransactions.containsKey(databaseName)) {
      throw StateError(
        'Cannot close database $databaseName while a transaction is active.',
      );
    }
    if (references > 1) {
      _references[databaseName] = references - 1;
      return;
    }
    _close(databaseName);
  }

  @override
  Future<int> execute(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final database = _database(databaseName);
    final before = _totalChanges(database);
    _executeSingle(database, sql, arguments ?? const []);
    return _totalChanges(database) - before;
  }

  @override
  Future<int> executeInsert(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final database = _database(databaseName);
    _executeSingle(database, sql, arguments ?? const []);
    return database.lastInsertRowId;
  }

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final result = _selectSingle(
      _database(databaseName),
      sql,
      arguments ?? const [],
    );
    return QueryResult(
      columns: result.columnNames,
      rows: result.map((row) => row.values.toList()).toList(),
    );
  }

  @override
  Future<int> insert(
    String databaseName,
    String table,
    Map<String, Object?> values,
  ) async {
    final database = _database(databaseName);
    return _insert(database, table, values);
  }

  @override
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return _update(
      _database(databaseName),
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return _delete(
      _database(databaseName),
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<void> beginTransaction(
    String databaseName,
    String transactionId,
  ) async {
    if (_activeTransactions.containsKey(databaseName)) {
      throw StateError('Database $databaseName already has a transaction.');
    }
    _executeSingle(_database(databaseName), 'BEGIN TRANSACTION');
    _activeTransactions[databaseName] = transactionId;
  }

  @override
  Future<void> endTransaction(
    String databaseName,
    String transactionId, {
    required bool commit,
  }) async {
    final database = _transactionDatabase(databaseName, transactionId);
    try {
      _executeSingle(database, commit ? 'COMMIT' : 'ROLLBACK');
    } catch (_) {
      if (commit) {
        try {
          _executeSingle(database, 'ROLLBACK');
        } catch (_) {}
      }
      rethrow;
    } finally {
      _activeTransactions.remove(databaseName);
    }
  }

  @override
  Future<int> transactionExecute(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) async {
    final database = _transactionDatabase(databaseName, transactionId);
    final before = _totalChanges(database);
    _executeSingle(database, sql, arguments ?? const []);
    return _totalChanges(database) - before;
  }

  @override
  Future<QueryResult> transactionQuery(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) async {
    final result = _selectSingle(
      _transactionDatabase(databaseName, transactionId),
      sql,
      arguments ?? const [],
    );
    return QueryResult(
      columns: result.columnNames,
      rows: result.map((row) => row.values.toList()).toList(),
    );
  }

  @override
  Future<int> transactionInsert(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values,
  ) async =>
      _insert(_transactionDatabase(databaseName, transactionId), table, values);

  @override
  Future<int> transactionUpdate(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async => _update(
    _transactionDatabase(databaseName, transactionId),
    table,
    values,
    where: where,
    whereArgs: whereArgs,
  );

  @override
  Future<int> transactionDelete(
    String databaseName,
    String transactionId,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async => _delete(
    _transactionDatabase(databaseName, transactionId),
    table,
    where: where,
    whereArgs: whereArgs,
  );

  @override
  Future<List<Object?>> executeBatch(
    String databaseName,
    List<Map<String, Object?>> operations,
  ) async {
    final database = _database(databaseName);
    _executeSingle(database, 'BEGIN TRANSACTION');
    try {
      final results = <Object?>[
        for (final operation in operations) _batch(database, operation),
      ];
      _executeSingle(database, 'COMMIT');
      return results;
    } catch (_) {
      try {
        _executeSingle(database, 'ROLLBACK');
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<String> getDatabasePath(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) async {
    if (iosAppGroup != null) {
      throw UnsupportedError('iosAppGroup is only supported on iOS.');
    }
    return _path(databaseName, directory: directory);
  }

  @override
  Future<bool> databaseExists(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) async {
    if (iosAppGroup != null) {
      throw UnsupportedError('iosAppGroup is only supported on iOS.');
    }
    return File(_path(databaseName, directory: directory)).existsSync();
  }

  @override
  Future<void> importDatabase(
    String databaseName,
    Uint8List bytes, {
    String? directory,
    String? iosAppGroup,
    bool overwrite = false,
  }) async {
    if (iosAppGroup != null) {
      throw UnsupportedError('iosAppGroup is only supported on iOS.');
    }
    if (_databases.containsKey(databaseName)) {
      throw StateError("Database '$databaseName' is open.");
    }
    final path = _path(databaseName, directory: directory);
    final file = File(path);
    if (file.existsSync() && !overwrite) return;
    file.parent.createSync(recursive: true);
    if (overwrite) {
      for (final suffix in const ['-journal', '-wal', '-shm']) {
        final sidecar = File('$path$suffix');
        if (sidecar.existsSync()) sidecar.deleteSync();
      }
    }
    file.writeAsBytesSync(bytes, flush: true);
  }

  @override
  Future<void> deleteDatabase(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) async {
    if (iosAppGroup != null) {
      throw UnsupportedError('iosAppGroup is only supported on iOS.');
    }
    _close(databaseName);
    for (final suffix in const ['', '-journal', '-wal', '-shm']) {
      final file = File('${_path(databaseName, directory: directory)}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
  }

  /// Closes all test databases and removes an automatically-created temp dir.
  void dispose() {
    for (final database in _databases.values) {
      database.dispose();
    }
    _databases.clear();
    _configs.clear();
    _references.clear();
    _activeTransactions.clear();
    if (_ownsDirectory && _directory.existsSync()) {
      _directory.deleteSync(recursive: true);
    }
  }

  String _path(String name, {String? directory}) =>
      '${directory ?? _directory.path}${Platform.pathSeparator}$name.db';

  Database _database(String name) =>
      _databases[name] ?? (throw StateError("Database '$name' is not open."));

  Database _transactionDatabase(String name, String transactionId) {
    if (_activeTransactions[name] != transactionId) {
      throw StateError("Transaction '$transactionId' is not active.");
    }
    return _database(name);
  }

  void _close(String name) {
    _databases.remove(name)?.dispose();
    _configs.remove(name);
    _references.remove(name);
    _activeTransactions.remove(name);
  }

  int _insert(Database database, String table, Map<String, Object?> values) {
    if (values.isEmpty) throw ArgumentError('Values cannot be empty.');
    final entries = values.entries.toList();
    final columns = entries
        .map((entry) => _quoteIdentifier(entry.key))
        .join(', ');
    final placeholders = List.filled(entries.length, '?').join(', ');
    _executeSingle(
      database,
      'INSERT INTO ${_quoteIdentifier(table)} ($columns) VALUES ($placeholders)',
      entries.map((entry) => entry.value).toList(),
    );
    return database.lastInsertRowId;
  }

  int _update(
    Database database,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    if (values.isEmpty) throw ArgumentError('Values cannot be empty.');
    final entries = values.entries.toList();
    final set = entries
        .map((entry) => '${_quoteIdentifier(entry.key)} = ?')
        .join(', ');
    final sql =
        'UPDATE ${_quoteIdentifier(table)} SET $set'
        '${where == null || where.isEmpty ? '' : ' WHERE $where'}';
    _executeSingle(database, sql, [
      ...entries.map((entry) => entry.value),
      ...?whereArgs,
    ]);
    return database.updatedRows;
  }

  int _delete(
    Database database,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    final sql =
        'DELETE FROM ${_quoteIdentifier(table)}'
        '${where == null || where.isEmpty ? '' : ' WHERE $where'}';
    _executeSingle(database, sql, whereArgs ?? const []);
    return database.updatedRows;
  }

  Object? _batch(Database database, Map<String, Object?> operation) {
    switch (operation['type']) {
      case 'execute':
        final before = _totalChanges(database);
        _executeSingle(
          database,
          operation['sql'] as String,
          (operation['arguments'] as List?)?.cast<Object?>() ?? const [],
        );
        return _totalChanges(database) - before;
      case 'query':
        final result = _selectSingle(
          database,
          operation['sql'] as String,
          (operation['arguments'] as List?)?.cast<Object?>() ?? const [],
        );
        return {
          'columns': result.columnNames,
          'rows': result.map((row) => row.values.toList()).toList(),
        };
      case 'insert':
        return _insert(
          database,
          operation['table'] as String,
          (operation['values'] as Map).cast<String, Object?>(),
        );
      case 'update':
        return _update(
          database,
          operation['table'] as String,
          (operation['values'] as Map).cast<String, Object?>(),
          where: operation['where'] as String?,
          whereArgs: (operation['whereArgs'] as List?)?.cast<Object?>(),
        );
      case 'delete':
        return _delete(
          database,
          operation['table'] as String,
          where: operation['where'] as String?,
          whereArgs: (operation['whereArgs'] as List?)?.cast<Object?>(),
        );
      default:
        throw ArgumentError.value(operation['type'], 'type');
    }
  }

  void _executeSingle(
    Database database,
    String sql, [
    List<Object?> arguments = const [],
  ]) {
    try {
      final statement = database.prepare(sql, checkNoTail: true);
      try {
        statement.execute(arguments);
      } finally {
        statement.dispose();
      }
    } on SqliteException catch (error) {
      throw _mapException(error, sql);
    }
  }

  ResultSet _selectSingle(
    Database database,
    String sql, [
    List<Object?> arguments = const [],
  ]) {
    try {
      final statement = database.prepare(sql, checkNoTail: true);
      try {
        return statement.select(arguments);
      } finally {
        statement.dispose();
      }
    } on SqliteException catch (error) {
      throw _mapException(error, sql);
    }
  }

  NativeSqliteException _mapException(SqliteException error, String sql) {
    return NativeSqliteException(
      resultCode: error.resultCode,
      extendedResultCode: error.extendedResultCode,
      message: error.message,
      sql: error.causingStatement ?? sql,
    );
  }

  int _databaseVersion(Database database) =>
      _selectSingle(database, 'PRAGMA user_version').first.columnAt(0) as int;

  int _totalChanges(Database database) =>
      _selectSingle(database, 'SELECT total_changes()').first.columnAt(0)
          as int;

  void _migrate(Database database, List<String> statements, int version) {
    _executeSingle(database, 'PRAGMA foreign_keys = OFF');
    _executeSingle(database, 'BEGIN IMMEDIATE');
    try {
      for (final sql in statements) {
        _executeSingle(database, sql);
      }
      final violations = _selectSingle(database, 'PRAGMA foreign_key_check');
      if (violations.isNotEmpty) {
        throw StateError(
          'Migration to version $version left ${violations.length} foreign '
          'key violation(s), first: ${violations.first}.',
        );
      }
      _executeSingle(database, 'PRAGMA user_version = $version');
      _executeSingle(database, 'COMMIT');
    } catch (_) {
      _executeSingle(database, 'ROLLBACK');
      rethrow;
    }
  }
}
