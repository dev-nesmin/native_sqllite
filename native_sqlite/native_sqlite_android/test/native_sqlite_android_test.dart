import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite_android/native_sqlite_android.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('native_sqlite_android');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NativeSqliteAndroid platform;
  late List<MethodCall> calls;

  setUp(() {
    platform = NativeSqliteAndroid();
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'openDatabase' => '/tmp/app.db',
        'execute' => 2,
        'executeInsert' => 7,
        'query' => {
          'columns': ['id'],
          'rows': [
            [1],
          ],
        },
        'insert' => 8,
        'update' => 3,
        'delete' => 4,
        'batch' => [1],
        'getDatabasePath' => '/tmp/app.db',
        'databaseExists' => true,
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('uses the documented method names and argument maps', () async {
    final config = DatabaseConfig(
      name: 'app',
      onCreate: const ['CREATE TABLE t (id)'],
    );
    expect(await platform.openDatabase(config), '/tmp/app.db');
    expect(await platform.execute('app', 'UPDATE t SET id = ?', [1]), 2);
    expect(
      await platform.executeInsert('app', 'INSERT INTO t VALUES (?)', [1]),
      7,
    );
    expect((await platform.query('app', 'SELECT id FROM t', const [])).rows, [
      [1],
    ]);
    expect(await platform.insert('app', 't', const {'id': 1}), 8);
    expect(
      await platform.update(
        'app',
        't',
        const {'id': 2},
        where: 'id = ?',
        whereArgs: const [1],
      ),
      3,
    );
    expect(
      await platform.delete('app', 't', where: 'id = ?', whereArgs: const [2]),
      4,
    );
    await platform.beginTransaction('app', 'tx');
    await platform.endTransaction('app', 'tx', commit: true);
    expect(
      await platform.executeBatch('app', const [
        {'type': 'execute', 'sql': 'DELETE FROM t'},
      ]),
      [1],
    );
    expect(await platform.getDatabasePath('app'), '/tmp/app.db');
    expect(await platform.databaseExists('app'), isTrue);
    final bytes = ByteData(3).buffer.asUint8List()..setAll(0, const [1, 2, 3]);
    await platform.importDatabase('app', bytes, overwrite: true);
    await platform.closeDatabase('app');
    await platform.deleteDatabase('app');

    expect(calls.map((call) => call.method), [
      'openDatabase',
      'execute',
      'executeInsert',
      'query',
      'insert',
      'update',
      'delete',
      'beginTransaction',
      'endTransaction',
      'batch',
      'getDatabasePath',
      'databaseExists',
      'importDatabase',
      'closeDatabase',
      'deleteDatabase',
    ]);
    expect(calls[1].arguments, {
      'name': 'app',
      'sql': 'UPDATE t SET id = ?',
      'arguments': [1],
    });
    expect(calls[5].arguments, {
      'name': 'app',
      'table': 't',
      'values': {'id': 2},
      'where': 'id = ?',
      'whereArgs': [1],
    });
    expect(calls[8].arguments, {
      'name': 'app',
      'transactionId': 'tx',
      'commit': true,
    });
    final importArguments = calls[12].arguments! as Map<Object?, Object?>;
    expect(importArguments['name'], 'app');
    expect(importArguments['bytes'], orderedEquals([1, 2, 3]));
    expect(importArguments['overwrite'], isTrue);
  });

  test('maps structured channel errors and rejects missing results', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'NATIVE_SQLITE_ERROR',
        message: 'UNIQUE constraint failed: t.id',
        details: const {
          'code': 19,
          'extendedCode': 2067,
          'sql': 'INSERT INTO t VALUES (?)',
        },
      );
    });
    await expectLater(
      platform.executeInsert('app', 'INSERT INTO t VALUES (?)', const [1]),
      throwsA(
        isA<NativeSqliteException>()
            .having((error) => error.resultCode, 'resultCode', 19)
            .having((error) => error.extendedResultCode, 'extended', 2067)
            .having((error) => error.isUniqueViolation, 'unique', isTrue),
      ),
    );

    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await expectLater(
      platform.execute('app', 'DELETE FROM t', const []),
      throwsStateError,
    );
  });
}
