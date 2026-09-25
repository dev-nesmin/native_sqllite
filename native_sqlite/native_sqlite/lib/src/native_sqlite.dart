import 'dart:async';

import 'package:flutter/services.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';

import 'inspector_connect.dart';
import 'sql_identifier.dart';
import 'uuid.dart';

final Object _transactionZoneKey = Object();

/// SQLite conflict resolution used by [NativeSqliteDatabase.insert].
enum ConflictAlgorithm {
  /// Roll back the current transaction when a constraint fails.
  rollback,

  /// Abort the statement while preserving an outer transaction.
  abort,

  /// Stop at the failing row while preserving earlier row changes.
  fail,

  /// Skip the row that violates a constraint.
  ignore,

  /// Delete the conflicting row and insert the new row.
  replace,
}

/// Entry point for opening and deleting SQLite databases.
///
/// Database operations live on the [NativeSqliteDatabase] returned by [open],
/// so a database name cannot accidentally be passed to the wrong operation.
///
/// ```dart
/// final db = await NativeSqlite.open(
///   DatabaseConfig(
///     name: 'app',
///     onCreate: ['CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT)'],
///   ),
/// );
/// await db.insert('notes', {'body': 'Hello'});
/// final notes = await db.query('SELECT * FROM notes');
/// await db.close();
/// ```
abstract final class NativeSqlite {
  static final Map<String, Set<NativeSqliteDatabase>> _openHandles = {};
  static final Map<String, _DatabaseState> _states = {};

  static NativeSqlitePlatform get _platform {
    final platform = NativeSqlitePlatform.instance;
    if (platform == null) {
      if (ServicesBinding.rootIsolateToken == null) {
        throw StateError(
          'NativeSqlite is not registered in this background isolate. On the '
          'root isolate, capture ServicesBinding.rootIsolateToken. In the '
          'background isolate call BackgroundIsolateBinaryMessenger.'
          'ensureInitialized(token), then DartPluginRegistrant.'
          'ensureInitialized(), before using NativeSqlite.',
        );
      }
      throw StateError(
        'No platform implementation found for NativeSqlite. '
        'Make sure you have added the platform-specific dependencies.',
      );
    }
    return platform;
  }

  /// Whether this isolate owns at least one open handle for [databaseName].
  static bool isOpen(String databaseName) =>
      _openHandles[databaseName]?.any((handle) => !handle.isClosed) ?? false;

  /// Whether a database file exists at the requested platform location.
  static Future<bool> databaseExists(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) {
    final location = DatabaseConfig(
      name: databaseName,
      directory: directory,
      iosAppGroup: iosAppGroup,
    );
    return _platform.databaseExists(
      databaseName,
      directory: location.directory,
      iosAppGroup: location.iosAppGroup,
    );
  }

  /// Closes every handle currently owned by this isolate.
  static Future<void> closeAll() async {
    final handles = [for (final databases in _openHandles.values) ...databases];
    for (final handle in handles) {
      await handle.close();
    }
  }

  /// Opens or creates a database and returns an owned handle to it.
  ///
  /// If a database with the same name and configuration is already open, the
  /// platform retains the existing connection. Opening the same name with a
  /// different configuration throws. Every successful call must be paired
  /// with [NativeSqliteDatabase.close].
  static Future<NativeSqliteDatabase> open(DatabaseConfig config) async {
    final platform = _platform;
    final state = _states.putIfAbsent(config.name, _DatabaseState.new);
    if (Zone.current[_transactionZoneKey] == state) {
      throw StateError('Cannot open a database inside its transaction.');
    }
    final path = await state.lock.synchronized(
      () => platform.openDatabase(config),
    );
    final database = NativeSqliteDatabase._(
      platform: platform,
      config: config,
      path: path,
      state: state,
    );
    _openHandles.putIfAbsent(config.name, () => {}).add(database);
    InspectorConnect.init(database);
    return database;
  }

