import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';

void main() {
  group('DatabaseConfig constructor', () {
    test('sets required name field', () {
      final config = DatabaseConfig(name: 'my_db', version: 1, onCreate: []);
      expect(config.name, 'my_db');
    });

    test('defaults version to 1', () {
      final config = DatabaseConfig(name: 'my_db', onCreate: []);
      expect(config.version, 1);
    });

    test('defaults enableWAL to true', () {
      final config = DatabaseConfig(name: 'my_db', onCreate: []);
      expect(config.enableWAL, isTrue);
    });

    test('defaults enableForeignKeys to true', () {
      final config = DatabaseConfig(name: 'my_db', onCreate: []);
      expect(config.enableForeignKeys, isTrue);
    });

    test('accepts custom version', () {
      final config = DatabaseConfig(name: 'my_db', version: 5, onCreate: []);
      expect(config.version, 5);
    });

    test('rejects an empty name', () {
      expect(() => DatabaseConfig(name: '  '), throwsA(isA<ArgumentError>()));
    });

    test('rejects unsafe or extension-bearing names', () {
      for (final name in ['a.b', '../escape', '/absolute', 'space name']) {
        expect(
          () => DatabaseConfig(name: name),
          throwsA(isA<ArgumentError>()),
          reason: name,
        );
      }
    });

    test('validates custom locations', () {
      expect(
        () => DatabaseConfig(name: 'db', directory: 'relative/path'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => DatabaseConfig(
          name: 'db',
          directory: '/tmp/data',
          iosAppGroup: 'group.dev.nesmin',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects versions below one', () {
      expect(
        () => DatabaseConfig(name: 'my_db', version: 0),
        throwsA(isA<RangeError>()),
      );
    });

    test('accepts custom enableWAL', () {
      final config = DatabaseConfig(
        name: 'my_db',
        version: 1,
        onCreate: [],
        enableWAL: false,
      );
      expect(config.enableWAL, isFalse);
    });

    test('accepts custom enableForeignKeys', () {
      final config = DatabaseConfig(
        name: 'my_db',
        version: 1,
        onCreate: [],
        enableForeignKeys: false,
      );
      expect(config.enableForeignKeys, isFalse);
    });

    test('accepts onCreate statements', () {
      final stmts = [
        'CREATE TABLE users (id INTEGER PRIMARY KEY)',
        'CREATE TABLE posts (id INTEGER PRIMARY KEY)',
      ];
      final config = DatabaseConfig(name: 'my_db', version: 1, onCreate: stmts);
      expect(config.onCreate, stmts);
    });

    test('accepts onUpgrade statements', () {
      final stmts = ['ALTER TABLE users ADD COLUMN bio TEXT'];
      final config = DatabaseConfig(
        name: 'my_db',
        version: 2,
        onCreate: [],
        onUpgrade: stmts,
      );
      expect(config.onUpgrade, stmts);
    });

    test('upgradeStatements runs missing steps in order, then onUpgrade', () {
      final config = DatabaseConfig(
        name: 'my_db',
        version: 4,
        migrations: {
          2: ['ALTER TABLE users ADD COLUMN bio TEXT'],
          4: ['CREATE TABLE tags (id INTEGER PRIMARY KEY)'],
        },
        onUpgrade: ['CREATE INDEX IF NOT EXISTS idx ON users (bio)'],
      );

      expect(config.upgradeStatements(1), [
        'ALTER TABLE users ADD COLUMN bio TEXT',
        'CREATE TABLE tags (id INTEGER PRIMARY KEY)',
        'CREATE INDEX IF NOT EXISTS idx ON users (bio)',
      ]);
      expect(config.upgradeStatements(3), [
        'CREATE TABLE tags (id INTEGER PRIMARY KEY)',
        'CREATE INDEX IF NOT EXISTS idx ON users (bio)',
      ]);
    });
  });

  group('DatabaseConfig.toMap / fromMap', () {
    test('round-trips all fields through toMap/fromMap', () {
      final original = DatabaseConfig(
        name: 'my_db',
        version: 3,
        onCreate: ['CREATE TABLE users (id INTEGER PRIMARY KEY)'],
        onUpgrade: ['ALTER TABLE users ADD COLUMN bio TEXT'],
        migrations: {
          2: ['ALTER TABLE users ADD COLUMN age INTEGER'],
        },
        enableWAL: false,
        enableForeignKeys: false,
        directory: '/tmp/native-sqlite',
      );

      final restored = DatabaseConfig.fromMap(original.toMap());
      expect(restored.migrations, original.migrations);

      expect(restored.name, original.name);
      expect(restored.version, original.version);
      expect(restored.enableWAL, original.enableWAL);
      expect(restored.enableForeignKeys, original.enableForeignKeys);
      expect(restored.directory, original.directory);
      expect(restored.iosAppGroup, original.iosAppGroup);
      expect(restored.onCreate, original.onCreate);
      expect(restored.onUpgrade, original.onUpgrade);
    });

    test('fromMap uses default version 1 when missing', () {
      final config = DatabaseConfig.fromMap({'name': 'my_db'});
      expect(config.version, 1);
    });

    test('fromMap uses default enableWAL true when missing', () {
      final config = DatabaseConfig.fromMap({'name': 'my_db'});
      expect(config.enableWAL, isTrue);
    });

    test('fromMap uses default enableForeignKeys true when missing', () {
      final config = DatabaseConfig.fromMap({'name': 'my_db'});
      expect(config.enableForeignKeys, isTrue);
    });

    test('fromMap handles null onCreate', () {
      final config = DatabaseConfig.fromMap({
        'name': 'my_db',
        'onCreate': null,
      });
      expect(config.onCreate, isNull);
    });
  });

  group('DatabaseConfig equality', () {
    test('two configs with same fields are equal', () {
      final a = DatabaseConfig(name: 'db', version: 1, onCreate: []);
      final b = DatabaseConfig(name: 'db', version: 1, onCreate: []);

      expect(a, equals(b));
    });

    test('different names are not equal', () {
      final a = DatabaseConfig(name: 'db_a', version: 1, onCreate: []);
      final b = DatabaseConfig(name: 'db_b', version: 1, onCreate: []);

      expect(a, isNot(equals(b)));
    });

    test('different versions are not equal', () {
      final a = DatabaseConfig(name: 'db', version: 1, onCreate: []);
      final b = DatabaseConfig(name: 'db', version: 2, onCreate: []);

      expect(a, isNot(equals(b)));
    });

    test('same config has same hashCode', () {
      final a = DatabaseConfig(name: 'db', version: 1, onCreate: []);
      final b = DatabaseConfig(name: 'db', version: 1, onCreate: []);

      expect(a.hashCode, b.hashCode);
    });

    test('different schema statements are not equal', () {
      final a = DatabaseConfig(
        name: 'db',
        onCreate: ['CREATE TABLE a (id INTEGER)'],
        migrations: {
          2: ['ALTER TABLE a ADD COLUMN name TEXT'],
        },
      );
      final b = DatabaseConfig(
        name: 'db',
        onCreate: ['CREATE TABLE b (id INTEGER)'],
        migrations: {
          2: ['ALTER TABLE b ADD COLUMN name TEXT'],
        },
      );

      expect(a, isNot(equals(b)));
    });

    test('equal schema collections have equal hashes', () {
      final a = DatabaseConfig(
        name: 'db',
        onUpgrade: ['CREATE INDEX idx ON users (name)'],
        migrations: {
          2: ['ALTER TABLE users ADD COLUMN name TEXT'],
        },
      );
      final b = DatabaseConfig(
        name: 'db',
        onUpgrade: ['CREATE INDEX idx ON users (name)'],
        migrations: {
          2: ['ALTER TABLE users ADD COLUMN name TEXT'],
        },
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('DatabaseConfig open compatibility', () {
    test('ignores SQL formatting and comments', () {
      final compact = DatabaseConfig(
        name: 'db',
        onCreate: ['CREATE TABLE "items" ("id" INTEGER, "name" TEXT)'],
      );
      final formatted = DatabaseConfig(
        name: 'db',
        onCreate: [
          '''
          -- generated schema
          CREATE TABLE "items" (
            "id" INTEGER,
            "name" TEXT
          )
          ''',
        ],
      );

      expect(compact.hasSameOpenConfiguration(formatted), isTrue);
    });

    test('does not merge distinct SQL tokens or settings', () {
      final config = DatabaseConfig(name: 'db', onCreate: ['SELECT a, b']);
      expect(
        config.hasSameOpenConfiguration(
          DatabaseConfig(name: 'db', onCreate: ['SELECT ab']),
        ),
        isFalse,
      );
      expect(
        config.hasSameOpenConfiguration(
          DatabaseConfig(
            name: 'db',
            onCreate: ['SELECT a, b'],
            enableWAL: false,
          ),
        ),
        isFalse,
      );
    });
  });

  group('DatabaseConfig.toString', () {
    test('includes name and version', () {
      final config = DatabaseConfig(name: 'my_db', version: 2, onCreate: []);
      final str = config.toString();

      expect(str, contains('my_db'));
      expect(str, contains('2'));
    });
  });
}
