import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_example/generated/database_manager.dart';
import 'package:native_sqlite_example/models/user.dart';

/// Runs on a real device/simulator: exercises the platform implementation
/// (Android SQLiteOpenHelper / iOS NativeSqliteManager), not mocks.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const native = MethodChannel('com.example.native_sqlite_example/native');

  Future<int> scalar(String db, String sql) async =>
      (await NativeSqlite.query(db, sql)).rows.first.first as int;

  group('generated DatabaseManager', () {
    setUpAll(() async {
      await NativeSqlite.deleteDatabase(DatabaseManager.defaultDatabaseName)
          .catchError((_) {});
      await DatabaseManager.init();
    });

    test('creates the schema at the generated version', () async {
      final db = DatabaseManager.currentDatabase;
      expect(await scalar(db, 'PRAGMA user_version'), DatabaseManager.schemaVersion);
      expect(await scalar(db, 'PRAGMA foreign_keys'), 1);
      final tables = await NativeSqlite.query(
        db,
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.rows.map((r) => r.first).toSet();
      expect(names, containsAll(DatabaseManager.tableNames));
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

      final fromNative = await native.invokeListMethod<Map>('getUsersFromNative');
      expect(fromNative!.map((u) => u['id']), containsAll([dartId, nativeId]));

      final report = await native.invokeMethod<String>('testNativeAccess');
      expect(report, contains('All native access tests passed'));
    }, skip: kIsWeb ? 'No native side on the web' : false);
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

    Future<void> open(int version, {Map<int, List<String>> steps = migrations}) =>
        NativeSqlite.open(
          config: DatabaseConfig(
            name: name,
            version: version,
            onCreate: createV1,
            migrations: steps,
          ),
        );

    setUpAll(() async {
      await NativeSqlite.deleteDatabase(name).catchError((_) {});
      await open(1);
      await NativeSqlite.execute(name, "INSERT INTO authors (name) VALUES ('ada')");
      await NativeSqlite.execute(name, 'INSERT INTO books (author_id) VALUES (1), (1)');
      await NativeSqlite.close(name);
    });

    tearDownAll(() => NativeSqlite.deleteDatabase(name));

    test('applies only the missing steps and keeps data', () async {
      await open(2);
      expect(await scalar(name, 'PRAGMA user_version'), 2);
      await NativeSqlite.execute(name, "UPDATE authors SET bio = 'b' WHERE id = 1");
      await NativeSqlite.close(name);

      await open(3);
      expect(await scalar(name, 'PRAGMA user_version'), 3);
      expect(await scalar(name, 'SELECT COUNT(*) FROM books'), 2);
      expect(
        (await NativeSqlite.query(name, 'SELECT bio FROM authors')).rows.single.single,
        'b',
      );
      expect(await scalar(name, 'PRAGMA foreign_keys'), 1);
      await NativeSqlite.close(name);
    });

    test('rejects downgrades', () async {
      await expectLater(open(1), throwsA(anything));
    });

    test('rolls back a migration that violates a foreign key', () async {
      await expectLater(
        open(4, steps: {4: ['DELETE FROM authors']}),
        throwsA(anything),
      );
      await open(3);
      expect(await scalar(name, 'PRAGMA user_version'), 3);
      expect(await scalar(name, 'SELECT COUNT(*) FROM authors'), 1);
      await NativeSqlite.close(name);
    });
  });
}
