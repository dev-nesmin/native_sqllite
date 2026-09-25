import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';

void main() {
  const name = 'api_gaps_test';
  late NativeSqliteFfi backend;

  setUpAll(() => backend = NativeSqliteTesting.useFfi());

  setUp(() => NativeSqlite.deleteDatabase(name));
  tearDown(() => NativeSqlite.deleteDatabase(name));
  tearDownAll(() => backend.dispose());

  test('existence, open state, configure hook, and closeAll', () async {
    expect(await NativeSqlite.databaseExists(name), isFalse);
    final config = DatabaseConfig(
      name: name,
      busyTimeout: 1234,
      onConfigure: const ['PRAGMA cache_size = 321'],
      onCreate: const [
        'CREATE TABLE items ('
            'id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, value TEXT)',
      ],
    );
    final first = await NativeSqlite.open(config);
    final second = await NativeSqlite.open(config);

    expect(NativeSqlite.isOpen(name), isTrue);
    expect(await NativeSqlite.databaseExists(name), isTrue);
    expect((await first.query('PRAGMA busy_timeout')).rows.single.single, 1234);
    expect((await first.query('PRAGMA cache_size')).rows.single.single, 321);

    await NativeSqlite.closeAll();
    expect(first.isClosed, isTrue);
    expect(second.isClosed, isTrue);
    expect(NativeSqlite.isOpen(name), isFalse);
    expect(await NativeSqlite.databaseExists(name), isTrue);
  });

  test(
    'conflict algorithms and upsert quote identifiers and bind values',
    () async {
      final database = await NativeSqlite.open(
        DatabaseConfig(
          name: name,
          onCreate: const [
            'CREATE TABLE "order" ('
                'id INTEGER PRIMARY KEY, "key" TEXT NOT NULL UNIQUE, value TEXT)',
          ],
        ),
      );
      addTearDown(database.close);

      await database.insert('order', {
        'id': 1,
        'key': 'same',
        'value': 'first',
      });
      await database.insert('order', {
        'id': 2,
        'key': 'same',
        'value': 'ignored',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      expect((await database.query('SELECT count(*) FROM "order"')).rows, [
        [1],
      ]);

      expect(
        await database.upsert(
          'order',
          {'id': 3, 'key': 'same', 'value': 'updated'},
          conflictColumns: ['key'],
        ),
        1,
      );
      expect(
        (await database.query('SELECT id, value FROM "order"')).rows.single,
        [3, 'updated'],
      );

      await database.upsert(
        'order',
        {'id': 4, 'key': 'same', 'value': 'unused'},
        conflictColumns: ['key'],
        updateValues: const {'value': 'custom'},
      );
      expect(
        (await database.query('SELECT value FROM "order"')).rows.single.single,
        'custom',
      );
    },
  );

  test('opens a complete database file from an asset bundle', () async {
    final seeded = await NativeSqlite.open(
      DatabaseConfig(
        name: name,
        enableWAL: false,
        onCreate: const [
          'CREATE TABLE seed (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
          "INSERT INTO seed (value) VALUES ('from asset')",
        ],
      ),
    );
    final path = seeded.path;
    await seeded.close();
    final bytes = await File(path).readAsBytes();
    await NativeSqlite.deleteDatabase(name);

    final imported = await NativeSqlite.openFromAsset(
      DatabaseConfig(name: name, readOnly: true, enableWAL: false),
      'assets/seed.db',
      bundle: _MemoryAssetBundle(bytes),
    );
    addTearDown(imported.close);

    expect(
      (await imported.query('SELECT value FROM seed')).rows.single.single,
      'from asset',
    );
  });

  test('read-only opens query but reject writes and version changes', () async {
    final writable = await NativeSqlite.open(
      DatabaseConfig(
        name: name,
        onCreate: const [
          'CREATE TABLE entries (id INTEGER PRIMARY KEY, value TEXT)',
          "INSERT INTO entries (value) VALUES ('kept')",
        ],
      ),
    );
    await writable.close();

    final readOnly = await NativeSqlite.open(
      DatabaseConfig(name: name, readOnly: true, enableWAL: false),
    );
    expect(
      (await readOnly.query('SELECT value FROM entries')).rows.single.single,
      'kept',
    );
    await expectLater(
      readOnly.execute("INSERT INTO entries (value) VALUES ('blocked')"),
      throwsA(isA<NativeSqliteException>()),
    );
    await readOnly.close();

    await expectLater(
      NativeSqlite.open(
        DatabaseConfig(
          name: name,
          version: 2,
          readOnly: true,
          enableWAL: false,
        ),
      ),
      throwsStateError,
    );
  });

  test('watch refreshes for Dart and native-side writes', () async {
    final database = await NativeSqlite.open(
      DatabaseConfig(
        name: name,
        onCreate: const [
          'CREATE TABLE items (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
        ],
      ),
    );
    addTearDown(database.close);
    final results = StreamIterator(
      database.watch('SELECT value FROM items ORDER BY id', const [
        'items',
      ], pollInterval: const Duration(milliseconds: 10)),
    );
    addTearDown(results.cancel);

    expect(await results.moveNext(), isTrue);
    expect(results.current.rows, isEmpty);

    final change = database.tableChanges.first;
    await database.insert('items', {'id': 1, 'value': 'dart'});
    expect(await change, {'items'});
    expect(await results.moveNext(), isTrue);
    expect(results.current.rows, [
      ['dart'],
    ]);

    await backend.insert(name, 'items', {'id': 2, 'value': 'native'});
    expect(await results.moveNext(), isTrue);
    expect(results.current.rows, [
      ['dart'],
      ['native'],
    ]);
  });
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.bytes);

  final Uint8List bytes;

  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(bytes);
}
