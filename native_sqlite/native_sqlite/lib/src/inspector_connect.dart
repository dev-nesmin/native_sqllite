// Portions adapted from Isar Connect.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart'
    show QueryResult;

import '../inspector_protocol.dart';
import 'native_sqlite.dart';
import 'sql_identifier.dart';

typedef _InspectorHandler = Future<Object?> Function(Map<String, Object?> args);

/// Registers the debug-only VM service API used by the native_sqlite DevTools
/// extension.
class InspectorConnect {
  static final Map<String, Set<NativeSqliteDatabase>> _databases = {};
  static final Map<String, _InspectorHandler> _handlers = {};
  static bool _initialized = false;

  /// Whether inspector service extensions should be registered in debug mode.
  static bool enabled = true;

  /// Whether [init] should print the DevTools hint.
  static bool printBanner = true;

  /// Disables inspector code at compile time with
  /// `--dart-define=NATIVE_SQLITE_INSPECTOR=false`.
  static const bool _enabledByEnvironment = bool.fromEnvironment(
    'NATIVE_SQLITE_INSPECTOR',
    defaultValue: true,
  );

  /// Registers [database] for discovery by DevTools.
  static void init(NativeSqliteDatabase database) {
    if (!kDebugMode ||
        !enabled ||
        !_enabledByEnvironment ||
        ServicesBinding.rootIsolateToken == null) {
      return;
    }

    _databases.putIfAbsent(database.name, () => {}).add(database);
    if (_initialized) return;

    _initialized = true;
    _createHandlers();
    for (final entry in _handlers.entries) {
      _registerExtension(entry.key, entry.value);
    }
    if (printBanner) {
      debugPrint('Native SQLite Inspector: Open DevTools → native_sqlite');
    }
  }

  /// Removes a closed database from inspector discovery.
  static void unregister(NativeSqliteDatabase database) {
    final handles = _databases[database.name];
    handles?.remove(database);
    if (handles?.isEmpty ?? false) _databases.remove(database.name);
  }

  /// Removes all handles for [databaseName].
  static void unregisterDatabase(String databaseName) {
    _databases.remove(databaseName);
  }

  @visibleForTesting
  static bool debugIsRegistered(String databaseName) =>
      _databases.containsKey(databaseName);

  @visibleForTesting
  static void debugClearDatabases() => _databases.clear();

  @visibleForTesting
  static Future<void> debugRequireTable(String database, String table) =>
      _requireTable(database, table);

  @visibleForTesting
  static Future<String> debugResolvePrimaryKeyColumn(
    String database,
    String table,
    String? requested,
  ) async {
    final schema = await _getTableSchema(database, table);
    if (schema.primaryKeys.length != 1) {
      throw StateError(
        'Inspector row updates require exactly one primary-key column',
      );
    }
    final actual = schema.primaryKeys.single;
    if (requested != null && requested != actual) {
      throw ArgumentError.value(
        requested,
        'pkColumn',
        'is not the primary-key column for $table',
      );
    }
    return actual;
  }

  /// Invokes the same typed handler used by the VM service registration.
  @visibleForTesting
  static Future<Object?> debugHandle(
    String method, [
    Map<String, Object?> args = const {},
  ]) async {
    if (_handlers.isEmpty) _createHandlers();
    final handler = _handlers[method];
    if (handler == null) throw ArgumentError.value(method, 'method');
    return handler(args);
  }

