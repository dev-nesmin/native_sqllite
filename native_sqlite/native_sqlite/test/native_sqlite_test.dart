import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart'
    show NativeSqlitePlatform;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeSqlitePlatform extends NativeSqlitePlatform
    with MockPlatformInterfaceMixin {
  int closeDatabaseCalls = 0;
  int batchCalls = 0;
  final List<bool> transactionEnds = [];
  String? lastQuerySql;
  List<Object?>? lastQueryArguments;

  @override
  Future<String> openDatabase(DatabaseConfig config) {
    return Future.value('/path/to/${config.name}');
  }

  @override
  Future<void> closeDatabase(String databaseName) {
    closeDatabaseCalls++;
    return Future.value();
  }

  @override
  Future<String> getDatabasePath(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) {
    return Future.value('/path/to/$databaseName');
  }

  @override
  Future<void> deleteDatabase(
    String databaseName, {
    String? directory,
    String? iosAppGroup,
  }) {
    return Future.value();
  }

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) {
    lastQuerySql = sql;
    lastQueryArguments = arguments;
    return Future.value(
      QueryResult(
        columns: ['id', 'name'],
        rows: [
          [1, 'Test User'],
        ],
      ),
    );
  }

  @override
  Future<int> execute(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) {
    return Future.value(1);
  }

  @override
  Future<int> executeInsert(
    String databaseName,
    String sql,
    List<Object?>? arguments,
  ) async => 321;

  @override
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return Future.value(1);
  }

  @override
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return Future.value(1);
  }

  @override
  Future<int> insert(
    String databaseName,
    String table,
    Map<String, Object?> values,
  ) {
    return Future.value(123);
  }

  @override
  Future<void> beginTransaction(
    String databaseName,
    String transactionId,
  ) async {}

  @override
  Future<void> endTransaction(
    String databaseName,
    String transactionId, {
    required bool commit,
  }) async {
    transactionEnds.add(commit);
  }

  @override
  Future<int> transactionExecute(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) => execute(databaseName, sql, arguments);

  @override
  Future<QueryResult> transactionQuery(
    String databaseName,
    String transactionId,
    String sql,
    List<Object?>? arguments,
  ) => query(databaseName, sql, arguments);

  @override
  Future<int> transactionInsert(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values,
  ) => insert(databaseName, table, values);

  @override
  Future<int> transactionUpdate(
    String databaseName,
    String transactionId,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) => update(databaseName, table, values, where: where, whereArgs: whereArgs);

  @override
  Future<int> transactionDelete(
    String databaseName,
    String transactionId,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) => delete(databaseName, table, where: where, whereArgs: whereArgs);

  @override
  Future<List<Object?>> executeBatch(
    String databaseName,
    List<Map<String, Object?>> operations,
  ) async {
    batchCalls++;
    return [
      for (final operation in operations)
        if (operation['type'] == 'query')
          {
            'columns': ['id', 'name'],
            'rows': [
              [1, 'Test User'],
            ],
          }
        else
          1,
    ];
  }
}

class InspectorSchemaPlatform extends MockNativeSqlitePlatform {
  String? lastSql;
  final queries = <String>[];

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) async {
    lastSql = sql;
    queries.add(sql);
    if (sql.contains('sqlite_master')) {
      if (sql.startsWith('SELECT type, sql')) {
        return arguments?.single == 'order details'
            ? const QueryResult(
                columns: ['type', 'sql'],
                rows: [
                  ['table', 'CREATE TABLE "order details" ("record id" INT)'],
                ],
              )
            : const QueryResult(columns: ['type', 'sql'], rows: []);
      }
      return QueryResult(
        columns: const ['exists'],
        rows: arguments?.single == 'order details'
            ? const [
                [1],
              ]
            : const [],
      );
    }
    if (sql.startsWith('PRAGMA table_info')) {
      return const QueryResult(
        columns: ['name', 'type', 'notnull', 'dflt_value', 'pk'],
        rows: [
          ['record id', 'INTEGER', 1, null, 1],
          ['body', 'TEXT', 0, null, 0],
        ],
      );
    }
    if (sql.startsWith('PRAGMA index_list')) {
      return const QueryResult(columns: ['name'], rows: []);
    }
    return super.query(databaseName, sql, arguments);
  }
}

