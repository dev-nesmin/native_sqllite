import 'package:native_sqlite/native_sqlite.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/user.dart';

class RawApiResult {
  const RawApiResult({
    required this.operation,
    required this.detail,
    this.passed = true,
    this.error,
  });

  final String operation;
  final String detail;
  final bool passed;
  final NativeSqliteException? error;
}

/// Runs the complete raw API against an isolated, disposable database.
class RawApiDemoService {
  const RawApiDemoService();

  static const databaseName = 'raw_api_demo';

  Future<List<RawApiResult>> run() async {
    final results = <RawApiResult>[];
    NativeSqliteDatabase? database;
    try {
      await NativeSqlite.deleteDatabase(databaseName);
      final path = await NativeSqlite.getDatabasePath(databaseName);
      results.add(RawApiResult(operation: 'getDatabasePath', detail: path));

      database = await NativeSqlite.open(
        DatabaseConfig(
          name: databaseName,
          onCreate: [
            CategorySchema.createTableSql,
            UserSchema.createTableSql,
            ProductSchema.createTableSql,
            ...UserSchema.indexSql,
          ],
        ),
      );
      results.add(
        RawApiResult(
          operation: 'open',
          detail: 'Opened ${database.name} at ${database.path}',
        ),
      );

      final firstId = await database.executeInsert(
        'INSERT INTO ${_table(UserSchema.tableName)} '
        '(${_column(UserSchema.NAME)}, ${_column(UserSchema.EMAIL)}, '
        '${_column(UserSchema.AGE)}, ${_column(UserSchema.IS_ACTIVE)}, '
        '${_column(UserSchema.CREATED_AT)}) VALUES (?, ?, ?, ?, ?)',
        ['Raw Execute', 'execute@example.com', 20, 1, 1000],
      );
      results.add(
        RawApiResult(operation: 'executeInsert', detail: 'row ID $firstId'),
      );

      final executed = await database.execute(
        'UPDATE ${_table(UserSchema.tableName)} '
        'SET ${_column(UserSchema.AGE)} = ? '
        'WHERE ${_column(UserSchema.ID)} = ?',
        [21, firstId],
      );
      results.add(
        RawApiResult(operation: 'execute', detail: '$executed row changed'),
      );

      final queried = await database.query(
        'SELECT ${_column(UserSchema.NAME)}, ${_column(UserSchema.AGE)} '
        'FROM ${_table(UserSchema.tableName)} '
        'WHERE ${_column(UserSchema.ID)} = ?',
        [firstId],
      );
      results.add(
        RawApiResult(
          operation: 'query',
          detail: '${queried.toMapList().single}',
        ),
      );

      final inserted = await database.insert(UserSchema.tableName, {
        UserSchema.NAME: 'Raw Insert',
        UserSchema.EMAIL: 'insert@example.com',
        UserSchema.AGE: 30,
        UserSchema.IS_ACTIVE: 1,
        UserSchema.CREATED_AT: 2000,
      });
      results.add(
        RawApiResult(operation: 'insert', detail: 'row ID $inserted'),
      );

      final updated = await database.update(
        UserSchema.tableName,
        {UserSchema.NAME: 'Raw Updated'},
        where: '${_column(UserSchema.ID)} = ?',
        whereArgs: [inserted],
      );
      results.add(
        RawApiResult(operation: 'update', detail: '$updated row changed'),
      );

      final transactionCount = await database.transaction((transaction) async {
        await transaction.insert(UserSchema.tableName, {
          UserSchema.NAME: 'Transaction User',
          UserSchema.EMAIL: 'transaction@example.com',
          UserSchema.AGE: 40,
          UserSchema.IS_ACTIVE: 1,
          UserSchema.CREATED_AT: 3000,
        });
        final count = await transaction.query(
          'SELECT COUNT(*) AS count FROM ${_table(UserSchema.tableName)}',
        );
        return count.toMapList().single['count'] as int;
      });
      results.add(
        RawApiResult(
          operation: 'transaction',
          detail: 'committed with $transactionCount rows visible',
        ),
      );

      final batch = database.batch()
        ..insert(UserSchema.tableName, {
          UserSchema.NAME: 'Batch One',
          UserSchema.EMAIL: 'batch-one@example.com',
          UserSchema.AGE: 50,
          UserSchema.IS_ACTIVE: 1,
          UserSchema.CREATED_AT: 4000,
        })
        ..insert(UserSchema.tableName, {
          UserSchema.NAME: 'Batch Two',
          UserSchema.EMAIL: 'batch-two@example.com',
          UserSchema.AGE: 60,
          UserSchema.IS_ACTIVE: 0,
          UserSchema.CREATED_AT: 5000,
        })
        ..query(
          'SELECT COUNT(*) AS count FROM ${_table(UserSchema.tableName)}',
        );
      final batchResults = await batch.commit();
      final batchCount = (batchResults.last! as QueryResult)
          .toMapList()
          .single['count'];
      results.add(
        RawApiResult(
          operation: 'batch',
          detail: '${batchResults.length} operations; $batchCount total rows',
        ),
      );

      final deleted = await database.delete(
        UserSchema.tableName,
        where: '${_column(UserSchema.ID)} = ?',
        whereArgs: [inserted],
      );
      results.add(
        RawApiResult(operation: 'delete', detail: '$deleted row removed'),
      );

      await _captureError(results, 'UNIQUE', () {
        return database!.insert(UserSchema.tableName, {
          UserSchema.NAME: 'Duplicate',
          UserSchema.EMAIL: 'execute@example.com',
          UserSchema.AGE: 1,
          UserSchema.IS_ACTIVE: 1,
          UserSchema.CREATED_AT: 6000,
        });
      });
      await _captureError(results, 'NOT NULL', () {
        return database!.insert(UserSchema.tableName, {
          UserSchema.NAME: null,
          UserSchema.EMAIL: 'not-null@example.com',
          UserSchema.AGE: 1,
          UserSchema.IS_ACTIVE: 1,
          UserSchema.CREATED_AT: 7000,
        });
      });
      await _captureError(results, 'FOREIGN KEY', () {
        return database!.insert(ProductSchema.tableName, {
          ProductSchema.NAME: 'Orphan',
          ProductSchema.PRICE: 1.0,
          ProductSchema.STOCK: 0,
          ProductSchema.IS_AVAILABLE: 1,
          ProductSchema.CATEGORY_ID: 999999,
          ProductSchema.CREATED_AT: 8000,
        });
      });
      await _captureError(
        results,
        'syntax error',
        () => database!.execute(
          'INSRT INTO ${_table(UserSchema.tableName)} '
          '(${_column(UserSchema.NAME)}) VALUES (?)',
          ['invalid'],
        ),
      );

      await database.close();
      results.add(
        RawApiResult(
          operation: 'close',
          detail: 'isClosed = ${database.isClosed}',
        ),
      );
      await NativeSqlite.deleteDatabase(databaseName);
      results.add(
        const RawApiResult(
          operation: 'deleteDatabase',
          detail: 'Disposable database deleted',
        ),
      );
      return results;
    } finally {
      if (database != null && !database.isClosed) await database.close();
      await NativeSqlite.deleteDatabase(databaseName);
    }
  }

  Future<void> _captureError(
    List<RawApiResult> results,
    String operation,
    Future<Object?> Function() action,
  ) async {
    try {
      await action();
      results.add(
        RawApiResult(
          operation: operation,
          detail: 'Expected an error, but the operation succeeded',
          passed: false,
        ),
      );
    } on NativeSqliteException catch (error) {
      final expected = switch (operation) {
        'UNIQUE' => error.isUniqueViolation,
        'NOT NULL' => error.isNotNullViolation,
        'FOREIGN KEY' => error.isForeignKeyViolation,
        'syntax error' => error.isSyntaxError,
        _ => false,
      };
      results.add(
        RawApiResult(
          operation: operation,
          detail:
              'code ${error.resultCode}, extended '
              '${error.extendedResultCode}: ${error.message}',
          passed: expected,
          error: error,
        ),
      );
    }
  }

  static String _table(String value) => '"$value"';
  static String _column(String value) => '"$value"';
}