  static void _createHandlers() {
    if (_handlers.isNotEmpty) return;
    _handlers.addAll({
      NativeSqliteInspectorProtocol.getInfo: (_) async => const InspectorInfo(
        protocol: NativeSqliteInspectorProtocol.version,
        package: 'native_sqlite',
        capabilities: [
          'browse',
          'schema',
          'sql',
          'writeSql',
          'updateRecord',
          'deleteRecord',
          'dataVersion',
        ],
      ).toJson(),
      NativeSqliteInspectorProtocol.listDatabases: (_) => _listDatabases(),
      NativeSqliteInspectorProtocol.getSchema: (json) async {
        final request = InspectorDatabaseRequest.fromJson(json);
        _requireRegisteredDatabase(request.database);
        return (await _getTablesForDatabase(
          request.database,
        )).map((table) => table.toJson()).toList();
      },
      NativeSqliteInspectorProtocol.executeQuery: (json) async {
        final request = InspectorBrowseRequest.fromJson(json);
        return (await _browse(request)).toJson();
      },
      NativeSqliteInspectorProtocol.executeSql: (json) async {
        final request = InspectorSqlRequest.fromJson(json);
        return (await _executeSql(request)).toJson();
      },
      NativeSqliteInspectorProtocol.getDataVersion: (json) async {
        final request = InspectorDatabaseRequest.fromJson(json);
        _requireRegisteredDatabase(request.database);
        final result = await _database(
          request.database,
        ).query('PRAGMA data_version');
        return result.rows.first.first as int;
      },
      NativeSqliteInspectorProtocol.updateRecord: (json) async {
        final request = InspectorMutationRequest.fromJson(json);
        await _mutate(request, delete: false);
        return true;
      },
      NativeSqliteInspectorProtocol.deleteRecord: (json) async {
        final request = InspectorMutationRequest.fromJson(json);
        await _mutate(request, delete: true);
        return true;
      },
    });
  }