  /// Copies a complete SQLite file from [assetKey] when needed, then opens it.
  ///
  /// Existing files are preserved unless [overwrite] is true. Importing over
  /// an open database is rejected. The asset's `PRAGMA user_version` must
  /// match [DatabaseConfig.version] for a read-only open, or it is migrated
  /// normally for a writable open.
  static Future<NativeSqliteDatabase> openFromAsset(
    DatabaseConfig config,
    String assetKey, {
    AssetBundle? bundle,
    bool overwrite = false,
  }) async {
    if (isOpen(config.name)) {
      throw StateError(
        'Close every handle for "${config.name}" before importing an asset.',
      );
    }
    final platform = _platform;
    final exists = await platform.databaseExists(
      config.name,
      directory: config.directory,
      iosAppGroup: config.iosAppGroup,
    );
    if (overwrite || !exists) {
      final data = await (bundle ?? rootBundle).load(assetKey);
      await platform.importDatabase(
        config.name,
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        directory: config.directory,
        iosAppGroup: config.iosAppGroup,
        overwrite: overwrite,
      );
    }
    return open(config);
  }

  /// Gets the deterministic platform path for [databaseName].
  ///
  /// Prefer [NativeSqliteDatabase.path] when the database is already open.
  static Future<String> getDatabasePath(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) {
    final location = DatabaseConfig(
      name: databaseName,
      directory: directory,
      iosAppGroup: iosAppGroup,
    );
    return _platform.getDatabasePath(
      databaseName,
      directory: location.directory,
      iosAppGroup: location.iosAppGroup,
    );
  }

  /// Closes every open handle for [databaseName] and deletes its files.
  static Future<void> deleteDatabase(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) async {
    final location = DatabaseConfig(
      name: databaseName,
      directory: directory,
      iosAppGroup: iosAppGroup,
    );
    final state = _states[databaseName];
    if (state != null && Zone.current[_transactionZoneKey] == state) {
      throw StateError('Cannot delete a database inside its transaction.');
    }
    Future<void> operation() => _platform.deleteDatabase(
      databaseName,
      directory: location.directory,
      iosAppGroup: location.iosAppGroup,
    );
    if (state == null) {
      await operation();
    } else {
      await state.lock.synchronized(operation);
    }
    final handles = _openHandles.remove(databaseName);
    if (handles != null) {
      for (final handle in handles) {
        handle._markClosed();
      }
    }
    InspectorConnect.unregisterDatabase(databaseName);
  }

  static void _release(NativeSqliteDatabase database) {
    final handles = _openHandles[database.name];
    handles?.remove(database);
    if (handles?.isEmpty ?? false) {
      _openHandles.remove(database.name);
    }
    InspectorConnect.unregister(database);
  }
}

/// An owned connection reference returned by [NativeSqlite.open].
///
/// A handle is tied to exactly one database. Calling [close] releases this
/// handle's reference; subsequent operations on it throw [StateError].
final class NativeSqliteDatabase {
  NativeSqliteDatabase._({
    required NativeSqlitePlatform platform,
    required this.config,
    required this.path,
    required _DatabaseState state,
  }) : _platform = platform,
       _state = state;

  final NativeSqlitePlatform _platform;
  final _DatabaseState _state;

  /// The configuration used to open this handle.
  final DatabaseConfig config;

  /// Absolute path returned by the platform when the database was opened.
  final String path;

  bool _closed = false;
  Future<void>? _closeFuture;

  /// Database name from [config].
  String get name => config.name;

  /// Schema version from [config].
  int get version => config.version;

  /// Whether this handle has released its connection reference.
  bool get isClosed => _closed;

  /// Executes a single SQL statement and returns its affected-row count.
  Future<int> execute(String sql, [List<Object?>? arguments]) {
    return _runWrite(() => _platform.execute(name, sql, arguments));
  }

  /// Executes a raw INSERT and returns its SQLite row ID.
  Future<int> executeInsert(String sql, [List<Object?>? arguments]) {
    return _runWrite(() => _platform.executeInsert(name, sql, arguments));
  }

  /// Executes a query and returns its columns and rows.
  Future<QueryResult> query(String sql, [List<Object?>? arguments]) {
    return _run(() => _platform.query(name, sql, arguments));
  }

