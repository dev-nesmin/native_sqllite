import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';

/// The iOS implementation of [NativeSqlitePlatform].
class NativeSqliteIOS extends NativeSqlitePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_sqlite_ios');

  /// Registers this class as the default instance of [NativeSqlitePlatform]
  static void registerWith() {
    NativeSqlitePlatform.instance = NativeSqliteIOS();
  }

  @override
  Future<String> openDatabase(DatabaseConfig config) async {
    final result = await methodChannel.invokeMethod<String>(
      'openDatabase',
      config.toMap(),
    );
    if (result == null) {
      throw Exception('Failed to open database: ${config.name}');
    }
    return result;
  }

  @override
  Future<void> closeDatabase(String databaseName) async {
    await methodChannel.invokeMethod<void>('closeDatabase', {
      'name': databaseName,
    });
  }

  @override
  Future<int> execute(String databaseName, String sql, List<Object?>? arguments) async {
    final result = await methodChannel.invokeMethod<int>('execute', {
      'name': databaseName,
      'sql': sql,
      'arguments': arguments,
    });
    return result ?? 0;
  }

  @override
  Future<QueryResult> query(String databaseName, String sql, List<Object?>? arguments) async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>('query', {
      'name': databaseName,
      'sql': sql,
      'arguments': arguments,
    });

    if (result == null) {
      return const QueryResult(columns: [], rows: []);
    }

    return QueryResult.fromMap(result.cast<String, dynamic>());
  }

  @override
  Future<int> insert(String databaseName, String table, Map<String, Object?> values) async {
    final result = await methodChannel.invokeMethod<int>('insert', {
      'name': databaseName,
      'table': table,
      'values': values,
    });
    return result ?? -1;
  }

  @override
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final result = await methodChannel.invokeMethod<int>('update', {
      'name': databaseName,
      'table': table,
      'values': values,
      'where': where,
      'whereArgs': whereArgs,
    });
    return result ?? 0;
  }

  @override
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final result = await methodChannel.invokeMethod<int>('delete', {
      'name': databaseName,
      'table': table,
      'where': where,
      'whereArgs': whereArgs,
    });
    return result ?? 0;
  }

  @override
  Future<bool> transaction(String databaseName, List<String> sqlStatements) async {
    final result = await methodChannel.invokeMethod<bool>('transaction', {
      'name': databaseName,
      'statements': sqlStatements,
    });
    return result ?? false;
  }

  @override
  Future<String?> getDatabasePath(String databaseName) async {
    return await methodChannel.invokeMethod<String>('getDatabasePath', {
      'name': databaseName,
    });
  }

  @override
  Future<void> deleteDatabase(String databaseName) async {
    await methodChannel.invokeMethod<void>('deleteDatabase', {
      'name': databaseName,
    });
  }
}
