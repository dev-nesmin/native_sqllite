import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';

void main() {
  group('AutoMigration.createConfig', () {
    test('returns DatabaseConfig with correct name and version', () {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 3,
        onCreateStatements: ['CREATE TABLE users (id INTEGER PRIMARY KEY)'],
        tables: {'users': 'CREATE TABLE users (id INTEGER PRIMARY KEY)'},
        tableNames: ['users'],
        migrations: [],
      );

      expect(config.name, 'test_db');
      expect(config.version, 3);
    });

    test('sets onCreateStatements as onCreate', () {
      final statements = [
        'CREATE TABLE users (id INTEGER PRIMARY KEY)',
        'CREATE TABLE posts (id INTEGER PRIMARY KEY)',
      ];
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 1,
        onCreateStatements: statements,
        tables: {},
        tableNames: [],
        migrations: [],
      );

      expect(config.onCreate, statements);
    });

    test('defaults enableWAL to true', () {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 1,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
      );

      expect(config.enableWAL, isTrue);
    });

    test('defaults enableForeignKeys to true', () {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 1,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
      );

      expect(config.enableForeignKeys, isTrue);
    });

    test('respects custom enableWAL=false', () {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 1,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
        enableWAL: false,
      );

      expect(config.enableWAL, isFalse);
    });

    test('respects custom enableForeignKeys=false', () {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 1,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
        enableForeignKeys: false,
      );

      expect(config.enableForeignKeys, isFalse);
    });

    test('attaches onMigrateCallback', () {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
      );

      expect(config.onMigrateCallback, isNotNull);
    });
  });

  group('AutoMigration.createConfig - migration callback with migrations list',
      () {
    test('applies migration SQL from migrations list', () async {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [
          {
            'sql': [
              'ALTER TABLE users ADD COLUMN bio TEXT',
              'CREATE INDEX idx_users_email ON users (email)',
            ],
          },
        ],
      );

      final statements = await config.onMigrateCallback!(1, 2);
      expect(statements, [
        'ALTER TABLE users ADD COLUMN bio TEXT',
        'CREATE INDEX idx_users_email ON users (email)',
      ]);
    });

    test('handles multiple migration entries', () async {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 3,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [
          {
            'sql': ['ALTER TABLE users ADD COLUMN bio TEXT'],
          },
          {
            'sql': ['ALTER TABLE posts ADD COLUMN published_at INTEGER'],
          },
        ],
      );

      final statements = await config.onMigrateCallback!(1, 3);
      expect(statements.length, 2);
      expect(statements[0], contains('bio'));
      expect(statements[1], contains('published_at'));
    });

    test('skips migration entry with null sql', () async {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [
          {'sql': null},
          {
            'sql': ['ALTER TABLE users ADD COLUMN bio TEXT'],
          },
        ],
      );

      final statements = await config.onMigrateCallback!(1, 2);
      expect(statements, ['ALTER TABLE users ADD COLUMN bio TEXT']);
    });
  });

  group('AutoMigration.createConfig - fallback migration (no migrations list)',
      () {
    test('generates CREATE TABLE IF NOT EXISTS for each table', () async {
      const createSql =
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)';
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {'users': createSql},
        tableNames: ['users'],
        migrations: [],
      );

      final statements = await config.onMigrateCallback!(1, 2);
      expect(statements.length, 1);
      expect(statements.first,
          contains('CREATE TABLE IF NOT EXISTS users'));
    });

    test('drops deleted tables when dropRemovedTables=true', () async {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {'users': 'CREATE TABLE users (id INTEGER PRIMARY KEY)'},
        tableNames: ['users'],
        migrations: [],
        deletedTableNames: ['old_table', 'legacy_data'],
        dropRemovedTables: true,
      );

      final statements = await config.onMigrateCallback!(1, 2);
      expect(
          statements, contains('DROP TABLE IF EXISTS old_table'));
      expect(
          statements, contains('DROP TABLE IF EXISTS legacy_data'));
    });

    test('does not drop tables when dropRemovedTables=false', () async {
      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
        deletedTableNames: ['old_table'],
        dropRemovedTables: false,
      );

      final statements = await config.onMigrateCallback!(1, 2);
      expect(statements, isNot(contains('DROP TABLE IF EXISTS old_table')));
    });

    test('calls onCustomMigrate callback', () async {
      var called = false;
      String? calledDb;
      int? calledOld;
      int? calledNew;

      final config = AutoMigration.createConfig(
        name: 'test_db',
        schemaVersion: 2,
        onCreateStatements: [],
        tables: {},
        tableNames: [],
        migrations: [],
        onCustomMigrate: (db, oldV, newV) async {
          called = true;
          calledDb = db;
          calledOld = oldV;
          calledNew = newV;
        },
      );

      await config.onMigrateCallback!(1, 2);

      expect(called, isTrue);
      expect(calledDb, 'test_db');
      expect(calledOld, 1);
      expect(calledNew, 2);
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

      expect(statements, contains('DROP TABLE IF EXISTS legacy_data'));
      expect(statements, contains('DROP TABLE IF EXISTS old_cache'));
      expect(statements, isNot(contains('DROP TABLE IF EXISTS users')));
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