  static void _registerExtension(String method, _InspectorHandler handler) {
    developer.registerExtension(method, (_, parameters) async {
      try {
        final encoded = parameters['args'];
        final args = encoded == null
            ? <String, Object?>{}
            : (jsonDecode(encoded) as Map).cast<String, Object?>();
        final result = await handler(args);
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'result': result}),
        );
      } catch (error) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          error.toString(),
        );
      }
    });
  }

  static Future<List<Map<String, Object?>>> _listDatabases() async {
    final databases = <Map<String, Object?>>[];
    for (final name in _databases.keys.toList()..sort()) {
      try {
        final database = _database(name);
        databases.add(
          InspectorDatabaseInfo(
            name: name,
            path: database.path,
            tables: await _getTablesForDatabase(name),
            size: await _getDatabaseSize(name),
          ).toJson(),
        );
      } catch (_) {
        // One unavailable handle must not hide healthy databases.
      }
    }
    return databases;
  }

  static Future<InspectorQueryPage> _browse(
    InspectorBrowseRequest request,
  ) async {
    _requireRegisteredDatabase(request.database);
    final schema = await _getTableSchema(request.database, request.table);
    final limit = request.limit.clamp(1, 500);
    final offset = request.offset < 0 ? 0 : request.offset;
    final table = quoteSqlIdentifier(request.table);
    final orderBy = schema.usesRowId
        ? 'rowid'
        : schema.primaryKeys.isEmpty
        ? schema.columns
              .map((column) => quoteSqlIdentifier(column.name))
              .join(', ')
        : schema.primaryKeys.map(quoteSqlIdentifier).join(', ');
    final select = schema.usesRowId
        ? 'SELECT rowid AS ${quoteSqlIdentifier(NativeSqliteInspectorProtocol.rowIdKey)}, *'
        : 'SELECT *';
    final result = await _database(request.database).query(
      '$select FROM $table${orderBy.isEmpty ? '' : ' ORDER BY $orderBy'} '
      'LIMIT ? OFFSET ?',
      [limit, offset],
    );
    final countResult = await _database(
      request.database,
    ).query('SELECT COUNT(*) FROM $table');
    final count = countResult.rows.first.first as int;

    final hiddenRowId = schema.usesRowId ? 1 : 0;
    final columns = result.columns.skip(hiddenRowId).toList();
    final rows = <List<Object?>>[];
    final identities = <InspectorRecordIdentity?>[];
    for (final row in result.rows) {
      rows.add(row.skip(hiddenRowId).map(_jsonValue).toList());
      if (schema.isView) {
        identities.add(null);
      } else if (schema.usesRowId) {
        identities.add(
          InspectorRecordIdentity(
            kind: 'rowid',
            values: {
              NativeSqliteInspectorProtocol.rowIdKey: _identityString(
                row.first,
              ),
            },
          ),
        );
      } else {
        identities.add(
          InspectorRecordIdentity(
            kind: 'primaryKey',
            values: {
              for (final key in schema.primaryKeys)
                key: _identityString(row[result.columns.indexOf(key)]),
            },
          ),
        );
      }
    }
    return InspectorQueryPage(
      columns: columns,
      rows: rows,
      identities: identities,
      count: count,
    );
  }

  static Future<InspectorSqlResult> _executeSql(
    InspectorSqlRequest request,
  ) async {
    _requireRegisteredDatabase(request.database);
    final sql = request.sql.trim();
    if (sql.isEmpty) throw ArgumentError.value(sql, 'sql', 'is empty');
    final readOnly = _isReadOnlySql(sql);
    if (!readOnly && !request.allowWrite) {
      throw StateError(
        'This statement may write to the database. Enable SQL writes first.',
      );
    }

    final database = _database(request.database);
    final before = readOnly ? 0 : await _totalChanges(database);
    QueryResult result;
    try {
      result = await database.query(sql);
    } catch (_) {
      if (readOnly) rethrow;
      await database.execute(sql);
      result = const QueryResult(columns: [], rows: []);
    }
    final affectedRows = readOnly
        ? 0
        : (await _totalChanges(database)) - before;
    final truncated =
        result.rows.length > NativeSqliteInspectorProtocol.maxSqlRows;
    if (!readOnly) _notifyDataChanged();
    return InspectorSqlResult(
      columns: result.columns,
      rows: result.rows
          .take(NativeSqliteInspectorProtocol.maxSqlRows)
          .map((row) => row.map(_jsonValue).toList())
          .toList(),
      affectedRows: affectedRows,
      truncated: truncated,
      readOnly: readOnly,
    );
  }

  static Future<void> _mutate(
    InspectorMutationRequest request, {
    required bool delete,
  }) async {
    _requireRegisteredDatabase(request.database);
    final schema = await _getTableSchema(request.database, request.table);
    if (schema.isView) throw StateError('Views cannot be edited.');
    if (!delete && request.values.isEmpty) {
      throw ArgumentError.value(request.values, 'values', 'is empty');
    }
    final columnNames = schema.columns.map((column) => column.name).toSet();
    final unknownValues = request.values.keys.where(
      (column) => !columnNames.contains(column),
    );
    if (unknownValues.isNotEmpty) {
      throw ArgumentError('Unknown columns: ${unknownValues.join(', ')}');
    }
    final identity = _validatedIdentity(schema, request.identity);
    final where = identity.keys
        .map(
          (column) => column == NativeSqliteInspectorProtocol.rowIdKey
              ? 'rowid = ?'
              : '${quoteSqlIdentifier(column)} = ?',
        )
        .join(' AND ');
    final whereArgs = identity.values.cast<Object?>().toList();
    await _database(request.database).transaction((transaction) async {
      final changed = delete
          ? await transaction.delete(
              request.table,
              where: where,
              whereArgs: whereArgs,
            )
          : await transaction.update(
              request.table,
              request.values,
              where: where,
              whereArgs: whereArgs,
            );
      if (changed != 1) {
        throw StateError(
          'Expected to change exactly one row, but changed $changed.',
        );
      }
    });
    _notifyDataChanged();
  }

  static Map<String, String> _validatedIdentity(
    InspectorTableSchema schema,
    InspectorRecordIdentity identity,
  ) {
    if (schema.usesRowId) {
      if (identity.kind != 'rowid' ||
          identity.values.keys.toSet().difference({
            NativeSqliteInspectorProtocol.rowIdKey,
          }).isNotEmpty ||
          !identity.values.containsKey(
            NativeSqliteInspectorProtocol.rowIdKey,
          )) {
        throw ArgumentError('Invalid rowid identity.');
      }
      return identity.values;
    }
    if (identity.kind != 'primaryKey' ||
        identity.values.keys
            .toSet()
            .difference(schema.primaryKeys.toSet())
            .isNotEmpty ||
        schema.primaryKeys.any((key) => !identity.values.containsKey(key))) {
      throw ArgumentError('Invalid primary-key identity.');
    }
    return {for (final key in schema.primaryKeys) key: identity.values[key]!};
  }

  static bool _isReadOnlySql(String sql) {
    final normalized = _stripLeadingComments(sql).trimLeft().toUpperCase();
    final keywords = _sqlKeywordsOutsideLiterals(normalized);
    final keyword = keywords.firstOrNull;
    if (keyword == 'SELECT' || keyword == 'EXPLAIN' || keyword == 'VALUES') {
      return true;
    }
    if (keyword == 'WITH') {
      return !keywords.any(
        const {
          'ALTER',
          'CREATE',
          'DELETE',
          'DROP',
          'INSERT',
          'REINDEX',
          'REPLACE',
          'UPDATE',
          'VACUUM',
        }.contains,
      );
    }
    if (keyword != 'PRAGMA') return false;
    final match = RegExp(
      r'^PRAGMA\s+(?:[A-Z0-9_]+\.)?([A-Z0-9_]+)',
    ).firstMatch(normalized);
    final pragma = match?.group(1);
    final readOnly = const {
      'APPLICATION_ID',
      'COLLATION_LIST',
      'COMPILE_OPTIONS',
      'DATA_VERSION',
      'DATABASE_LIST',
      'FOREIGN_KEY_CHECK',
      'FOREIGN_KEYS',
      'FREELIST_COUNT',
      'INDEX_INFO',
      'INDEX_LIST',
      'INDEX_XINFO',
      'INTEGRITY_CHECK',
      'JOURNAL_MODE',
      'PAGE_COUNT',
      'PAGE_SIZE',
      'QUICK_CHECK',
      'SCHEMA_VERSION',
      'TABLE_INFO',
      'TABLE_XINFO',
      'USER_VERSION',
    }.contains(pragma);
    if (!readOnly || match == null) return false;
    final tail = normalized
        .substring(match.end)
        .replaceFirst(RegExp(r';\s*$'), '')
        .trim();
    if (tail.isEmpty) return true;
    return const {
          'FOREIGN_KEY_CHECK',
          'INDEX_INFO',
          'INDEX_LIST',
          'INDEX_XINFO',
          'TABLE_INFO',
          'TABLE_XINFO',
        }.contains(pragma) &&
        RegExp(r'^\([^)]*\)$').hasMatch(tail);
  }

  static List<String> _sqlKeywordsOutsideLiterals(String sql) {
    final keywords = <String>[];
    var index = 0;
    while (index < sql.length) {
      final character = sql.codeUnitAt(index);
      if (character == 0x27 || character == 0x22 || character == 0x60) {
        final quote = character;
        index++;
        while (index < sql.length) {
          if (sql.codeUnitAt(index) == quote) {
            if (index + 1 < sql.length && sql.codeUnitAt(index + 1) == quote) {
              index += 2;
              continue;
            }
            index++;
            break;
          }
          index++;
        }
        continue;
      }
      if (character == 0x5B) {
        final end = sql.indexOf(']', index + 1);
        index = end < 0 ? sql.length : end + 1;
        continue;
      }
      if (character == 0x2D &&
          index + 1 < sql.length &&
          sql.codeUnitAt(index + 1) == 0x2D) {
        final end = sql.indexOf('\n', index + 2);
        index = end < 0 ? sql.length : end + 1;
        continue;
      }
      if (character == 0x2F &&
          index + 1 < sql.length &&
          sql.codeUnitAt(index + 1) == 0x2A) {
        final end = sql.indexOf('*/', index + 2);
        index = end < 0 ? sql.length : end + 2;
        continue;
      }
      final isLetter =
          (character >= 0x41 && character <= 0x5A) || character == 0x5F;
      if (!isLetter) {
        index++;
        continue;
      }
      final start = index++;
      while (index < sql.length) {
        final next = sql.codeUnitAt(index);
        if (!((next >= 0x41 && next <= 0x5A) ||
            (next >= 0x30 && next <= 0x39) ||
            next == 0x5F)) {
          break;
        }
        index++;
      }
      keywords.add(sql.substring(start, index));
    }
    return keywords;
  }

  static String _stripLeadingComments(String sql) {
    var value = sql;
    while (true) {
      value = value.trimLeft();
      if (value.startsWith('--')) {
        final newline = value.indexOf('\n');
        value = newline < 0 ? '' : value.substring(newline + 1);
        continue;
      }
      if (value.startsWith('/*')) {
        final end = value.indexOf('*/', 2);
        value = end < 0 ? '' : value.substring(end + 2);
        continue;
      }
      return value;
    }
  }

  static Future<int> _totalChanges(NativeSqliteDatabase database) async {
    final result = await database.query('SELECT total_changes()');
    return result.rows.first.first as int;
  }

  static Object? _jsonValue(Object? value) {
    if (value is Uint8List || value is List<int>) {
      final bytes = value is Uint8List
          ? value
          : Uint8List.fromList(value as List<int>);
      return {
        r'$type': 'blob',
        'base64': base64Encode(bytes),
        'length': bytes.length,
      };
    }
    if (value is double && !value.isFinite) {
      return {r'$type': 'number', 'value': value.toString()};
    }
    return value;
  }

  static String _identityString(Object? value) {
    if (value is Uint8List || value is List<int>) {
      final bytes = value is Uint8List
          ? value
          : Uint8List.fromList(value as List<int>);
      return 'base64:${base64Encode(bytes)}';
    }
    return value?.toString() ?? 'null';
  }

  static void _notifyDataChanged() {
    developer.postEvent(NativeSqliteInspectorProtocol.dataChangedEvent, {});
  }

  static void _requireRegisteredDatabase(String database) {
    if (!_databases.containsKey(database)) {
      throw ArgumentError.value(database, 'database', 'is not registered');
    }
  }

  static NativeSqliteDatabase _database(String name) {
    _requireRegisteredDatabase(name);
    return _databases[name]!.firstWhere((database) => !database.isClosed);
  }

  static Future<void> _requireTable(String database, String table) async {
    final result = await _database(database).query(
      "SELECT 1 FROM sqlite_master WHERE type IN ('table', 'view') "
      'AND name = ? LIMIT 1',
      [table],
    );
    if (result.rows.isEmpty) {
      throw ArgumentError.value(table, 'table', 'does not exist');
    }
  }

  static Future<InspectorTableSchema> _getTableSchema(
    String database,
    String table,
  ) async {
    await _requireTable(database, table);
    final objectResult = await _database(database).query(
      "SELECT type, sql FROM sqlite_master WHERE type IN ('table', 'view') "
      'AND name = ? LIMIT 1',
      [table],
    );
    final object = objectResult.toMapList().single;
    final isView = object['type'] == 'view';
    final createSql = object['sql'] as String? ?? '';
    final columnsResult = await _database(
      database,
    ).query('PRAGMA table_info(${quoteSqlIdentifier(table)})');
    final columns = columnsResult.toMapList().map((column) {
      final position = column['pk'] as int? ?? 0;
      return InspectorColumnInfo(
        name: column['name'] as String,
        type: column['type'] as String? ?? '',
        nullable: (column['notnull'] as int? ?? 0) == 0,
        primaryKeyPosition: position,
        defaultValue: _jsonValue(column['dflt_value']),
      );
    }).toList();
    final primaryKeys = [...columns]
      ..sort(
        (left, right) =>
            left.primaryKeyPosition.compareTo(right.primaryKeyPosition),
      );
    return InspectorTableSchema(
      name: table,
      columns: columns,
      primaryKeys: primaryKeys
          .where((column) => column.primaryKeyPosition > 0)
          .map((column) => column.name)
          .toList(),
      indexes: await _getIndexes(database, table),
      usesRowId:
          !isView &&
          !RegExp(
            r'\bWITHOUT\s+ROWID\b',
            caseSensitive: false,
          ).hasMatch(createSql),
      isView: isView,
    );
  }

  static Future<List<InspectorTableSchema>> _getTablesForDatabase(
    String database,
  ) async {
    try {
      return await _getTablesForDatabaseBatched(database);
    } catch (_) {
      return _getTablesForDatabaseFallback(database);
    }
  }

  static Future<List<InspectorTableSchema>> _getTablesForDatabaseBatched(
    String database,
  ) async {
    final sqliteObjects = await _database(database).query(
      "SELECT name, type, sql FROM sqlite_master "
      "WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%' "
      'ORDER BY name',
    );
    final columnRows = await _database(database).query(
      'SELECT m.name AS object_name, c.name AS column_name, '
      'c.type AS column_type, c."notnull" AS is_not_null, '
      'c.dflt_value AS default_value, c.pk AS primary_key_position '
      'FROM sqlite_master AS m JOIN pragma_table_info(m.name) AS c '
      "WHERE m.type IN ('table', 'view') AND m.name NOT LIKE 'sqlite_%' "
      'ORDER BY m.name, c.cid',
    );
    final indexRows = await _database(database).query(
      'SELECT m.name AS object_name, il.name AS index_name, '
      'ii.name AS column_name '
      'FROM sqlite_master AS m JOIN pragma_index_list(m.name) AS il '
      'LEFT JOIN pragma_index_info(il.name) AS ii '
      "WHERE m.type = 'table' AND m.name NOT LIKE 'sqlite_%' "
      'ORDER BY m.name, il.seq, ii.seqno',
    );

    final columnsByTable = <String, List<InspectorColumnInfo>>{};
    for (final row in columnRows.toMapList()) {
      columnsByTable
          .putIfAbsent(row['object_name'] as String, () => [])
          .add(
            InspectorColumnInfo(
              name: row['column_name'] as String,
              type: row['column_type'] as String? ?? '',
              nullable: (row['is_not_null'] as int? ?? 0) == 0,
              primaryKeyPosition: row['primary_key_position'] as int? ?? 0,
              defaultValue: _jsonValue(row['default_value']),
            ),
          );
    }
    final indexColumns = <String, Map<String, List<String>>>{};
    for (final row in indexRows.toMapList()) {
      final indexName = row['index_name'] as String?;
      if (indexName == null) continue;
      final columns = indexColumns
          .putIfAbsent(row['object_name'] as String, () => {})
          .putIfAbsent(indexName, () => []);
      final columnName = row['column_name'] as String?;
      if (columnName != null) columns.add(columnName);
    }

    return sqliteObjects.toMapList().map((object) {
      final name = object['name'] as String;
      final isView = object['type'] == 'view';
      final columns = columnsByTable[name] ?? const <InspectorColumnInfo>[];
      final primaryKeys =
          columns.where((column) => column.primaryKeyPosition > 0).toList()
            ..sort(
              (left, right) =>
                  left.primaryKeyPosition.compareTo(right.primaryKeyPosition),
            );
      return InspectorTableSchema(
        name: name,
        columns: columns,
        primaryKeys: primaryKeys.map((column) => column.name).toList(),
        indexes: [
          for (final entry
              in indexColumns[name]?.entries ??
                  const <MapEntry<String, List<String>>>[])
            '${entry.key} (${entry.value.join(', ')})',
        ],
        usesRowId:
            !isView &&
            !RegExp(
              r'\bWITHOUT\s+ROWID\b',
              caseSensitive: false,
            ).hasMatch(object['sql'] as String? ?? ''),
        isView: isView,
      );
    }).toList();
  }

  static Future<List<InspectorTableSchema>> _getTablesForDatabaseFallback(
    String database,
  ) async {
    final result = await _database(database).query(
      "SELECT name FROM sqlite_master WHERE type IN ('table', 'view') "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final tables = <InspectorTableSchema>[];
    for (final row in result.toMapList()) {
      try {
        tables.add(await _getTableSchema(database, row['name'] as String));
      } catch (_) {
        // A malformed or concurrently removed object must not hide its peers.
      }
    }
    return tables;
  }

  static Future<List<String>> _getIndexes(String database, String table) async {
    try {
      final result = await _database(
        database,
      ).query('PRAGMA index_list(${quoteSqlIdentifier(table)})');
      final indexes = <String>[];
      for (final row in result.toMapList()) {
        final name = row['name'] as String;
        final info = await _database(
          database,
        ).query('PRAGMA index_info(${quoteSqlIdentifier(name)})');
        indexes.add(
          '$name (${info.toMapList().map((column) => column['name']).join(', ')})',
        );
      }
      return indexes;
    } catch (_) {
      return [];
    }
  }

  static Future<int> _getDatabaseSize(String database) async {
    try {
      final pageCount = await _database(database).query('PRAGMA page_count');
      final pageSize = await _database(database).query('PRAGMA page_size');
      return (pageCount.rows.first.first as int) *
          (pageSize.rows.first.first as int);
    } catch (_) {
      return 0;
    }
  }
}
