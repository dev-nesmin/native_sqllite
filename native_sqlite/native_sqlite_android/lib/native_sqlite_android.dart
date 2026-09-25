/// Android method-channel implementation of the native_sqlite platform API.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';

extension on MethodChannel {
  Future<T?> _invokeNativeSqliteMethod<T>(
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      final details = error.details;
      if (details is Map && details['code'] is int) {
        throw NativeSqliteException.fromPlatformException(error);
      }
      rethrow;
    }
  }

  Future<List<T>?> _invokeNativeSqliteListMethod<T>(
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await invokeListMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      final details = error.details;
      if (details is Map && details['code'] is int) {
        throw NativeSqliteException.fromPlatformException(error);
      }
      rethrow;
    }
  }
}

/// The Android implementation of [NativeSqlitePlatform].
class NativeSqliteAndroid extends NativeSqlitePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_sqlite_android');

  /// Registers this class as the default instance of [NativeSqlitePlatform]
  static void registerWith() {
    NativeSqlitePlatform.instance = NativeSqliteAndroid();
  }

  @override
  Future<String> openDatabase(DatabaseConfig config) async {
    final result = await methodChannel._invokeNativeSqliteMethod<String>(
      'openDatabase',
      config.toMap(),
    );
    return _requireResult(result, 'openDatabase');
  }

  @override
  Future<void> closeDatabase(String databaseName) async {
    await methodChannel._invokeNativeSqliteMethod<void>('closeDatabase', {
      'name': databaseName,
    });
  }

  @override
  Future<int> execute(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final result = await methodChannel._invokeNativeSqliteMethod<int>(
      'execute',
      {'name': databaseName, 'sql': sql, 'arguments': arguments},
    );
    return _requireResult(result, 'execute');
  }

  @override
  Future<int> executeInsert(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final result = await methodChannel._invokeNativeSqliteMethod<int>(
      'executeInsert',
      {'name': databaseName, 'sql': sql, 'arguments': arguments},
    );
    return _requireResult(result, 'executeInsert');
  }

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async {
    final result = await methodChannel
        ._invokeNativeSqliteMethod<Map<Object?, Object?>>('query', {
          'name': databaseName,
          'sql': sql,
          'arguments': arguments,
        });

    return QueryResult.fromMap(
      _requireResult(result, 'query').cast<String, dynamic>(),
    );
  }

  @override
  Future<int> insert(
    String databaseName,
    String table,
    Map<String, Object?> values,
  ) async {
    final result = await methodChannel._invokeNativeSqliteMethod<int>(
      'insert',
      {'name': databaseName, 'table': table, 'values': values},
    );
    return _requireResult(result, 'insert');
  }

  @override
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final result = await methodChannel
        ._invokeNativeSqliteMethod<int>('update', {
          'name': databaseName,
          'table': table,
          'values': values,
          'where': where,
          'whereArgs': whereArgs,
        });
    return _requireResult(result, 'update');
  }

  @override
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final result = await methodChannel._invokeNativeSqliteMethod<int>(
      'delete',
      {
        'name': databaseName,
        'table': table,
        'where': where,
        'whereArgs': whereArgs,
      },
    );
    return _requireResult(result, 'delete');
  }

  @override
  Future<void> beginTransaction(
    String databaseName,
    String transactionId,
  ) async {
    await methodChannel._invokeNativeSqliteMethod<void>('beginTransaction', {
      'name': databaseName,
      'transactionId': transactionId,
    });
  }

  @override
  Future<void> endTransaction(
    String databaseName,
    String transactionId, {
    required bool commit,
  }) async {
    await methodChannel._invokeNativeSqliteMethod<void>('endTransaction', {
      'name': databaseName,
      'transactionId': transactionId,
      'commit': commit,
    });
  }

  @override
  Future<int> transactionExecute(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) => _transactionOperation<int>('execute', databaseName, transactionId, {
    'sql': sql,
    'arguments': arguments,
  });

  @override
  Future<QueryResult> transactionQuery(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) async {
    final result = await _transactionOperation<Map<Object?, Object?>>(
      'query',
      databaseName,
      transactionId,
      {'sql': sql, 'arguments': arguments},
    );
    return QueryResult.fromMap(result.cast<String, dynamic>());
  }

  @override
  Future<int> transactionInsert(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values,
  ) => _transactionOperation<int>('insert', databaseName, transactionId, {
    'table': table,
    'values': values,
  });

  @override
  Future<int> transactionUpdate(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) => _transactionOperation<int>('update', databaseName, transactionId, {
    'table': table,
    'values': values,
    'where': where,
    'whereArgs': whereArgs,
  });

  @override
  Future<int> transactionDelete(
    String databaseName,
    String transactionId,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) => _transactionOperation<int>('delete', databaseName, transactionId, {
    'table': table,
    'where': where,
    'whereArgs': whereArgs,
  });

  Future<T> _transactionOperation<T>(
    String method,
    String databaseName,
    String transactionId,
    Map<String, Object?> arguments,
  ) async {
    final result = await methodChannel._invokeNativeSqliteMethod<T>(method, {
      'name': databaseName,
      'transactionId': transactionId,
      ...arguments,
    });
    return _requireResult(result, method);
  }

  @override
  Future<List<Object?>> executeBatch(
    String databaseName,
    List<Map<String, Object?>> operations,
  ) async {
    final result = await methodChannel._invokeNativeSqliteListMethod<Object?>(
      'batch',
      {'name': databaseName, 'operations': operations},
    );
    return _requireResult(result, 'batch');
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
    final result = await methodChannel._invokeNativeSqliteMethod<String>(
      'getDatabasePath',
      {'name': databaseName, 'directory': directory},
    );
    return _requireResult(result, 'getDatabasePath');
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
    final result = await methodChannel._invokeNativeSqliteMethod<bool>(
      'databaseExists',
      {'name': databaseName, 'directory': directory},
    );
    return _requireResult(result, 'databaseExists');
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
    await methodChannel._invokeNativeSqliteMethod<void>('importDatabase', {
      'name': databaseName,
      'bytes': bytes,
      'directory': directory,
      'overwrite': overwrite,
    });
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
    await methodChannel._invokeNativeSqliteMethod<void>('deleteDatabase', {
      'name': databaseName,
      'directory': directory,
    });
  }
}

T _requireResult<T>(T? result, String operation) {
  if (result == null) {
    throw StateError('$operation returned no result');
  }
  return result;
}
