import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'native_sqlite.dart';

/// Handles communication with the Native SQLite Inspector.
class InspectorConnect {
  static final Set<String> _databases = {};
  static bool _initialized = false;

  // Configurable URL for the hosted inspector
  // Using HTTP instead of HTTPS to avoid Mixed Content blocking when connecting to ws://localhost
  static String inspectorUrl = 'http://dev-nesmin.github.io/native_sqllite/';

  /// Initializes the inspector connection for the given database.
  static void init(String databaseName) {
    _databases.add(databaseName);

    if (!_initialized) {
      _initialized = true;
      _registerExtensions();
      _printConnection();
    }
  }

  static void _printConnection() async {
    if (!kDebugMode) return;

    try {
      developer.ServiceProtocolInfo? info;
      Uri? serviceUri;

      // Retry up to 5 times to get the service URI
      for (var i = 0; i < 5; i++) {
        info = await developer.Service.getInfo();
        serviceUri = info.serverUri;
        if (serviceUri != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }

      if (serviceUri == null) {
        print(
          '╔════════════════════════════════════════════════════════════════════════════╗',
        );
        print(
          '║  Native SQLite Inspector                                                   ║',
        );
        print(
          '║                                                                            ║',
        );
        print(
          '║  Could not auto-detect VM Service URI.                                     ║',
        );
        print(
          '║  Please copy the URI printed above (starts with http://127.0.0.1:...)      ║',
        );
        print(
          '║  and use it to connect at:                                                 ║',
        );
        print('║  $inspectorUrl                                            ║');
        print(
          '╚════════════════════════════════════════════════════════════════════════════╝',
        );
        return;
      }

      final port = serviceUri.port;
      var path = serviceUri.path;
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      if (path.endsWith('=')) {
        path = path.substring(0, path.length - 1);
      }

      final secret = path.isEmpty ? '' : path.split('/').last;

      // Format: https://dev-nesmin.web.app/#/PORT/SECRET
      final url = '$inspectorUrl#/$port/$secret';

      print(
        '╔════════════════════════════════════════════════════════════════════════════╗',
      );
      print(
        '║                                                                            ║',
      );
      print(
        '║  Native SQLite Inspector is available at:                                  ║',
      );
      print('║  $url  ║');
      print(
        '║                                                                            ║',
      );
      print(
        '╚════════════════════════════════════════════════════════════════════════════╝',
      );
    } catch (e) {
      print('Failed to get VM Service info: $e');
    }
  }

  static void _registerExtensions() {
    // List databases
    developer.registerExtension('ext.native_sqlite.listDatabases', (
      method,
      parameters,
    ) async {
      try {
        final dbs = <Map<String, dynamic>>[];
        for (final name in _databases) {
          final path = await NativeSqlite.getDatabasePath(name);
          if (path != null) {
            // Get tables for this database
            final tablesResult = await NativeSqlite.query(
              name,
              "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
            );

            final tables = <Map<String, dynamic>>[];
            for (final row in tablesResult.toMapList()) {
              final tableName = row['name'] as String;
              // Get table info
              final columnsResult = await NativeSqlite.query(
                name,
                "PRAGMA table_info($tableName)",
              );

              final columns = columnsResult
                  .toMapList()
                  .map(
                    (c) => {
                      'name': c['name'],
                      'type': c['type'],
                      'nullable': c['notnull'] == 0,
                      'defaultValue': c['dflt_value'],
                      'primaryKey': c['pk'] == 1,
                    },
                  )
                  .toList();

              tables.add({
                'name': tableName,
                'columns': columns,
                'indexes': [], // TODO: Fetch indexes
                'primaryKey': columns.firstWhere(
                  (c) => c['primaryKey'] == true,
                  orElse: () => {},
                )['name'],
              });
            }

            dbs.add({
              'name': name,
              'path': path,
              'tables': tables,
              'size': 0, // TODO: Get file size
            });
          }
        }
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'result': dbs}),
        );
      } catch (e) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });

    // Get Schema (reused logic from listDatabases for now, but specific to one db if needed)
    developer.registerExtension('ext.native_sqlite.getSchema', (
      method,
      parameters,
    ) async {
      // For now listDatabases returns full schema, so this might be redundant or specific
      // But keeping it for compatibility
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'result': {}}),
      );
    });

    // Execute Query
    developer.registerExtension('ext.native_sqlite.executeQuery', (
      method,
      parameters,
    ) async {
      try {
        if (!parameters.containsKey('args')) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'Missing args',
          );
        }

        final argsJson = parameters['args'];
        if (argsJson == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'args is null',
          );
        }

        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final database = args['database'] as String?;

        if (database == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'Missing database parameter',
          );
        }

        // Inspector can send either:
        // 1. A direct SQL query via 'query' parameter
        // 2. A table name with limit/offset for pagination
        String sql;
        if (args.containsKey('query')) {
          sql = args['query'] as String;
        } else if (args.containsKey('table')) {
          final table = args['table'] as String;
          final limit = args['limit'] as int? ?? 50;
          final offset = args['offset'] as int? ?? 0;

          // Build paginated query
          sql = 'SELECT * FROM $table LIMIT $limit OFFSET $offset';
        } else {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'Missing query or table parameter',
          );
        }

        final result = await NativeSqlite.query(database, sql);
        final rows = result.toMapList();

        // Get total count if this is a table query with pagination
        int totalCount = rows.length;
        if (args.containsKey('table')) {
          final table = args['table'] as String;
          final countResult = await NativeSqlite.query(
            database,
            'SELECT COUNT(*) as count FROM $table',
          );
          final countRows = countResult.toMapList();
          if (countRows.isNotEmpty) {
            totalCount = countRows.first['count'] as int;
          }
        }

        return developer.ServiceExtensionResponse.result(
          jsonEncode({
            'result': {'objects': rows, 'count': totalCount},
          }),
        );
      } catch (e, stackTrace) {
        print('executeQuery error: $e\n$stackTrace');
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });

    // Execute SQL
    developer.registerExtension('ext.native_sqlite.executeSql', (
      method,
      parameters,
    ) async {
      try {
        if (!parameters.containsKey('args')) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'Missing args',
          );
        }

        final args = jsonDecode(parameters['args']!) as Map<String, dynamic>;
        final database = args['database'] as String;
        final sql = args['sql'] as String;

        // Check if it's a SELECT
        if (sql.trim().toUpperCase().startsWith('SELECT')) {
          final result = await NativeSqlite.query(database, sql);
          return developer.ServiceExtensionResponse.result(
            jsonEncode({'result': result.toMapList()}),
          );
        } else {
          await NativeSqlite.execute(database, sql);
          _notifyDataChanged();
          return developer.ServiceExtensionResponse.result(
            jsonEncode({'result': []}),
          );
        }
      } catch (e) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });

    // Update Record
    developer.registerExtension('ext.native_sqlite.updateRecord', (
      method,
      parameters,
    ) async {
      try {
        if (!parameters.containsKey('args')) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'Missing args',
          );
        }
        final args = jsonDecode(parameters['args']!) as Map<String, dynamic>;
        final database = args['database'] as String;
        final table = args['table'] as String;
        final id = args['id'];
        final values = Map<String, Object?>.from(args['values'] as Map);

        // Find primary key name (assuming 'id' for now or need to fetch schema)
        // For simplicity, let's assume the primary key is passed or we can infer it?
        // The inspector usually knows the PK. But here we just get 'id'.
        // Let's assume standard 'id' or try to find it.
        // Actually, let's just use the 'id' value and assume the column is 'id' or 'rowid' if not specified.
        // Better: The inspector should probably pass the PK column name, but if not, we might need to look it up.
        // For this implementation, let's assume 'id' column.

        await NativeSqlite.update(
          database,
          table,
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        _notifyDataChanged();
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'result': true}),
        );
      } catch (e) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });

    // Delete Record
    developer.registerExtension('ext.native_sqlite.deleteRecord', (
      method,
      parameters,
    ) async {
      try {
        if (!parameters.containsKey('args')) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.invalidParams,
            'Missing args',
          );
        }
        final args = jsonDecode(parameters['args']!) as Map<String, dynamic>;
        final database = args['database'] as String;
        final table = args['table'] as String;
        final id = args['id'];

        await NativeSqlite.delete(
          database,
          table,
          where: 'id = ?',
          whereArgs: [id],
        );
        _notifyDataChanged();
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'result': true}),
        );
      } catch (e) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });
  }

  static void _notifyDataChanged() {
    developer.postEvent('ext.native_sqlite.data_changed', {});
  }
}
