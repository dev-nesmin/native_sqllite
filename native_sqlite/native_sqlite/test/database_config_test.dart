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

    test('accepts custom enableWAL', () {
      final config = DatabaseConfig(
          name: 'my_db', version: 1, onCreate: [], enableWAL: false);
      expect(config.enableWAL, isFalse);
    });

    test('accepts custom enableForeignKeys', () {
      final config = DatabaseConfig(
          name: 'my_db',
          version: 1,
          onCreate: [],
          enableForeignKeys: false);
      expect(config.enableForeignKeys, isFalse);
    });

    test('accepts onCreate statements', () {
      final stmts = [
        'CREATE TABLE users (id INTEGER PRIMARY KEY)',
        'CREATE TABLE posts (id INTEGER PRIMARY KEY)',
      ];
      final config =
          DatabaseConfig(name: 'my_db', version: 1, onCreate: stmts);
      expect(config.onCreate, stmts);
    });

    test('accepts onUpgrade statements', () {
      final stmts = ['ALTER TABLE users ADD COLUMN bio TEXT'];
      final config = DatabaseConfig(
          name: 'my_db', version: 2, onCreate: [], onUpgrade: stmts);
      expect(config.onUpgrade, stmts);
    });

    test('accepts onMigrateCallback', () async {
      var called = false;
      final config = DatabaseConfig(
        name: 'my_db',
        version: 2,
        onCreate: [],
        onMigrateCallback: (oldV, newV) async {
          called = true;
          return ['ALTER TABLE users ADD COLUMN bio TEXT'];
        },
      );

      expect(config.onMigrateCallback, isNotNull);
      final result = await config.onMigrateCallback!(1, 2);
      expect(called, isTrue);
      expect(result, ['ALTER TABLE users ADD COLUMN bio TEXT']);
    });
  });

  group('DatabaseConfig.toMap / fromMap', () {
    test('round-trips all fields through toMap/fromMap', () {
      final original = DatabaseConfig(
        name: 'my_db',
        version: 3,
        onCreate: ['CREATE TABLE users (id INTEGER PRIMARY KEY)'],
        onUpgrade: ['ALTER TABLE users ADD COLUMN bio TEXT'],
        enableWAL: false,
        enableForeignKeys: false,
      );

      final restored = DatabaseConfig.fromMap(original.toMap());

      expect(restored.name, original.name);
      expect(restored.version, original.version);
      expect(restored.enableWAL, original.enableWAL);
      expect(restored.enableForeignKeys, original.enableForeignKeys);
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
      final config = DatabaseConfig.fromMap({'name': 'my_db', 'onCreate': null});
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