  /// Re-runs [sql] when one of [tables] changes and emits distinct results.
  ///
  /// Changes made through this Dart API trigger an immediate refresh. The
  /// query is also polled every [pollInterval], which makes writes performed
  /// by native code or another SQLite connection observable. The first result
  /// is emitted as soon as the stream is listened to.
  Stream<QueryResult> watch(
    String sql,
    Iterable<String> tables, {
    List<Object?>? arguments,
    Duration pollInterval = const Duration(milliseconds: 500),
  }) {
    _checkOpen();
    final watchedTables = tables
        .map((table) => table.trim().toLowerCase())
        .where((table) => table.isNotEmpty)
        .toSet();
    if (watchedTables.isEmpty) {
      throw ArgumentError.value(tables, 'tables', 'must not be empty');
    }
    if (pollInterval <= Duration.zero) {
      throw ArgumentError.value(
        pollInterval,
        'pollInterval',
        'must be greater than zero',
      );
    }

    late StreamController<QueryResult> controller;
    StreamSubscription<Set<String>>? changes;
    Timer? timer;
    var refreshing = false;
    var refreshAgain = false;
    QueryResult? previous;

    Future<void> refresh() async {
      if (refreshing) {
        refreshAgain = true;
        return;
      }
      refreshing = true;
      try {
        do {
          refreshAgain = false;
          final result = await query(sql, arguments);
          if (result != previous && !controller.isClosed) {
            previous = result;
            controller.add(result);
          }
        } while (refreshAgain && !controller.isClosed);
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      } finally {
        refreshing = false;
      }
    }

    controller = StreamController<QueryResult>(
      onListen: () {
        unawaited(refresh());
        changes = _state.changes.listen((changedTables) {
          if (changedTables.isEmpty ||
              changedTables.any(watchedTables.contains)) {
            unawaited(refresh());
          }
        });
        timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
      },
      onCancel: () async {
        timer?.cancel();
        await changes?.cancel();
      },
    );
    return controller.stream;
  }

  /// Table names changed through this isolate's Dart API.
  ///
  /// An empty set means a raw statement changed an unknown set of tables.
  /// Native-only writes are detected by [watch]'s polling fallback and are
  /// not emitted here.
  Stream<Set<String>> get tableChanges => _state.changes;