void main() {
  setUp(() {
    InspectorConnect.enabled = true;
    InspectorConnect.printBanner = false;
    InspectorConnect.debugClearDatabases();
  });

  test('getDatabasePath', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    expect(await NativeSqlite.getDatabasePath('test_db'), '/path/to/test_db');
  });

  test('open', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final config = DatabaseConfig(name: 'test_db', version: 1, onCreate: []);
    final database = await NativeSqlite.open(config);
    expect(database.path, '/path/to/test_db');
    expect(database.name, 'test_db');
    expect(database.version, 1);
  });

  test('insert', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final id = await database.insert('users', {'name': 'Test'});
    expect(id, 123);
  });

  test('query', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final result = await database.query('SELECT * FROM users');
    expect(result.columns, ['id', 'name']);
    expect(result.rows.first, [1, 'Test User']);
  });

  test('update', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final rows = await database.update(
      'users',
      {'name': 'Updated'},
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(rows, 1);
  });

  test('delete', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final rows = await database.delete(
      'users',
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(rows, 1);
  });

  test('transaction', () async {
    final fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final value = await database.transaction((transaction) async {
      await transaction.execute('INSERT INTO users (name) VALUES (?)', ['A']);
      final result = await transaction.query('SELECT * FROM users');
      return result.rows.length;
    });
    expect(value, 1);
    expect(fakePlatform.transactionEnds, [true]);
  });

  test('execute returns affected row count', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final affected = await database.execute(
      'UPDATE users SET name = ? WHERE id = ?',
      ['Updated', 1],
    );
    expect(affected, 1);
  });

  test('execute without arguments', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final affected = await database.execute('DELETE FROM users');
    expect(affected, 1);
  });

  test('executeInsert returns the raw insert row ID', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));

    expect(
      await database.executeInsert('INSERT INTO users (name) VALUES (?)', [
        'Test',
      ]),
      321,
    );
  });

  test('close completes without error', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    await expectLater(database.close(), completes);
    expect(database.isClosed, isTrue);
    expect(() => database.query('SELECT 1'), throwsStateError);
  });

  test('close unregisters the database from the inspector', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    expect(InspectorConnect.debugIsRegistered('test_db'), isTrue);

    await database.close();

    expect(InspectorConnect.debugIsRegistered('test_db'), isFalse);
  });

  test('each handle owns one reference and close is idempotent', () async {
    final platform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = platform;
    final config = DatabaseConfig(name: 'test_db');
    final first = await NativeSqlite.open(config);
    final second = await NativeSqlite.open(config);

    await first.close();
    await first.close();
    expect(platform.closeDatabaseCalls, 1);
    expect(InspectorConnect.debugIsRegistered('test_db'), isTrue);
    expect(await second.query('SELECT 1'), isA<QueryResult>());

    await second.close();
    expect(platform.closeDatabaseCalls, 2);
    expect(InspectorConnect.debugIsRegistered('test_db'), isFalse);
  });

  test('deleteDatabase completes without error', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    await expectLater(NativeSqlite.deleteDatabase('test_db'), completes);
  });

  test('deleteDatabase unregisters the database from the inspector', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    expect(InspectorConnect.debugIsRegistered('test_db'), isTrue);

    await NativeSqlite.deleteDatabase('test_db');

    expect(InspectorConnect.debugIsRegistered('test_db'), isFalse);
    expect(database.isClosed, isTrue);
  });

  test('inspector can be disabled before opening a database', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    InspectorConnect.enabled = false;

    await NativeSqlite.open(DatabaseConfig(name: 'test_db'));

    expect(InspectorConnect.debugIsRegistered('test_db'), isFalse);
  });

  test('inspector validates table names against sqlite_master', () async {
    final platform = InspectorSchemaPlatform();
    NativeSqlitePlatform.instance = platform;
    await NativeSqlite.open(DatabaseConfig(name: 'test_db'));

    await InspectorConnect.debugRequireTable('test_db', 'order details');
    await expectLater(
      InspectorConnect.debugRequireTable('test_db', 'missing'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('inspector validates and quotes the actual primary key', () async {
    final platform = InspectorSchemaPlatform();
    NativeSqlitePlatform.instance = platform;
    await NativeSqlite.open(DatabaseConfig(name: 'test_db'));

    expect(
      await InspectorConnect.debugResolvePrimaryKeyColumn(
        'test_db',
        'order details',
        'record id',
      ),
      'record id',
    );
    expect(platform.queries, contains('PRAGMA table_info("order details")'));
    await expectLater(
      InspectorConnect.debugResolvePrimaryKeyColumn(
        'test_db',
        'order details',
        'record id" OR 1=1 --',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('query with arguments passes them to platform', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final result = await database.query('SELECT * FROM users WHERE id = ?', [
      1,
    ]);
    expect(result.columns, ['id', 'name']);
    expect(result.rows, isNotEmpty);
    expect(fakePlatform.lastQuerySql, 'SELECT * FROM users WHERE id = ?');
    expect(fakePlatform.lastQueryArguments, [1]);
  });

  test('update without where clause', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final rows = await database.update('users', {'active': 0});
    expect(rows, 1);
  });

  test('delete without where clause', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final rows = await database.delete('users');
    expect(rows, 1);
  });

  test('whereArgs without a where clause are rejected', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));

    expect(
      () => database.update('users', {'active': 0}, whereArgs: [1]),
      throwsArgumentError,
    );
    expect(
      () => database.delete('users', where: '  ', whereArgs: [1]),
      throwsArgumentError,
    );
  });

  test('insert with null field values', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final id = await database.insert('users', {'name': 'Test', 'email': null});
    expect(id, 123);
  });

  test('transaction rolls back callback errors', () async {
    final fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    await expectLater(
      database.transaction<void>((transaction) async {
        await transaction.execute('UPDATE users SET active = ?', [false]);
        throw StateError('stop');
      }),
      throwsStateError,
    );
    expect(fakePlatform.transactionEnds, [false]);
  });

  test('transaction rejects nested, direct, and escaped operations', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    late NativeSqliteTransaction escaped;

    await database.transaction<void>((transaction) async {
      escaped = transaction;
      expect(() => database.query('SELECT 1'), throwsStateError);
      expect(() => database.transaction<void>((_) async {}), throwsStateError);
    });

    expect(() => escaped.query('SELECT 1'), throwsStateError);
  });

  test('calls from outside a transaction wait for it to finish', () async {
    NativeSqlitePlatform.instance = MockNativeSqlitePlatform();
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final entered = Completer<void>();
    final release = Completer<void>();
    final transaction = database.transaction<void>((_) async {
      entered.complete();
      await release.future;
    });
    await entered.future;

    var queryCompleted = false;
    final query = database.query('SELECT 1').then((value) {
      queryCompleted = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(queryCompleted, isFalse);

    release.complete();
    await transaction;
    await query;
    expect(queryCompleted, isTrue);
  });

  test('batch is one platform call and returns typed query results', () async {
    final fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;
    final database = await NativeSqlite.open(DatabaseConfig(name: 'test_db'));
    final batch = database.batch()
      ..execute('CREATE TABLE users (id INTEGER)')
      ..insert('users', {'name': 'A'})
      ..query('SELECT * FROM users');

    final results = await batch.commit();

    expect(fakePlatform.batchCalls, 1);
    expect(results, hasLength(3));
    expect(results.last, isA<QueryResult>());
    expect(() => batch.execute('SELECT 1'), throwsStateError);
    await expectLater(batch.commit(), throwsStateError);
  });
}
