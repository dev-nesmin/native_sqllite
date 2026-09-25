/// WebAssembly and IndexedDB implementation of the native_sqlite platform API.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';
import 'package:sqlite3/wasm.dart' hide DatabaseConfig;

/// The Web implementation of [NativeSqlitePlatform].
///
/// Runs SQLite compiled to WebAssembly (`web/sqlite3.wasm`, see the README)
/// and persists database files in IndexedDB through sqlite3's
/// [IndexedDbFileSystem]. Every write completes only after it is flushed to
/// IndexedDB.
class NativeSqliteWeb extends NativeSqlitePlatform {
  /// Name of the IndexedDB database holding all SQLite files.
  static const storageName = 'native_sqlite';

  /// A map of database names to their open connections.
  final Map<String, CommonDatabase> _databases = {};
  final Map<String, DatabaseConfig> _databaseConfigs = {};
  final Map<String, int> _referenceCounts = {};
  final Map<String, Future<String>> _opening = {};
  final Map<String, String> _activeTransactions = {};
  bool _didReportWalFallback = false;

  Future<({WasmSqlite3 sqlite, IndexedDbFileSystem storage})>? _runtime;

  /// Registers this class as the default instance of [NativeSqlitePlatform]
  static void registerWith(Registrar registrar) {
    NativeSqlitePlatform.instance = NativeSqliteWeb();
  }

  /// Loads the WASM module and the IndexedDB file system once, shared by
  /// concurrent first calls.
  Future<({WasmSqlite3 sqlite, IndexedDbFileSystem storage})>
  _ensureInitialized() {
    return _runtime ??= () async {
      try {
        final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
        final storage = await IndexedDbFileSystem.open(dbName: storageName);
        sqlite.registerVirtualFileSystem(storage, makeDefault: true);
        return (sqlite: sqlite, storage: storage);
      } catch (e) {
        _runtime = null;
        throw Exception(
          'Failed to initialize sqlite3 WASM: $e\n'
          'Make sure web/sqlite3.wasm exists (see the native_sqlite_web README) '
          'and the browser supports WebAssembly and IndexedDB.',
        );
      }
    }();
  }

  static String _path(String databaseName) => '/$databaseName.db';

  static String _quoteIdentifier(String identifier) =>
      '"${identifier.replaceAll('"', '""')}"';

  /// Waits until pending writes are stored in IndexedDB.
  Future<void> _persist() async => (await _ensureInitialized()).storage.flush();

