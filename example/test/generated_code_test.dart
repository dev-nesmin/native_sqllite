import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/generated/database_manager.dart';
import 'package:native_sqlite_example/models/manual_log.dart';
import 'package:native_sqlite_example/models/user.dart';

void main() {
  const databaseName = 'generated_code_test';
  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;

  setUpAll(() {
    backend = NativeSqliteTesting.useFfi();
  });

  setUp(() async {
    await NativeSqlite.deleteDatabase(databaseName);
    database = await NativeSqlite.open(
      DatabaseConfig(name: databaseName, onCreate: [UserSchema.createTableSql]),
    );
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(databaseName);
  });

  tearDownAll(() {
    backend.dispose();
  });

  test('generated repository and query builder use real SQLite', () async {
    final repository = UserRepository(database);
    final id = await repository.insert(
      User(name: 'Alice', email: 'alice@example.com'),
    );

    final fetched = await repository.findById(id);
    expect(fetched?.name, 'Alice');
    expect(fetched?.id, id);
    expect(
      (await UserQueryBuilder(
        database,
      ).nameEqualTo('Alice').findAll()).single.id,
      id,
    );
  });

  test('Dart and SQL defaults for age agree', () async {
    const email = 'default@example.com';
    await database.executeInsert(
      'INSERT INTO "users" ("name", "email", "is_active", "created_at") '
      'VALUES (?, ?, ?, ?)',
      ['Default', email, 1, 0],
    );
    final raw = await database.query(
      'SELECT "age" FROM "users" WHERE "email" = ?',
      [email],
    );

    expect(User(name: 'Dart', email: 'dart@example.com').age, 18);
    expect(raw.rows.single.single, 18);
  });

  test('auto false tables keep their API but are not managed', () {
    expect(ManualLogSchema.createTableSql, contains('manual_logs'));
    expect(DatabaseManager.tableNames, isNot(contains('manual_logs')));
    expect(
      DatabaseManager.ensureSchemaStatements.join('\n'),
      isNot(contains('manual_logs')),
    );
  });
}