  /// Inserts [values] into [table] and returns the inserted row ID.
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
  }) {
    if (values.isEmpty) throw ArgumentError('Values cannot be empty.');
    if (conflictAlgorithm == ConflictAlgorithm.abort) {
      return _runWrite(
        () => _platform.insert(name, table, values),
        tables: {table},
      );
    }
    final entries = values.entries.toList();
    final columns = entries
        .map((entry) => quoteSqlIdentifier(entry.key))
        .join(', ');
    final placeholders = List.filled(entries.length, '?').join(', ');
    final algorithm = conflictAlgorithm.name.toUpperCase();
    return executeInsert(
      'INSERT OR $algorithm INTO ${quoteSqlIdentifier(table)} '
      '($columns) VALUES ($placeholders)',
      entries.map((entry) => entry.value).toList(),
    );
  }

  /// Inserts [values] or updates the row matching [conflictColumns].
  ///
  /// With no [updateValues], every inserted non-conflict column is assigned
  /// from SQLite's `excluded` row. Pass an empty map for `DO NOTHING`.
  /// Returns SQLite's affected-row count.
  Future<int> upsert(
    String table,
    Map<String, Object?> values, {
    required List<String> conflictColumns,
    Map<String, Object?>? updateValues,
  }) {
    if (values.isEmpty) throw ArgumentError('Values cannot be empty.');
    if (conflictColumns.isEmpty) {
      throw ArgumentError('conflictColumns cannot be empty.');
    }
    final entries = values.entries.toList();
    final columns = entries
        .map((entry) => quoteSqlIdentifier(entry.key))
        .join(', ');
    final placeholders = List.filled(entries.length, '?').join(', ');
    final conflict = conflictColumns.map(quoteSqlIdentifier).join(', ');
    final updates =
        updateValues ??
        {
          for (final entry in entries)
            if (!conflictColumns.contains(entry.key)) entry.key: entry.value,
        };
    final arguments = <Object?>[...entries.map((entry) => entry.value)];
    final action = updates.isEmpty
        ? 'DO NOTHING'
        : updateValues == null
        ? 'DO UPDATE SET ${updates.keys.map((column) {
            final quoted = quoteSqlIdentifier(column);
            return '$quoted = excluded.$quoted';
          }).join(', ')}'
        : 'DO UPDATE SET ${updates.keys.map((column) {
            arguments.add(updates[column]);
            return '${quoteSqlIdentifier(column)} = ?';
          }).join(', ')}';
    return execute(
      'INSERT INTO ${quoteSqlIdentifier(table)} ($columns) '
      'VALUES ($placeholders) ON CONFLICT ($conflict) $action',
      arguments,
    );
  }

  /// Updates rows in [table] and returns the affected-row count.
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _validateWhereArguments(where, whereArgs);
    return _runWrite(
      () => _platform.update(
        name,
        table,
        values,
        where: where,
        whereArgs: whereArgs,
      ),
      tables: {table},
    );
  }

  /// Deletes matching rows from [table] and returns the affected-row count.
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    _validateWhereArguments(where, whereArgs);
    return _runWrite(
      () => _platform.delete(name, table, where: where, whereArgs: whereArgs),
      tables: {table},
    );
  }

  /// Runs [action] atomically and commits its changes when it completes.
  ///
  /// Throwing from [action] rolls the transaction back. Calls made through
  /// this database handle wait until the transaction completes. Use the
  /// supplied [NativeSqliteTransaction] inside the callback; nested
  /// transactions and direct handle operations from the callback throw.
  Future<T> transaction<T>(
    Future<T> Function(NativeSqliteTransaction transaction) action,
  ) {
    _checkOpen();
    if (Zone.current[_transactionZoneKey] == _state) {
      throw StateError('Nested transactions are not supported.');
    }
    return _state.lock.synchronized(() async {
      _checkOpen();
      final transactionId = NativeSqliteUuid.generate();
      final transaction = NativeSqliteTransaction._(
        platform: _platform,
        databaseName: name,
        transactionId: transactionId,
      );
      await _platform.beginTransaction(name, transactionId);
      try {
        final value = await runZoned(
          () => action(transaction),
          zoneValues: {_transactionZoneKey: _state},
        );
        transaction._finish();
        await _platform.endTransaction(name, transactionId, commit: true);
        if (transaction._hasChanges) {
          _state.notifyChanges(
            transaction._hasUnknownChanges
                ? const {}
                : transaction._changedTables,
          );
        }
        return value;
      } catch (error, stackTrace) {
        transaction._finish();
        try {
          await _platform.endTransaction(name, transactionId, commit: false);
        } catch (_) {
          // Preserve the error that caused the rollback.
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  /// Creates a batch whose operations are sent in one platform call.
  NativeSqliteBatch batch() {
    _checkOpen();
    return NativeSqliteBatch._(this);
  }

  /// Releases this handle's reference to the shared platform connection.
  ///
  /// Closing an already closed handle is a no-op.
  Future<void> close() {
    if (Zone.current[_transactionZoneKey] == _state) {
      throw StateError('Cannot close a database inside its transaction.');
    }
    return _closeFuture ??= _state.lock.synchronized(_close);
  }

  Future<void> _close() async {
    if (_closed) return;
    await _platform.closeDatabase(name);
    _markClosed();
    NativeSqlite._release(this);
  }

  void _checkOpen() {
    if (_closed) {
      throw StateError('Database handle "$name" is closed.');
    }
  }

  Future<T> _run<T>(Future<T> Function() action) {
    _checkOpen();
    if (Zone.current[_transactionZoneKey] == _state) {
      throw StateError(
        'Use the transaction object for operations inside a transaction.',
      );
    }
    return _state.lock.synchronized(() {
      _checkOpen();
      return action();
    });
  }

  Future<T> _runWrite<T>(
    Future<T> Function() action, {
    Set<String> tables = const {},
  }) async {
    final value = await _run(action);
    _state.notifyChanges(tables);
    return value;
  }

  void _markClosed() {
    _closed = true;
  }
}

/// Operations available inside [NativeSqliteDatabase.transaction].
final class NativeSqliteTransaction {
  NativeSqliteTransaction._({
    required NativeSqlitePlatform platform,
    required this.databaseName,
    required this.transactionId,
  }) : _platform = platform;

  final NativeSqlitePlatform _platform;
  final String databaseName;
  final String transactionId;
  bool _active = true;
  final Set<String> _changedTables = {};
  bool _hasChanges = false;
  bool _hasUnknownChanges = false;

  Future<int> execute(String sql, [List<Object?>? arguments]) {
    _checkActive();
    _hasChanges = true;
    _hasUnknownChanges = true;
    return _platform.transactionExecute(
      databaseName,
      transactionId,
      sql,
      arguments,
    );
  }

  Future<QueryResult> query(String sql, [List<Object?>? arguments]) {
    _checkActive();
    return _platform.transactionQuery(
      databaseName,
      transactionId,
      sql,
      arguments,
    );
  }

  Future<int> insert(String table, Map<String, Object?> values) {
    _checkActive();
    _recordTable(table);
    return _platform.transactionInsert(
      databaseName,
      transactionId,
      table,
      values,
    );
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _checkActive();
    _recordTable(table);
    _validateWhereArguments(where, whereArgs);
    return _platform.transactionUpdate(
      databaseName,
      transactionId,
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    _checkActive();
    _recordTable(table);
    _validateWhereArguments(where, whereArgs);
    return _platform.transactionDelete(
      databaseName,
      transactionId,
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  void _checkActive() {
    if (!_active) {
      throw StateError('This transaction has already completed.');
    }
  }

  void _finish() => _active = false;

  void _recordTable(String table) {
    _hasChanges = true;
    _changedTables.add(table);
  }
}

/// A collection of parameterized operations committed in one platform call.
final class NativeSqliteBatch {
  NativeSqliteBatch._(this._database);

  final NativeSqliteDatabase _database;
  final List<Map<String, Object?>> _operations = [];
  bool _committed = false;

  void execute(String sql, [List<Object?>? arguments]) {
    _add({'type': 'execute', 'sql': sql, 'arguments': arguments});
  }

  void query(String sql, [List<Object?>? arguments]) {
    _add({'type': 'query', 'sql': sql, 'arguments': arguments});
  }

  void insert(String table, Map<String, Object?> values) {
    _add({'type': 'insert', 'table': table, 'values': values});
  }

  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    _validateWhereArguments(where, whereArgs);
    _add({
      'type': 'update',
      'table': table,
      'values': values,
      'where': where,
      'whereArgs': whereArgs,
    });
  }

  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _validateWhereArguments(where, whereArgs);
    _add({
      'type': 'delete',
      'table': table,
      'where': where,
      'whereArgs': whereArgs,
    });
  }

  Future<List<Object?>> commit() async {
    if (_committed) throw StateError('This batch has already been committed.');
    _committed = true;
    final results = await _database._run(
      () => _database._platform.executeBatch(
        _database.name,
        List.unmodifiable(_operations),
      ),
    );
    final changedTables = <String>{};
    var hasUnknownChanges = false;
    for (final operation in _operations) {
      switch (operation['type']) {
        case 'insert':
          changedTables.add(operation['table']! as String);
          break;
        case 'update':
          changedTables.add(operation['table']! as String);
          break;
        case 'delete':
          changedTables.add(operation['table']! as String);
          break;
        case 'execute':
          hasUnknownChanges = true;
          break;
        case 'query':
          break;
      }
    }
    if (hasUnknownChanges || changedTables.isNotEmpty) {
      _database._state.notifyChanges(
        hasUnknownChanges ? const {} : changedTables,
      );
    }
    if (results.length != _operations.length) {
      throw StateError(
        'Batch returned ${results.length} results for '
        '${_operations.length} operations.',
      );
    }
    return [
      for (var index = 0; index < results.length; index++)
        if (_operations[index]['type'] == 'query')
          QueryResult.fromMap(
            (results[index]! as Map<Object?, Object?>).cast<String, dynamic>(),
          )
        else
          results[index],
    ];
  }

  void _add(Map<String, Object?> operation) {
    if (_committed) throw StateError('This batch has already been committed.');
    _operations.add(operation);
  }
}

void _validateWhereArguments(String? where, List<Object?>? whereArgs) {
  if (whereArgs != null &&
      whereArgs.isNotEmpty &&
      (where?.trim().isEmpty ?? true)) {
    throw ArgumentError.value(
      whereArgs,
      'whereArgs',
      'requires a non-empty where clause',
    );
  }
}

final class _DatabaseState {
  final _AsyncLock lock = _AsyncLock();
  final StreamController<Set<String>> _changes =
      StreamController<Set<String>>.broadcast(sync: true);

  Stream<Set<String>> get changes => _changes.stream;

  void notifyChanges(Set<String> tables) {
    _changes.add({for (final table in tables) table.toLowerCase()});
  }
}

final class _AsyncLock {
  Future<void> _tail = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final previous = _tail;
    final released = Completer<void>();
    _tail = released.future;
    return previous.then((_) => action()).whenComplete(released.complete);
  }
}
