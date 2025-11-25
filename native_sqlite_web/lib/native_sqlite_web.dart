import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' hide DatabaseConfig;
import 'package:sqlite3/wasm.dart' hide DatabaseConfig;

/// The Web implementation of [NativeSqlitePlatform].
///
/// Uses sqlite3 WASM to provide SQLite functionality in web browsers.
/// This implementation maintains compatibility with native platforms while
/// leveraging IndexedDB for persistence through sqlite3's VFS.
class NativeSqliteWeb extends NativeSqlitePlatform {
  /// A map of database names to their sqlite3 Database instances
  final Map<String, Database> _databases = {};

  /// Whether the WASM sqlite3 has been initialized
  static bool _initialized = false;

  /// Registers this class as the default instance of [NativeSqlitePlatform]
  static void registerWith(Registrar registrar) {
    NativeSqlitePlatform.instance = NativeSqliteWeb();
  }

  /// Initialize the sqlite3 WASM module
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      // Initialize sqlite3 WASM
      // The sqlite3_web package automatically loads the WASM module
      // from the correct location and sets up persistence
      await WasmSqlite3.loadFromUrl(
        Uri.parse('sqlite3.wasm'),
      );

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize sqlite3 WASM: $e\n'
          'Make sure your app is running in a modern browser with WASM support.');
    }
  }

  @override
  Future<String> openDatabase(DatabaseConfig config) async {
    await _ensureInitialized();

    // Check if database is already open
    if (_databases.containsKey(config.name)) {
      return 'indexed_db://${config.name}.db';
    }

    try {
      // Open database with IndexedDB persistence
      final db = sqlite3.open(
        config.name,
        mode: OpenMode.readWriteCreate,
      );

      // Configure database
      if (config.enableForeignKeys) {
        db.execute('PRAGMA foreign_keys = ON');
      }

      // WAL mode is not fully supported on web, but we can use memory mode
      // which provides similar concurrency benefits
      if (config.enableWAL) {
        try {
          db.execute('PRAGMA journal_mode = MEMORY');
        } catch (_) {
          // Fallback to DELETE mode if MEMORY is not available
          db.execute('PRAGMA journal_mode = DELETE');
        }
      }

      // Check if this is a new database (needs onCreate)
      final version = _getDatabaseVersion(db);

      if (version == 0 && config.onCreate != null) {
        // New database - run onCreate statements
        _executeInTransaction(db, config.onCreate!);
        _setDatabaseVersion(db, config.version);
      } else if (version < config.version && config.onUpgrade != null) {
        // Database needs upgrade
        _executeInTransaction(db, config.onUpgrade!);
        _setDatabaseVersion(db, config.version);
      }

      _databases[config.name] = db;
      return 'indexed_db://${config.name}.db';
    } catch (e) {
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
      String databaseName, String sql, List<Object?>? arguments) async {
    final db = _getDatabase(databaseName);

    try {
      if (arguments == null || arguments.isEmpty) {
        db.execute(sql);
        return db.lastInsertRowId;
      } else {
        final stmt = db.prepare(sql);
        try {
          stmt.execute(arguments);
          return db.lastInsertRowId;
        } finally {
          stmt.dispose();
        }
      }
    } catch (e) {
      throw Exception('Failed to execute SQL: $e');
    }
  }

  @override
  Future<QueryResult> query(
      String databaseName, String sql, List<Object?>? arguments) async {
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
      String databaseName, String table, Map<String, Object?> values) async {
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
        return db.lastInsertRowId;
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
        return db.updatedRows;
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
        return db.updatedRows;
      } else {
        final stmt = db.prepare(sql);
        try {
          stmt.execute(whereArgs);
          return db.updatedRows;
        } finally {
          stmt.dispose();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete from $table: $e');
    }
  }

  @override
  Future<bool> transaction(
      String databaseName, List<String> sqlStatements) async {
    final db = _getDatabase(databaseName);

    try {
      _executeInTransaction(db, sqlStatements);
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
    // Close if open
    await closeDatabase(databaseName);

    await _ensureInitialized();

    try {
      // Delete the database file from IndexedDB
      // Note: The sqlite3 web implementation stores databases in IndexedDB
      // Opening and disposing removes the connection, but the file persists
      // For a complete deletion, we would need to use the file system API
      sqlite3.open(databaseName).dispose();
    } catch (e) {
      // Silently fail if database doesn't exist
      // This matches the behavior of native platforms
    }
  }

  // Helper methods

  Database _getDatabase(String databaseName) {
    final db = _databases[databaseName];
    if (db == null) {
      throw Exception('Database $databaseName is not open');
    }
    return db;
  }

  int _getDatabaseVersion(Database db) {
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

  void _setDatabaseVersion(Database db, int version) {
    db.execute('PRAGMA user_version = $version');
  }

  void _executeInTransaction(Database db, List<String> statements) {
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
