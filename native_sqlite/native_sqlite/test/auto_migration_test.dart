import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';

void main() {
  group('AutoMigration.createConfig', () {
    DatabaseConfig create({
      Map<int, List<String>> migrations = const {},
      List<String> ensure = const [],
      bool? enableWAL,
      bool? enableForeignKeys,
    }) => AutoMigration.createConfig(
      name: 'app',
      schemaVersion: 3,
      onCreateStatements: ['CREATE TABLE users (id INTEGER PRIMARY KEY)'],
      migrations: migrations,
      ensureSchemaStatements: ensure,
      enableWAL: enableWAL ?? true,
      enableForeignKeys: enableForeignKeys ?? true,
    );

    test('maps name, version and create statements', () {
      final config = create();
      expect(config.name, 'app');
      expect(config.version, 3);
      expect(config.onCreate, ['CREATE TABLE users (id INTEGER PRIMARY KEY)']);
    });

    test('defaults WAL and foreign keys to enabled', () {
      final config = create();
      expect(config.enableWAL, isTrue);
      expect(config.enableForeignKeys, isTrue);
    });

    test('respects disabled WAL and foreign keys', () {
      final config = create(enableWAL: false, enableForeignKeys: false);
      expect(config.enableWAL, isFalse);
      expect(config.enableForeignKeys, isFalse);
    });

    test('passes migrations to the platform (sent over the channel)', () {
      final config = create(migrations: {2: ['A'], 3: ['B']});
      expect(config.toMap()['migrations'], {2: ['A'], 3: ['B']});
    });

    test('upgrades apply only steps after the stored version', () {
      final config = create(
        migrations: {2: ['A'], 3: ['B', 'C']},
        ensure: ['CREATE TABLE IF NOT EXISTS x (id INTEGER)'],
      );
      expect(config.upgradeStatements(1), [
        'A',
        'B',
        'C',
        'CREATE TABLE IF NOT EXISTS x (id INTEGER)',
      ]);
      expect(config.upgradeStatements(2), [
        'B',
        'C',
        'CREATE TABLE IF NOT EXISTS x (id INTEGER)',
      ]);
    });
  });

  group('AutoMigration.detectNewTables', () {
    test('returns create statements for tables not yet in database', () async {
      final tables = {
        'users': 'CREATE TABLE users (id INTEGER PRIMARY KEY)',
        'posts': 'CREATE TABLE posts (id INTEGER PRIMARY KEY)',
      };
      final tableNames = ['users', 'posts'];

      final statements = await AutoMigration.detectNewTables(
        databaseName: 'test_db',
        tables: tables,
        tableNames: tableNames,
        queryFn: (_) async => [
          {'name': 'users'},
        ],
      );

      expect(statements, ['CREATE TABLE posts (id INTEGER PRIMARY KEY)']);
    });

    test('returns empty list when all tables already exist', () async {
      final tables = {
        'users': 'CREATE TABLE users (id INTEGER PRIMARY KEY)',
      };

      final statements = await AutoMigration.detectNewTables(
        databaseName: 'test_db',
        tables: tables,
        tableNames: ['users'],
        queryFn: (_) async => [
          {'name': 'users'},
        ],
      );

      expect(statements, isEmpty);
    });

    test('returns all statements when database is empty', () async {
      final tables = {
        'users': 'CREATE TABLE users (id INTEGER PRIMARY KEY)',
        'posts': 'CREATE TABLE posts (id INTEGER PRIMARY KEY)',
      };

      final statements = await AutoMigration.detectNewTables(
        databaseName: 'test_db',
        tables: tables,
        tableNames: ['users', 'posts'],
        queryFn: (_) async => [],
      );

      expect(statements.length, 2);
    });

    test('passes correct SQL query to queryFn', () async {
      String? capturedSql;

      await AutoMigration.detectNewTables(
        databaseName: 'test_db',
        tables: {},
        tableNames: [],
        queryFn: (sql) async {
          capturedSql = sql;
          return [];
        },
      );

      expect(capturedSql, contains('sqlite_master'));
      expect(capturedSql, contains("type='table'"));
    });
  });

  group('AutoMigration.detectRemovedTables', () {
    test('returns DROP statements for tables in DB but not in schema', () async {
      final statements = await AutoMigration.detectRemovedTables(
        tableNames: ['users'],
        queryFn: (_) async => [
          {'name': 'users'},
          {'name': 'legacy_data'},
          {'name': 'old_cache'},
        ],
      );

      expect(statements, contains('DROP TABLE IF EXISTS "legacy_data"'));
      expect(statements, contains('DROP TABLE IF EXISTS "old_cache"'));
      expect(statements, isNot(contains('DROP TABLE IF EXISTS "users"')));
    });

    test('returns empty list when DB matches schema exactly', () async {
      final statements = await AutoMigration.detectRemovedTables(
        tableNames: ['users', 'posts'],
        queryFn: (_) async => [
          {'name': 'users'},
          {'name': 'posts'},
        ],
      );

      expect(statements, isEmpty);
    });

    test('returns empty list when database has no tables', () async {
      final statements = await AutoMigration.detectRemovedTables(
        tableNames: ['users'],
        queryFn: (_) async => [],
      );

      expect(statements, isEmpty);
    });
  });
}
