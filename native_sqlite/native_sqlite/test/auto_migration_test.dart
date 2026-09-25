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
      final config = create(
        migrations: {
          2: ['A'],
          3: ['B'],
        },
      );
      expect(config.toMap()['migrations'], {
        2: ['A'],
        3: ['B'],
      });
    });

    test('upgrades apply only steps after the stored version', () {
      final config = create(
        migrations: {
          2: ['A'],
          3: ['B', 'C'],
        },
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
}
