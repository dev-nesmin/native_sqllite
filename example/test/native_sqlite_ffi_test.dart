import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';

void main() {
  const name = 'host_ffi_conformance';
  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;

  setUpAll(() {
    backend = NativeSqliteTesting.useFfi();
  });

  setUp(() async {
    await NativeSqlite.deleteDatabase(name);
    database = await NativeSqlite.open(
      DatabaseConfig(
        name: name,
        version: 2,
        onCreate: const [
          'CREATE TABLE parents (id INTEGER PRIMARY KEY)',
          'CREATE TABLE entries ('
              'id INTEGER PRIMARY KEY, value TEXT NOT NULL UNIQUE, payload BLOB)',
          'CREATE TABLE children ('
              'id INTEGER PRIMARY KEY, parent_id INTEGER NOT NULL, '
              'FOREIGN KEY (parent_id) REFERENCES parents(id))',
        ],
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(name);
  });

  tearDownAll(() {
    backend.dispose();
  });

  test(
    'uses a real file database with typed values and affected counts',
    () async {
      expect(File(database.path).existsSync(), isTrue);
      expect(
        (await database.query('PRAGMA user_version')).rows.single.single,
        2,
      );

      final id = await database.insert('entries', {
        'value': 'typed',
        'payload': Uint8List.fromList([0, 127, 255]),
      });
      expect(id, greaterThan(0));
      expect(
        await database.execute('UPDATE entries SET value = ? WHERE id = ?', [
          'updated',
          id,
        ]),
        1,
      );

      final row = (await database.query(
        'SELECT value, payload FROM entries WHERE id = ?',
        [id],
      )).rows.single;
      expect(row.first, 'updated');
      expect(row.last, Uint8List.fromList([0, 127, 255]));
    },
  );

  test('commits, rolls back, and executes batches atomically', () async {
    await database.transaction((transaction) async {
      await transaction.insert('entries', {'id': 1, 'value': 'committed'});
    });

    await expectLater(
      database.transaction<void>((transaction) async {
        await transaction.insert('entries', {'id': 2, 'value': 'rolled-back'});
        await transaction.insert('entries', {'id': 3, 'value': 'committed'});
      }),
      throwsA(isA<NativeSqliteException>()),
    );

    final batch = database.batch()
      ..insert('entries', {'id': 4, 'value': 'batch-a'})
      ..execute('INSERT INTO entries (id, value) VALUES (?, ?)', [5, 'batch-b'])
      ..query('SELECT COUNT(*) FROM entries');
    final results = await batch.commit();

    expect(results, hasLength(3));
    expect((results.last as QueryResult).rows.single.single, 3);
    expect(
      (await database.query('SELECT COUNT(*) FROM entries')).rows.single.single,
      3,
    );
  });

  test('uses the cross-platform typed SQLite error contract', () async {
    await database.insert('entries', {'id': 1, 'value': 'private-value'});

    Future<NativeSqliteException> capture(
      Future<Object?> Function() operation,
    ) async {
      try {
        await operation();
        fail('Expected NativeSqliteException');
      } on NativeSqliteException catch (error) {
        return error;
      }
    }

    final unique = await capture(
      () => database.insert('entries', {'id': 2, 'value': 'private-value'}),
    );
    expect(unique.extendedResultCode, 2067);
    expect(unique.isUniqueViolation, isTrue);
    expect(unique.toString(), isNot(contains('private-value')));

    final notNull = await capture(
      () => database.insert('entries', {'id': 3, 'value': null}),
    );
    expect(notNull.extendedResultCode, 1299);

    final foreignKey = await capture(
      () => database.insert('children', {'id': 1, 'parent_id': 999}),
    );
    expect(foreignKey.extendedResultCode, 787);

    final syntax = await capture(() => database.execute('INSRT broken'));
    expect(syntax.resultCode, 1);
  });

  test('applies versioned migrations and preserves existing data', () async {
    const migrationName = 'host_ffi_migration';
    await NativeSqlite.deleteDatabase(migrationName);
    final versionOne = await NativeSqlite.open(
      DatabaseConfig(
        name: migrationName,
        onCreate: const [
          'CREATE TABLE records (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
        ],
      ),
    );
    await versionOne.insert('records', {'id': 1, 'value': 'kept'});
    await versionOne.close();

    final versionTwo = await NativeSqlite.open(
      DatabaseConfig(
        name: migrationName,
        version: 2,
        onCreate: const [
          'CREATE TABLE records ('
              'id INTEGER PRIMARY KEY, value TEXT NOT NULL, note TEXT)',
        ],
        migrations: const {
          2: ['ALTER TABLE records ADD COLUMN note TEXT'],
        },
      ),
    );
    expect(
      (await versionTwo.query(
        'SELECT value FROM records WHERE id = 1',
      )).rows.single.single,
      'kept',
    );
    expect(
      (await versionTwo.query('PRAGMA user_version')).rows.single.single,
      2,
    );
    await versionTwo.close();
    await NativeSqlite.deleteDatabase(migrationName);
  });
}
