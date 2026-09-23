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

  Future<({WasmSqlite3 sqlite, IndexedDbFileSystem storage})>? _runtime;

  /// Registers this class as the default instance of [NativeSqlitePlatform]
  static void registerWith(Registrar registrar) {
    NativeSqlitePlatform.instance = NativeSqliteWeb();
  }

  /// Loads the WASM module and the IndexedDB file system once, shared by
  /// concurrent first calls.
  Future<({WasmSqlite3 sqlite, IndexedDbFileSystem storage})> _ensureInitialized() {
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

  /// Waits until pending writes are stored in IndexedDB.
  Future<void> _persist() async => (await _ensureInitialized()).storage.flush();

  @override
  Future<String> openDatabase(DatabaseConfig config) async {
    final runtime = await _ensureInitialized();

    // Reopening replaces the connection, as on Android and iOS, so a new
    // config (e.g. a higher version) is applied.
    await closeDatabase(config.name);

    CommonDatabase? db;
    try {
      db = runtime.sqlite.open(_path(config.name));

      if (config.enableWAL) {
        if (kDebugMode) {
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
      if (version == 0) {
        _migrate(db, config.onCreate ?? const [], config.version);
      } else if (version < config.version) {
        _migrate(db, config.upgradeStatements(version), config.version);
      }

      // Enabled only after create/upgrade: table rebuilds during a migration
      // must not trigger ON DELETE actions on child tables.
      if (config.enableForeignKeys) {
        db.execute('PRAGMA foreign_keys = ON');
      }

      _databases[config.name] = db;
      await _persist();
      return 'indexed_db://${config.name}.db';
    } catch (e) {
      db?.dispose();
      throw Exception('Failed to open database ${config.name}: $e');
    }
  }

  @override
  Future<void> closeDatabase(String databaseName) async {
    final db = _databases.remove(databaseName);
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
      if (arguments == null || arguments.isEmpty) {
        db.execute(sql);
      } else {
        final stmt = db.prepare(sql);
        try {
          stmt.execute(arguments);
        } finally {
          stmt.dispose();
        }
      }
      await _persist();
      return db.updatedRows;
    } catch (e) {
      throw Exception('Failed to execute SQL: $e');
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
      final ResultSet resultSet;

      if (arguments == null || arguments.isEmpty) {
        resultSet = db.select(sql);
      } else {
        final stmt = db.prepare(sql);
        try {
          resultSet = stmt.select(arguments);
        } finally {
          stmt.dispose();
        }
      }

      // Extract column names
      final columns = resultSet.columnNames;

      // Extract rows
      final rows = resultSet.map((row) {
        return row.values.toList();
      }).toList();

      return QueryResult(columns: columns, rows: rows);
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
      final columns = values.keys.join(', ');
      final placeholders = List.filled(values.length, '?').join(', ');
      final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';

      final stmt = db.prepare(sql);
      try {
        stmt.execute(values.values.toList());
        final id = db.lastInsertRowId;
        await _persist();
        return id;
      } finally {
        stmt.dispose();
      }
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
      final setClause = values.keys.map((key) => '$key = ?').join(', ');
      var sql = 'UPDATE $table SET $setClause';

      final arguments = values.values.toList();

      if (where != null && where.isNotEmpty) {
        sql += ' WHERE $where';
        if (whereArgs != null) {
          arguments.addAll(whereArgs);
        }
      }

      final stmt = db.prepare(sql);
      try {
        stmt.execute(arguments);
        final updated = db.updatedRows;
        await _persist();
        return updated;
      } finally {
        stmt.dispose();
      }
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
      var sql = 'DELETE FROM $table';

      if (where != null && where.isNotEmpty) {
        sql += ' WHERE $where';
      }

      if (whereArgs == null || whereArgs.isEmpty) {
        db.execute(sql);
      } else {
        final stmt = db.prepare(sql);
        try {
          stmt.execute(whereArgs);
        } finally {
          stmt.dispose();
        }
      }
      final deleted = db.updatedRows;
      await _persist();
      return deleted;
    } catch (e) {
      throw Exception('Failed to delete from $table: $e');
    }
  }

  @override
  Future<bool> transaction(
    String databaseName,
    List<String> sqlStatements,
  ) async {
    final db = _getDatabase(databaseName);

    try {
      _executeInTransaction(db, sqlStatements);
      await _persist();
      return true;
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  @override
  Future<String?> getDatabasePath(String databaseName) async {
    if (_databases.containsKey(databaseName)) {
      return 'indexed_db://$databaseName.db';
    }
    return null;
  }

  @override
  Future<void> deleteDatabase(String databaseName) async {
    await closeDatabase(databaseName);
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
        db.execute(sql);
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

  void _executeInTransaction(CommonDatabase db, List<String> statements) {
    db.execute('BEGIN TRANSACTION');
    try {
      for (final sql in statements) {
        db.execute(sql);
      }
      db.execute('COMMIT');
    } catch (e) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}
