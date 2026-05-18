import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeSqlitePlatform
    with MockPlatformInterfaceMixin
    implements NativeSqlitePlatform {
  @override
  Future<String> openDatabase(DatabaseConfig config) {
    return Future.value('/path/to/${config.name}');
  }

  @override
  Future<void> closeDatabase(String databaseName) {
    return Future.value();
  }

  @override
  Future<String?> getDatabasePath(String databaseName) {
    return Future.value('/path/to/$databaseName');
  }

  @override
  Future<void> deleteDatabase(String databaseName) {
    return Future.value();
  }

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) {
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
  Future<bool> transaction(String databaseName, List<String> sqlStatements) {
    return Future.value(true);
  }
}

void main() {
  test('getDatabasePath', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    expect(await NativeSqlite.getDatabasePath('test_db'), '/path/to/test_db');
  });

  test('open', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final config = DatabaseConfig(name: 'test_db', version: 1, onCreate: []);
    expect(await NativeSqlite.open(config: config), '/path/to/test_db');
  });

  test('insert', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final id = await NativeSqlite.insert('test_db', 'users', {'name': 'Test'});
    expect(id, 123);
  });

  test('query', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final result = await NativeSqlite.query('test_db', 'SELECT * FROM users');
    expect(result.columns, ['id', 'name']);
    expect(result.rows.first, [1, 'Test User']);
  });

  test('update', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final rows = await NativeSqlite.update(
      'test_db',
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

    final rows = await NativeSqlite.delete(
      'test_db',
      'users',
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(rows, 1);
  });

  test('transaction', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final success = await NativeSqlite.transaction('test_db', [
      'INSERT INTO users (name) VALUES ("A")',
      'INSERT INTO users (name) VALUES ("B")',
    ]);
    expect(success, true);
  });

  test('execute returns affected row count', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final affected = await NativeSqlite.execute(
      'test_db',
      'UPDATE users SET name = ? WHERE id = ?',
      ['Updated', 1],
    );
    expect(affected, 1);
  });

  test('execute without arguments', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final affected = await NativeSqlite.execute(
      'test_db',
      'DELETE FROM users',
    );
    expect(affected, 1);
  });

  test('close completes without error', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    await expectLater(NativeSqlite.close('test_db'), completes);
  });

  test('deleteDatabase completes without error', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    await expectLater(NativeSqlite.deleteDatabase('test_db'), completes);
  });

  test('query with arguments passes them to platform', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final result = await NativeSqlite.query(
      'test_db',
      'SELECT * FROM users WHERE id = ?',
      [1],
    );
    expect(result.columns, ['id', 'name']);
    expect(result.rows, isNotEmpty);
  });

  test('update without where clause', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final rows = await NativeSqlite.update(
      'test_db',
      'users',
      {'active': 0},
    );
    expect(rows, 1);
  });

  test('delete without where clause', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final rows = await NativeSqlite.delete('test_db', 'users');
    expect(rows, 1);
  });

  test('insert with null field values', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final id = await NativeSqlite.insert(
      'test_db',
      'users',
      {'name': 'Test', 'email': null},
    );
    expect(id, 123);
  });

  test('transaction with empty list', () async {
    MockNativeSqlitePlatform fakePlatform = MockNativeSqlitePlatform();
    NativeSqlitePlatform.instance = fakePlatform;

    final success = await NativeSqlite.transaction('test_db', []);
    expect(success, true);
  });
}