  @override
  Future<String> openDatabase(DatabaseConfig config) async {
    if (config.directory != null || config.iosAppGroup != null) {
      throw UnsupportedError(
        'Custom database locations are not supported on web.',
      );
    }
    final inFlight = _opening[config.name];
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // The next call retries after the failed owner removed its marker.
      }
      return openDatabase(config);
    }

    if (_databases.containsKey(config.name)) {
      if (!_databaseConfigs[config.name]!.hasSameOpenConfiguration(config)) {
        throw StateError(
          "Database '${config.name}' is already open with a different "
          'configuration.',
        );
      }
      _referenceCounts[config.name] = _referenceCounts[config.name]! + 1;
      return 'indexed_db://${config.name}.db';
    }

    final operation = _openNewDatabase(config);
    _opening[config.name] = operation;
    try {
      return await operation;
    } finally {
      if (identical(_opening[config.name], operation)) {
        final _ = _opening.remove(config.name);
      }
    }
  }

  Future<String> _openNewDatabase(DatabaseConfig config) async {
    final runtime = await _ensureInitialized();

    CommonDatabase? db;
    try {
      db = runtime.sqlite.open(
        _path(config.name),
        mode: config.readOnly ? OpenMode.readOnly : OpenMode.readWriteCreate,
      );
      _executeSingle(db, 'PRAGMA busy_timeout = ${config.busyTimeout}');

      if (config.enableWAL && !config.readOnly) {
        if (kDebugMode && !_didReportWalFallback) {
          _didReportWalFallback = true;
          debugPrint(
            'native_sqlite: WAL mode is not supported on web. '
            'Falling back to MEMORY journal mode.',
          );
        }
        try {
          db.execute('PRAGMA journal_mode = MEMORY');
        } catch (_) {
          db.execute('PRAGMA journal_mode = DELETE');
        }
      }

      final version = _getDatabaseVersion(db);
      if (version > config.version) {
        throw StateError(
          'Database is at version $version, newer than the requested '
          'version ${config.version}; downgrades are not supported.',
        );
      }
      if (config.readOnly && version != config.version) {
        throw StateError(
          'Read-only database is at version $version, expected '
          '${config.version}.',
        );
      } else if (version == 0) {
        _migrate(db, config.onCreate ?? const [], config.version);
      } else if (version < config.version) {
        _migrate(db, config.upgradeStatements(version), config.version);
      }

      // Enabled only after create/upgrade: table rebuilds during a migration
      // must not trigger ON DELETE actions on child tables.
      if (config.enableForeignKeys) {
        db.execute('PRAGMA foreign_keys = ON');
      }
      for (final sql in config.onConfigure ?? const <String>[]) {
        _executeSingle(db, sql);
      }

      _databases[config.name] = db;
      _databaseConfigs[config.name] = config;
      _referenceCounts[config.name] = 1;
      await _persist();
      return 'indexed_db://${config.name}.db';
    } catch (e) {
      _databases.remove(config.name);
      _databaseConfigs.remove(config.name);
      _referenceCounts.remove(config.name);
      db?.dispose();
      throw Exception('Failed to open database ${config.name}: $e');
    }
  }

  @override
  Future<void> closeDatabase(String databaseName) async {
    final references = _referenceCounts[databaseName];
    if (references == null) return;
    if (references > 1) {
      _referenceCounts[databaseName] = references - 1;
      return;
    }
    _disposeDatabase(databaseName);
  }

  void _disposeDatabase(String databaseName) {
    final db = _databases.remove(databaseName);
    _databaseConfigs.remove(databaseName);
    _referenceCounts.remove(databaseName);
    _activeTransactions.remove(databaseName);
    if (db != null) {
      try {
        db.dispose();
      } catch (e) {
        throw Exception('Failed to close database $databaseName: $e');
      }
    }
  }

  @override
  Future<int> execute(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final db = _getDatabase(databaseName);

    try {
      final changesBefore = _totalChanges(db);
      _executeSingle(db, sql, arguments ?? const []);
      await _persist();
      return _totalChanges(db) - changesBefore;
    } on NativeSqliteException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to execute SQL: $e');
    }
  }

  @override
  Future<int> executeInsert(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final db = _getDatabase(databaseName);
    try {
      _executeSingle(db, sql, arguments ?? const []);
      await _persist();
      return db.lastInsertRowId;
    } on NativeSqliteException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to execute insert: $e');
    }
  }

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final db = _getDatabase(databaseName);

    try {
      final selection = _selectSingleWithMetadata(
        db,
        sql,
        arguments ?? const [],
      );
      final resultSet = selection.result;

      // `query` also supports writes that return rows and write PRAGMAs.
      // Flush those before completing so IndexedDB never lags the API call.
      if (!selection.isReadOnly) await _persist();

      // Extract column names
      final columns = resultSet.columnNames;

      // Extract rows
      final rows = resultSet.map((row) {
        return row.values.toList();
      }).toList();

      return QueryResult(columns: columns, rows: rows);
    } on NativeSqliteException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to query database: $e');
    }
  }

  @override
  Future<int> insert(
    String databaseName,
    String table,
    Map<String, Object?> values,
  ) async {
    final db = _getDatabase(databaseName);

    if (values.isEmpty) {
      throw ArgumentError('Values cannot be empty for insert');
    }

    try {
      final entries = values.entries.toList();
      final columns = entries
          .map((entry) => _quoteIdentifier(entry.key))
          .join(', ');
      final placeholders = List.filled(entries.length, '?').join(', ');
      final sql =
          'INSERT INTO ${_quoteIdentifier(table)} ($columns) '
          'VALUES ($placeholders)';

      final stmt = db.prepare(sql, checkNoTail: true);
      try {
        stmt.execute(entries.map((entry) => entry.value).toList());
        final id = db.lastInsertRowId;
        await _persist();
        return id;
      } finally {
        stmt.dispose();
      }
    } on SqliteException catch (e) {
      throw _mapSqliteException(e);
    } catch (e) {
      throw Exception('Failed to insert into $table: $e');
    }
  }

  @override
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = _getDatabase(databaseName);

    if (values.isEmpty) {
      throw ArgumentError('Values cannot be empty for update');
    }

    try {
      final entries = values.entries.toList();
      final setClause = entries
          .map((entry) => '${_quoteIdentifier(entry.key)} = ?')
          .join(', ');
      var sql = 'UPDATE ${_quoteIdentifier(table)} SET $setClause';

      final arguments = entries.map((entry) => entry.value).toList();

      if (where != null && where.isNotEmpty) {
        sql += ' WHERE $where';
        if (whereArgs != null) {
          arguments.addAll(whereArgs);
        }
      }

      final stmt = db.prepare(sql, checkNoTail: true);
      try {
        stmt.execute(arguments);
        final updated = db.updatedRows;
        await _persist();
        return updated;
      } finally {
        stmt.dispose();
      }
    } on SqliteException catch (e) {
      throw _mapSqliteException(e);
    } catch (e) {
      throw Exception('Failed to update $table: $e');
    }
  }

  @override
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = _getDatabase(databaseName);

    try {
      var sql = 'DELETE FROM ${_quoteIdentifier(table)}';

      if (where != null && where.isNotEmpty) {
        sql += ' WHERE $where';
      }

      _executeSingle(db, sql, whereArgs ?? const []);
      final deleted = db.updatedRows;
      await _persist();
      return deleted;
    } on NativeSqliteException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete from $table: $e');
    }
  }

  @override
  Future<void> beginTransaction(
    String databaseName,
    String transactionId,
  ) async {
    final db = _getDatabase(databaseName);
    if (_activeTransactions.containsKey(databaseName)) {
      throw StateError('Database $databaseName already has a transaction');
    }
    db.execute('BEGIN TRANSACTION');
    _activeTransactions[databaseName] = transactionId;
  }

  @override
  Future<void> endTransaction(
    String databaseName,
    String transactionId, {
    required bool commit,
  }) async {
    final db = _transactionDatabase(databaseName, transactionId);
    try {
      db.execute(commit ? 'COMMIT' : 'ROLLBACK');
      await _persist();
    } catch (e) {
      if (commit) {
        try {
          db.execute('ROLLBACK');
        } catch (_) {}
      }
      throw Exception('${commit ? 'Commit' : 'Rollback'} failed: $e');
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
    final db = _transactionDatabase(databaseName, transactionId);
    _executeSingle(db, sql, arguments ?? const []);
    return db.updatedRows;
  }

  @override
  Future<QueryResult> transactionQuery(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) async {
    final db = _transactionDatabase(databaseName, transactionId);
    final result = _selectSingle(db, sql, arguments ?? const []);
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
  ) async {
    final db = _transactionDatabase(databaseName, transactionId);
    return _batchOperation(db, {
          'type': 'insert',
          'table': table,
          'values': values,
        })
        as int;
  }

  @override
  Future<int> transactionUpdate(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = _transactionDatabase(databaseName, transactionId);
    return _batchOperation(db, {
          'type': 'update',
          'table': table,
          'values': values,
          'where': where,
          'whereArgs': whereArgs,
        })
        as int;
  }

  @override
  Future<int> transactionDelete(
    String databaseName,
    String transactionId,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = _transactionDatabase(databaseName, transactionId);
    return _batchOperation(db, {
          'type': 'delete',
          'table': table,
          'where': where,
          'whereArgs': whereArgs,
        })
        as int;
  }

  @override
  Future<List<Object?>> executeBatch(
    String databaseName,
    List<Map<String, Object?>> operations,
  ) async {
    final db = _getDatabase(databaseName);
    db.execute('BEGIN TRANSACTION');
    try {
      final results = [
        for (final operation in operations) _batchOperation(db, operation),
      ];
      db.execute('COMMIT');
      await _persist();
      return results;
    } catch (_) {
      try {
        db.execute('ROLLBACK');
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
    if (directory != null || iosAppGroup != null) {
      throw UnsupportedError(
        'Custom database locations are not supported on web.',
      );
    }
    return 'indexed_db://$databaseName.db';
  }

  @override
  Future<bool> databaseExists(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) async {
    if (directory != null || iosAppGroup != null) {
      throw UnsupportedError(
        'Custom database locations are not supported on web.',
      );
    }
    if (_databases.containsKey(databaseName)) return true;
    final storage = (await _ensureInitialized()).storage;
    return storage.xAccess(_path(databaseName), 0) != 0;
  }

  @override
  Future<void> importDatabase(
    String databaseName,
    Uint8List bytes, {
    String? directory,
    String? iosAppGroup,
    bool overwrite = false,
  }) async {
    if (directory != null || iosAppGroup != null) {
      throw UnsupportedError(
        'Custom database locations are not supported on web.',
      );
    }
    if (_databases.containsKey(databaseName)) {
      throw StateError("Database '$databaseName' is open.");
    }
    final storage = (await _ensureInitialized()).storage;
    final path = _path(databaseName);
    if (storage.xAccess(path, 0) != 0 && !overwrite) return;
    if (overwrite) {
      for (final file in [path, '$path-journal', '$path-wal', '$path-shm']) {
        if (storage.xAccess(file, 0) != 0) storage.xDelete(file, 0);
      }
    }
    final opened = storage.xOpen(
      Sqlite3Filename(path),
      SqlFlag.SQLITE_OPEN_READWRITE | SqlFlag.SQLITE_OPEN_CREATE,
    );
    try {
      opened.file.xTruncate(0);
      opened.file.xWrite(bytes, 0);
      opened.file.xSync(0);
    } finally {
      opened.file.xClose();
    }
    await storage.flush();
  }

  @override
  Future<void> deleteDatabase(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) async {
    if (directory != null || iosAppGroup != null) {
      throw UnsupportedError(
        'Custom database locations are not supported on web.',
      );
    }
    _disposeDatabase(databaseName);
    final storage = (await _ensureInitialized()).storage;
    final path = _path(databaseName);
    for (final file in [path, '$path-journal', '$path-wal']) {
      if (storage.xAccess(file, 0) != 0) storage.xDelete(file, 0);
    }
    await storage.flush();
  }

  // Helper methods

  CommonDatabase _getDatabase(String databaseName) {
    final db = _databases[databaseName];
    if (db == null) {
      throw Exception('Database $databaseName is not open');
    }
    return db;
  }

  CommonDatabase _transactionDatabase(
    String databaseName,
    String transactionId,
  ) {
    if (_activeTransactions[databaseName] != transactionId) {
      throw StateError('Transaction $transactionId is not active');
    }
    return _getDatabase(databaseName);
  }

  Object? _batchOperation(CommonDatabase db, Map<String, Object?> operation) {
    final type = operation['type'] as String?;
    switch (type) {
      case 'execute':
        _executeSingle(
          db,
          operation['sql'] as String,
          (operation['arguments'] as List?)?.cast<Object?>() ?? const [],
        );
        return db.updatedRows;
      case 'query':
        final result = _selectSingle(
          db,
          operation['sql'] as String,
          (operation['arguments'] as List?)?.cast<Object?>() ?? const [],
        );
        return {
          'columns': result.columnNames,
          'rows': result.map((row) => row.values.toList()).toList(),
        };
      case 'insert':
        final values = (operation['values'] as Map).cast<String, Object?>();
        if (values.isEmpty) throw ArgumentError('Values cannot be empty');
        final entries = values.entries.toList();
        final columns = entries.map((e) => _quoteIdentifier(e.key)).join(', ');
        final placeholders = List.filled(entries.length, '?').join(', ');
        _executeSingle(
          db,
          'INSERT INTO ${_quoteIdentifier(operation['table'] as String)} '
          '($columns) VALUES ($placeholders)',
          entries.map((e) => e.value).toList(),
        );
        return db.lastInsertRowId;
      case 'update':
        final values = (operation['values'] as Map).cast<String, Object?>();
        if (values.isEmpty) throw ArgumentError('Values cannot be empty');
        final entries = values.entries.toList();
        final setClause = entries
            .map((e) => '${_quoteIdentifier(e.key)} = ?')
            .join(', ');
        final where = operation['where'] as String?;
        final sql =
            'UPDATE ${_quoteIdentifier(operation['table'] as String)} '
            'SET $setClause${where == null || where.isEmpty ? '' : ' WHERE $where'}';
        _executeSingle(db, sql, [
          ...entries.map((e) => e.value),
          ...(operation['whereArgs'] as List?)?.cast<Object?>() ?? const [],
        ]);
        return db.updatedRows;
      case 'delete':
        final where = operation['where'] as String?;
        final sql =
            'DELETE FROM ${_quoteIdentifier(operation['table'] as String)}'
            '${where == null || where.isEmpty ? '' : ' WHERE $where'}';
        _executeSingle(
          db,
          sql,
          (operation['whereArgs'] as List?)?.cast<Object?>() ?? const [],
        );
        return db.updatedRows;
      default:
        throw ArgumentError.value(type, 'type', 'Unknown batch operation');
    }
  }

  void _executeSingle(
    CommonDatabase db,
    String sql, [
    List<Object?> arguments = const [],
  ]) {
    try {
      final statement = db.prepare(sql, checkNoTail: true);
      try {
        statement.execute(arguments);
      } finally {
        statement.dispose();
      }
    } on SqliteException catch (error) {
      throw _mapSqliteException(error, sql);
    }
  }

  ResultSet _selectSingle(
    CommonDatabase db,
    String sql, [
    List<Object?> arguments = const [],
  ]) => _selectSingleWithMetadata(db, sql, arguments).result;

  ({ResultSet result, bool isReadOnly}) _selectSingleWithMetadata(
    CommonDatabase db,
    String sql, [
    List<Object?> arguments = const [],
  ]) {
    try {
      final statement = db.prepare(sql, checkNoTail: true);
      try {
        final isReadOnly = statement.isReadOnly;
        return (result: statement.select(arguments), isReadOnly: isReadOnly);
      } finally {
        statement.dispose();
      }
    } on SqliteException catch (error) {
      throw _mapSqliteException(error, sql);
    }
  }

  NativeSqliteException _mapSqliteException(
    SqliteException error, [
    String? sql,
  ]) {
    return NativeSqliteException(
      resultCode: error.resultCode,
      extendedResultCode: error.extendedResultCode,
      message: error.message,
      sql: error.causingStatement ?? sql,
    );
  }

  int _getDatabaseVersion(CommonDatabase db) {
    try {
      final result = db.select('PRAGMA user_version');
      if (result.isNotEmpty) {
        return result.first.columnAt(0) as int;
      }
    } catch (_) {
      // If PRAGMA fails, assume version 0
    }
    return 0;
  }

  int _totalChanges(CommonDatabase db) {
    return db.select('SELECT total_changes()').first.columnAt(0) as int;
  }

  void _setDatabaseVersion(CommonDatabase db, int version) {
    db.execute('PRAGMA user_version = $version');
  }

  /// Runs [statements] and sets [version] atomically, with foreign keys
  /// disabled, failing if the result violates a foreign key. Mirrors the
  /// Android and iOS implementations.
  void _migrate(CommonDatabase db, List<String> statements, int version) {
    db.execute('PRAGMA foreign_keys = OFF');
    db.execute('BEGIN IMMEDIATE');
    try {
      for (final sql in statements) {
        _executeSingle(db, sql);
      }
      final violations = db.select('PRAGMA foreign_key_check');
      if (violations.isNotEmpty) {
        throw StateError(
          'Migration to version $version left ${violations.length} '
          'foreign key violation(s), first: ${violations.first}',
        );
      }
      _setDatabaseVersion(db, version);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}
