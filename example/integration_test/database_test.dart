import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_example/generated/database_manager.dart';
import 'package:native_sqlite_example/main.dart';
import 'package:native_sqlite_example/models/note.dart';
import 'package:native_sqlite_example/models/sync_event.dart';
import 'package:native_sqlite_example/models/user.dart';
import 'package:native_sqlite_example/services/database_maintenance_service.dart';
import 'package:native_sqlite_example/services/model_gallery_service.dart';
import 'package:native_sqlite_example/services/raw_api_demo_service.dart';

/// Runs on a real device/simulator: exercises the platform implementation
/// (Android SQLiteOpenHelper / iOS NativeSqliteManager), not mocks.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const native = MethodChannel('com.example.native_sqlite_example/native');

  Future<int> scalar(NativeSqliteDatabase db, String sql) async =>
      (await db.query(sql)).rows.first.first as int;

  group('native-first connection ownership', () {
    test('Dart reuses and does not close the native connection', () async {
      final name = DatabaseManager.defaultDatabaseName;
      await NativeSqlite.deleteDatabase(name).catchError((_) {});

      expect(await native.invokeMethod<String>('openDatabaseFromNative'), name);
      await DatabaseManager.init();
      await DatabaseManager.close();

      final probe = await NativeSqlite.open(
        AutoMigration.createConfig(
          name: name,
          schemaVersion: DatabaseManager.schemaVersion,
          onCreateStatements: DatabaseManager.onCreateStatements,
          migrations: DatabaseManager.migrations,
          ensureSchemaStatements: DatabaseManager.ensureSchemaStatements,
        ),
      );
      expect(await scalar(probe, 'PRAGMA user_version'), greaterThan(0));
      await probe.close();

      await native.invokeMethod<void>('closeDatabaseFromNative');
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
    });
  }, skip: kIsWeb ? 'No native side on the web' : false);

  group('idempotent open', () {
    const name = 'idempotent_open_test';
    final config = DatabaseConfig(
      name: name,
      onCreate: const ['CREATE TABLE values_test (value INTEGER NOT NULL)'],
    );

    setUp(() => NativeSqlite.deleteDatabase(name).catchError((_) {}));
    tearDown(() => NativeSqlite.deleteDatabase(name).catchError((_) {}));

    test('keeps the shared connection until every owner closes', () async {
      final pathBeforeOpen = await NativeSqlite.getDatabasePath(name);
      final first = await NativeSqlite.open(config);
      expect(first.path, pathBeforeOpen);
      await first.execute('INSERT INTO values_test (value) VALUES (42)');
      final second = await NativeSqlite.open(config);

      await first.close();
      expect(await scalar(second, 'SELECT value FROM values_test'), 42);

      await second.close();
      expect(() => second.query('SELECT 1'), throwsStateError);
    });

    test('rejects a different configuration without replacing it', () async {
      final database = await NativeSqlite.open(config);
      await expectLater(
        NativeSqlite.open(
          DatabaseConfig(name: name, version: 2, onCreate: config.onCreate),
        ),
        throwsA(isA<Object>()),
      );
      expect(await scalar(database, 'PRAGMA user_version'), 1);
      await database.close();
    });
  });

  test('raw API and typed errors agree on this platform', () async {
    final results = await const RawApiDemoService().run();
    expect(results, hasLength(16));
    expect(results.every((result) => result.passed), isTrue);
    final errors = {
      for (final result in results) result.operation: result.error,
    };
    expect(errors['UNIQUE']?.extendedResultCode, 2067);
    expect(errors['NOT NULL']?.extendedResultCode, 1299);
    expect(errors['FOREIGN KEY']?.extendedResultCode, 787);
    expect(errors['syntax error']?.resultCode, 1);
  });

  test(
    'background isolate registers the plugin and writes through the handle API',
    () async {
      const name = 'background_isolate_test';
      final token = ServicesBinding.rootIsolateToken!;
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      addTearDown(() => NativeSqlite.deleteDatabase(name).catchError((_) {}));

      await Isolate.run(() async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);
        ui.DartPluginRegistrant.ensureInitialized();
        final database = await NativeSqlite.open(
          DatabaseConfig(
            name: name,
            onCreate: const [
              'CREATE TABLE isolate_values (value TEXT NOT NULL)',
            ],
          ),
        );
        await database.insert('isolate_values', {'value': 'from-isolate'});
        await database.close();
      });

      final database = await NativeSqlite.open(
        DatabaseConfig(
          name: name,
          onCreate: const ['CREATE TABLE isolate_values (value TEXT NOT NULL)'],
        ),
      );
      expect(
        (await database.query(
          'SELECT value FROM isolate_values',
        )).rows.single.single,
        'from-isolate',
      );
      await database.close();
    },
    skip: kIsWeb ? 'Dart web does not support Isolate.run' : false,
  );

  group('background platform work', () {
    const name = 'frame_responsiveness_test';
    late NativeSqliteDatabase database;

    setUp(() async {
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      database = await NativeSqlite.open(DatabaseConfig(name: name));
    });
    tearDown(() async {
      await database.close();
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
    });

    test('Dart frame timers keep running during a long native query', () async {
      final clock = Stopwatch()..start();
      final timerSamples = <Duration>[Duration.zero];
      final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        timerSamples.add(clock.elapsed);
      });
      addTearDown(timer.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final queryClock = Stopwatch()..start();
      final result = await database.query('''
        WITH RECURSIVE counter(value) AS (
          SELECT 0
          UNION ALL
          SELECT value + 1 FROM counter WHERE value < 30000000
        )
        SELECT sum(value) FROM counter
      ''');
      queryClock.stop();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      timer.cancel();

      expect(result.rows.single.single, 450000015000000);
      expect(queryClock.elapsed, greaterThan(const Duration(seconds: 2)));
      final largestTimerGap = <Duration>[
        for (var index = 1; index < timerSamples.length; index++)
          timerSamples[index] - timerSamples[index - 1],
      ].reduce((left, right) => left > right ? left : right);
      expect(timerSamples.length, greaterThan(30));
      expect(
        largestTimerGap,
        lessThan(const Duration(milliseconds: 750)),
        reason: 'The Dart/UI event loop stalled for $largestTimerGap.',
      );
    }, skip: kIsWeb ? 'Web SQLite runs in the Dart isolate' : false);
  });

  group('interactive transactions and batch', () {
    const name = 'transaction_batch_test';
    late NativeSqliteDatabase database;

    setUpAll(() async {
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      database = await NativeSqlite.open(
        DatabaseConfig(
          name: name,
          onCreate: [
            'CREATE TABLE entries ('
                'id INTEGER PRIMARY KEY, value TEXT NOT NULL UNIQUE)',
            'CREATE TABLE parents (id INTEGER PRIMARY KEY)',
            'CREATE TABLE children (id INTEGER PRIMARY KEY, parent_id INTEGER NOT NULL, '
                'FOREIGN KEY (parent_id) REFERENCES parents(id))',
          ],
        ),
      );
    });

    tearDownAll(() async {
      await database.close();
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
    });

    test('commits writes and supports reads with bound arguments', () async {
      final count = await database.transaction((transaction) async {
        await transaction.insert('entries', {'id': 1, 'value': 'first'});
        await transaction.execute(
          'INSERT INTO entries (id, value) VALUES (?, ?)',
          [2, 'second'],
        );
        final result = await transaction.query(
          'SELECT COUNT(*) FROM entries WHERE id >= ?',
          [1],
        );
        return result.rows.single.single as int;
      });

      expect(count, 2);
      expect(await scalar(database, 'SELECT COUNT(*) FROM entries'), 2);
    });

    test('rolls back every write when a later statement fails', () async {
      await expectLater(
        database.transaction<void>((transaction) async {
          await transaction.execute(
            'INSERT INTO entries (id, value) VALUES (?, ?)',
            [3, 'third'],
          );
          await transaction.execute(
            'INSERT INTO entries (id, value) VALUES (?, ?)',
            [4, 'first'],
          );
        }),
        throwsA(anything),
      );

      expect(await scalar(database, 'SELECT COUNT(*) FROM entries'), 2);
    });

    test('execute reports changes and raw inserts report row IDs', () async {
      expect(
        await database.execute(
          'CREATE TABLE execute_results (id INTEGER PRIMARY KEY, value TEXT)',
        ),
        0,
      );
      final rowId = await database.executeInsert(
        'INSERT INTO execute_results (value) VALUES (?)',
        ['created'],
      );
      expect(rowId, greaterThan(0));
      expect(
        await database.execute(
          'UPDATE execute_results SET value = ? WHERE id = ?',
          ['updated', rowId],
        ),
        1,
      );
    });

    test('reports typed SQLite result codes without bound values', () async {
      Future<NativeSqliteException> capture(
        Future<Object?> Function() operation,
      ) async {
        try {
          await operation();
          fail('Expected a NativeSqliteException');
        } on NativeSqliteException catch (error) {
          return error;
        }
      }

      const privateValue = 'must-not-appear-in-errors';
      await database.insert('entries', {'id': 89, 'value': privateValue});
      final unique = await capture(
        () => database.executeInsert(
          'INSERT INTO entries (id, value) VALUES (?, ?)',
          [90, privateValue],
        ),
      );
      expect(unique.resultCode, 19);
      expect(unique.extendedResultCode, 2067);
      expect(unique.isUniqueViolation, isTrue);
      expect(unique.sql, contains('?'));
      expect(unique.toString(), isNot(contains(privateValue)));

      final notNull = await capture(
        () => database.executeInsert(
          'INSERT INTO entries (id, value) VALUES (?, ?)',
          [91, null],
        ),
      );
      expect(notNull.resultCode, 19);
      expect(notNull.extendedResultCode, 1299);
      expect(notNull.isNotNullViolation, isTrue);
      expect(notNull.toString(), isNot(contains(privateValue)));

      final foreignKey = await capture(
        () => database.executeInsert(
          'INSERT INTO children (id, parent_id) VALUES (?, ?)',
          [1, 999],
        ),
      );
      expect(foreignKey.resultCode, 19);
      expect(foreignKey.extendedResultCode, 787);
      expect(foreignKey.isForeignKeyViolation, isTrue);

      final syntax = await capture(
        () => database.execute('INSRT INTO entries (id) VALUES (?)', [92]),
      );
      expect(syntax.resultCode, 1);
      expect(syntax.extendedResultCode, 1);
      expect(syntax.isSyntaxError, isTrue);
    });

    test('executes 10000 parameterized inserts in one batch', () async {
      final batch = database.batch();
      for (var id = 10000; id < 20000; id++) {
        batch.execute('INSERT INTO entries (id, value) VALUES (?, ?)', [
          id,
          'batch-$id',
        ]);
      }

      final results = await batch.commit();

      expect(results, hasLength(10000));
      expect(
        await scalar(
          database,
          'SELECT COUNT(*) FROM entries WHERE id >= 10000',
        ),
        10000,
      );
    });
  });

  group('generated DatabaseManager', () {
    setUpAll(() async {
      await NativeSqlite.deleteDatabase(
        DatabaseManager.defaultDatabaseName,
      ).catchError((_) {});
      await DatabaseManager.init();
    });

    test('creates the schema at the generated version', () async {
      final db = DatabaseManager.currentDatabase;
      expect(
        await scalar(db, 'PRAGMA user_version'),
        DatabaseManager.schemaVersion,
      );
      expect(await scalar(db, 'PRAGMA foreign_keys'), 1);
      final tables = await db.query(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.rows.map((r) => r.first).toSet();
      expect(names, containsAll(DatabaseManager.tableNames));
    });

    test('round-trips every gallery model through the platform', () async {
      final results = await ModelGalleryService(
        DatabaseManager.currentDatabase,
      ).runAll();
      expect(results, hasLength(13));
      expect(
        results
            .where((result) => !result.passed)
            .map((result) => '${result.model}: ${result.detail}'),
        isEmpty,
      );
    });

    test('generated native helpers round-trip every gallery model', () async {
      final models = await native.invokeListMethod<String>(
        'roundTripModelGallery',
      );
      expect(
        models,
        containsAll([
          'User',
          'Category',
          'Product',
          'Order',
          'Profile',
          'AdvancedUser',
          'FreezedAdvancedUser',
          'StyledItem',
          'Note',
          'Attachment',
          'Tag',
          'Comment',
          'SyncEvent',
        ]),
      );
    }, skip: kIsWeb ? 'No generated native helpers on the web' : false);

    test('native background task body writes a Dart-readable row', () async {
      final id = await native.invokeMethod<int>('runBackgroundSyncNow');
      expect(id, isNotNull);
      final event = await SyncEventRepository(
        DatabaseManager.currentDatabase,
      ).findById(id);
      expect(event?.source, 'native-worker');
      expect(event?.message, isNotEmpty);
    }, skip: kIsWeb ? 'No platform-native background scheduler' : false);

    test('sample generation repeats and reset recreates every table', () async {
      final maintenance = DatabaseMaintenanceService(
        DatabaseManager.currentDatabase,
      );
      await maintenance.generateSampleData();
      await maintenance.generateSampleData();
      for (final table in DatabaseManager.tableNames) {
        final result = await DatabaseManager.currentDatabase.query(
          'SELECT COUNT(*) FROM "$table"',
        );
        expect(result.rows.single.single as int, greaterThanOrEqualTo(2));
      }

      await DatabaseMaintenanceService.resetDatabase();
      for (final table in DatabaseManager.tableNames) {
        final result = await DatabaseManager.currentDatabase.query(
          'SELECT COUNT(*) FROM "$table"',
        );
        expect(result.rows.single.single, 0, reason: table);
      }
    });

    test('Dart and native code share the same database', () async {
      final repository = UserRepository(DatabaseManager.currentDatabase);
      final dartId = await repository.insert(
        User(name: 'From Dart', email: 'dart@test.dev'),
      );

      final nativeId = await native.invokeMethod<int>('createUserFromNative', {
        'name': 'From Native',
        'email': 'native@test.dev',
      });
      expect(await repository.findById(nativeId), isNotNull);

      final fromNative = await native.invokeListMethod<Map<Object?, Object?>>(
        'getUsersFromNative',
      );
      expect(fromNative!.map((u) => u['id']), containsAll([dartId, nativeId]));

      final report = await native.invokeMethod<String>('testNativeAccess');
      expect(report, contains('All native access tests passed'));
    }, skip: kIsWeb ? 'No native side on the web' : false);

    test('iOS native writes remain safe during repeated Dart opens', () async {
      final config = AutoMigration.createConfig(
        name: DatabaseManager.defaultDatabaseName,
        schemaVersion: DatabaseManager.schemaVersion,
        onCreateStatements: DatabaseManager.onCreateStatements,
        migrations: DatabaseManager.migrations,
        ensureSchemaStatements: DatabaseManager.ensureSchemaStatements,
      );
      final nativeWrites = native.invokeMethod<int>('stressNativeWrites');

      for (var iteration = 0; iteration < 200; iteration++) {
        final database = await NativeSqlite.open(config);
        await database.close();
      }

      expect(await nativeWrites, 200);
    }, skip: defaultTargetPlatform != TargetPlatform.iOS);
  });

  group('platform migrations', () {
    const name = 'migration_test';
    const createV1 = [
      'CREATE TABLE authors (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)',
      'CREATE TABLE books (id INTEGER PRIMARY KEY AUTOINCREMENT, author_id INTEGER NOT NULL, '
          'FOREIGN KEY (author_id) REFERENCES authors(id) ON DELETE CASCADE)',
    ];
    const migrations = {
      2: ['ALTER TABLE authors ADD COLUMN bio TEXT'],
      // Rebuilds the parent table: with foreign keys on, DROP TABLE would
      // cascade-delete every book.
      3: [
        'CREATE TABLE authors_new (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL, bio TEXT, email TEXT UNIQUE)',
        'INSERT INTO authors_new (id, name, bio) SELECT id, name, bio FROM authors',
        'DROP TABLE authors',
        'ALTER TABLE authors_new RENAME TO authors',
      ],
    };

    Future<NativeSqliteDatabase> open(
      int version, {
      Map<int, List<String>> steps = migrations,
    }) => NativeSqlite.open(
      DatabaseConfig(
        name: name,
        version: version,
        onCreate: createV1,
        migrations: steps,
      ),
    );

    setUpAll(() async {
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      final database = await open(1);
      await database.execute("INSERT INTO authors (name) VALUES ('ada')");
      await database.execute('INSERT INTO books (author_id) VALUES (1), (1)');
      await database.close();
    });

    tearDownAll(() => NativeSqlite.deleteDatabase(name));

    test('applies only the missing steps and keeps data', () async {
      final v2 = await open(2);
      expect(await scalar(v2, 'PRAGMA user_version'), 2);
      await v2.execute("UPDATE authors SET bio = 'b' WHERE id = 1");
      await v2.close();

      final v3 = await open(3);
      expect(await scalar(v3, 'PRAGMA user_version'), 3);
      expect(await scalar(v3, 'SELECT COUNT(*) FROM books'), 2);
      expect(
        (await v3.query('SELECT bio FROM authors')).rows.single.single,
        'b',
      );
      expect(await scalar(v3, 'PRAGMA foreign_keys'), 1);
      await v3.close();
    });

    test('rejects downgrades', () async {
      await expectLater(open(1), throwsA(anything));
    });

    test('rolls back a migration that violates a foreign key', () async {
      await expectLater(
        open(
          4,
          steps: {
            4: ['DELETE FROM authors'],
          },
        ),
        throwsA(anything),
      );
      final database = await open(3);
      expect(await scalar(database, 'PRAGMA user_version'), 3);
      expect(await scalar(database, 'SELECT COUNT(*) FROM authors'), 1);
      await database.close();
    });

    test('rejects multiple statements in one schema entry', () async {
      const invalidName = 'multiple_statement_schema_test';
      await NativeSqlite.deleteDatabase(invalidName).catchError((_) {});
      try {
        await expectLater(
          NativeSqlite.open(
            DatabaseConfig(
              name: invalidName,
              onCreate: [
                'CREATE TABLE first_schema_tail (id INTEGER); '
                    'CREATE TABLE second_schema_tail (id INTEGER)',
              ],
            ),
          ),
          throwsA(anything),
        );
      } finally {
        await NativeSqlite.deleteDatabase(invalidName).catchError((_) {});
      }
    });
  });

  group('quoted identifiers', () {
    const name = 'quoted_identifier_test';
    late NativeSqliteDatabase database;

    setUpAll(() async {
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      database = await NativeSqlite.open(
        DatabaseConfig(
          name: name,
          version: 1,
          onCreate: [
            'CREATE TABLE "order" ('
                '"select" INTEGER PRIMARY KEY AUTOINCREMENT, '
                '"group" TEXT NOT NULL)',
          ],
        ),
      );
    });

    tearDownAll(() async {
      await database.close();
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
    });

    test('insert, update and delete quote table and map keys', () async {
      final id = await database.insert('order', {'group': 'created'});
      expect(
        (await database.query(
          'SELECT "group" FROM "order" WHERE "select" = ?',
          [id],
        )).rows.single.single,
        'created',
      );

      expect(
        await database.update(
          'order',
          {'group': 'updated'},
          where: '"select" = ?',
          whereArgs: [id],
        ),
        1,
      );
      expect(
        (await database.query(
          'SELECT "group" FROM "order"',
        )).rows.single.single,
        'updated',
      );

      expect(
        await database.delete('order', where: '"select" = ?', whereArgs: [id]),
        1,
      );
      expect(await scalar(database, 'SELECT COUNT(*) FROM "order"'), 0);
    });
  });

  group('UUID primary keys', () {
    test('Dart and native helpers generate round-trippable UUIDs', () async {
      final repository = NoteRepository(DatabaseManager.currentDatabase);
      final dartId = await repository.insert(const Note(body: 'From Dart'));
      expect(dartId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect((await repository.findById(dartId))?.body, 'From Dart');

      if (!kIsWeb) {
        final nativeId = await native.invokeMethod<String>(
          'createNoteFromNative',
          {'body': 'From Native'},
        );
        expect(nativeId, matches(RegExp(r'^[0-9A-Fa-f-]{36}$')));
        expect((await repository.findById(nativeId))?.body, 'From Native');
      }
    });
  });

  group('typed SQL arguments', () {
    const name = 'typed_arguments_test';
    late NativeSqliteDatabase database;

    setUpAll(() async {
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      database = await NativeSqlite.open(
        DatabaseConfig(
          name: name,
          onCreate: [
            'CREATE TABLE values_test ('
                'id INTEGER PRIMARY KEY, payload BLOB, flag INTEGER, '
                'text_value TEXT)',
          ],
        ),
      );
    });

    tearDownAll(() async {
      await database.close();
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
    });

    test('preserves SQLite storage classes in every binding path', () async {
      final types = await database.query(
        'SELECT typeof(?), typeof(?), typeof(?), typeof(?), ? = 1',
        [
          1,
          1.5,
          null,
          Uint8List.fromList([1]),
          true,
        ],
      );
      expect(types.rows.single, ['integer', 'real', 'null', 'blob', 1]);

      await database.execute(
        'INSERT INTO values_test (id, payload, flag) VALUES (?, ?, ?)',
        [
          1,
          Uint8List.fromList([1]),
          true,
        ],
      );
      expect(
        await database.update(
          'values_test',
          {
            'payload': Uint8List.fromList([2, 3]),
          },
          where: 'flag = ?',
          whereArgs: [true],
        ),
        1,
      );
      expect(
        await scalar(
          database,
          'SELECT length(payload) FROM values_test WHERE flag = 1',
        ),
        2,
      );
      expect(
        await database.delete(
          'values_test',
          where: 'payload = ?',
          whereArgs: [
            Uint8List.fromList([2, 3]),
          ],
        ),
        1,
      );
    });

    test(
      'round-trips a row larger than the default Android cursor window',
      () async {
        final payload = Uint8List(3 * 1024 * 1024);
        for (var index = 0; index < payload.length; index += 4096) {
          payload[index] = index ~/ 4096 % 256;
        }
        await database.insert('values_test', {'id': 99, 'payload': payload});

        final result = await database.query(
          'SELECT payload FROM values_test WHERE id = ?',
          [99],
        );
        expect(result.rows.single.single, payload);
      },
    );

    test('round-trips empty blobs and text containing NUL bytes', () async {
      await database.insert('values_test', {
        'id': 100,
        'payload': Uint8List(0),
        'text_value': 'before\u0000after',
      });

      final result = await database.query(
        'SELECT payload, text_value FROM values_test WHERE id = 100',
      );
      expect(result.rows.single[0], Uint8List(0));
      expect(result.rows.single[1], 'before\u0000after');
    });

    test(
      'execute accepts row-returning statements and empty where deletes all',
      () async {
        expect(await database.execute('SELECT 1'), 0);
        expect(await database.execute('PRAGMA cache_size = -1000'), 0);
        await database.insert('values_test', {'id': 101});
        await database.insert('values_test', {'id': 102});
        expect(await database.delete('values_test', where: ''), greaterThan(1));
        expect(await scalar(database, 'SELECT COUNT(*) FROM values_test'), 0);
      },
    );

    test('surfaces step errors and rejects empty SQL', () async {
      await expectLater(
        database.query("SELECT json_extract('x', '\$.a')"),
        throwsA(anything),
      );
      await expectLater(database.query('', const []), throwsA(anything));
    });

    test('rejects multiple statements in one SQL string', () async {
      await expectLater(
        database.execute(
          'CREATE TABLE first_tail_test (id INTEGER); '
          'CREATE TABLE second_tail_test (id INTEGER)',
        ),
        throwsA(anything),
      );

      final created = await database.query(
        "SELECT name FROM sqlite_master WHERE name LIKE '%_tail_test'",
      );
      expect(created.rows, isEmpty);
    });
  });

  group('example raw SQL screens', () {
    setUpAll(() async {
      if (!kIsWeb) {
        await native
            .invokeMethod<void>('closeDatabaseFromNative')
            .catchError((_) {});
      }
      await DatabaseManager.close().catchError((_) {});
      await NativeSqlite.deleteDatabase(
        DatabaseManager.defaultDatabaseName,
      ).catchError((_) {});
      await DatabaseManager.init();
    });

    tearDownAll(() async {
      if (!kIsWeb) {
        await native
            .invokeMethod<void>('closeDatabaseFromNative')
            .catchError((_) {});
      }
      await DatabaseManager.close().catchError((_) {});
      await NativeSqlite.deleteDatabase(
        DatabaseManager.defaultDatabaseName,
      ).catchError((_) {});
    });

    Future<void> openFeature(WidgetTester tester, String title) async {
      await tester.pumpWidget(
        KeyedSubtree(key: UniqueKey(), child: const MyApp()),
      );
      await tester.pumpAndSettle();
      final target = find.text(title);
      for (
        var attempt = 0;
        target.evaluate().isEmpty && attempt < 10;
        attempt++
      ) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(target, findsOneWidget);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    testWidgets('manual API operations use the generated schema', (
      tester,
    ) async {
      await openFeature(tester, 'Manual API Demo');
      await tester.enterText(find.byType(TextField).at(0), 'Manual Test User');
      await tester.enterText(
        find.byType(TextField).at(1),
        'manual${DateTime.now().microsecondsSinceEpoch}@test.dev',
      );
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Manual Test User'), findsOneWidget);

      await tester.tap(find.text('Stats Query'));
      await tester.pumpAndSettle();
      final stats = await DatabaseManager.currentDatabase.query(
        'SELECT COUNT(*) AS count, AVG(${UserSchema.AGE}) AS avg_age '
        'FROM ${UserSchema.tableName}',
      );
      expect(stats.rows.single.first, greaterThan(0));
    });

    testWidgets('advanced SQL demos complete successfully', (tester) async {
      await openFeature(tester, 'Advanced Features');
      final expectations = <String, String>{
        'Transactions': 'Transaction completed successfully!',
        'Foreign Keys': 'Foreign key constraint violation caught',
        'Indexes': 'Indexes improve query performance',
        'Complex Queries': 'Order statistics by status',
        'Custom Queries': 'available products:',
        'Batch Operations': 'Successfully inserted 50 users',
        'Data Types': 'All data types properly serialized',
      };

      for (final entry in expectations.entries) {
        final button = find.text(entry.key).first;
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final inkWell = find.ancestor(
          of: button,
          matching: find.byType(InkWell),
        );
        tester.widget<InkWell>(inkWell).onTap!();
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(
          find.textContaining(entry.value, findRichText: true),
          findsOneWidget,
          reason: '${entry.key} demo did not complete',
        );
      }
    });

    testWidgets('statistics renders the live sqlite_master schema', (
      tester,
    ) async {
      await openFeature(tester, 'Database Statistics');
      expect(find.text(UserSchema.tableName), findsOneWidget);
      expect(find.textContaining('CREATE TABLE "users"'), findsOneWidget);
    });

    testWidgets('native integration screen is platform-aware', (tester) async {
      await openFeature(tester, 'Native Code Integration');
      if (kIsWeb) {
        expect(
          find.textContaining('there are no platform-native actions'),
          findsOneWidget,
        );
        expect(find.text('Run Native Access Tests'), findsNothing);
      } else {
        expect(find.text('Run Native Access Tests'), findsOneWidget);
        expect(find.text('Create User from Native Code'), findsOneWidget);
        expect(find.text('Get Users from Native Code'), findsOneWidget);
      }
    });
  });
}
