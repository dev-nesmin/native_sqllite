import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/generated/database_manager.dart';
import 'package:native_sqlite_example/services/database_maintenance_service.dart';

void main() {
  const databaseName = 'database_maintenance_test';
  late NativeSqliteFfi backend;

  setUpAll(() async {
    backend = NativeSqliteTesting.useFfi();
    await DatabaseManager.close();
    await NativeSqlite.deleteDatabase(databaseName);
    await DatabaseManager.init(name: databaseName);
  });

  tearDownAll(() async {
    await DatabaseManager.close();
    await NativeSqlite.deleteDatabase(databaseName);
    backend.dispose();
  });

  Future<int> count(String table) async {
    final result = await DatabaseManager.currentDatabase.query(
      'SELECT COUNT(*) FROM "$table"',
    );
    return result.rows.single.single as int;
  }

  test(
    'sample generation is atomic, repeatable, and covers every table',
    () async {
      final service = DatabaseMaintenanceService(
        DatabaseManager.currentDatabase,
      );
      final first = await service.generateSampleData();
      final second = await service.generateSampleData();

      expect(first.keys, unorderedEquals(DatabaseManager.tableNames));
      expect(second.keys, unorderedEquals(DatabaseManager.tableNames));
      for (final table in DatabaseManager.tableNames) {
        final perRun = table == 'comments' ? 2 : 1;
        expect(await count(table), perRun * 2, reason: table);
      }

      await expectLater(
        service.generateSampleData(forceFailure: true),
        throwsA(isA<StateError>()),
      );
      for (final table in DatabaseManager.tableNames) {
        final perRun = table == 'comments' ? 2 : 1;
        expect(await count(table), perRun * 2, reason: '$table rolled back');
      }
    },
  );

  test(
    'reset closes, deletes, and recreates a fresh generated schema',
    () async {
      await DatabaseMaintenanceService.resetDatabase();

      expect(DatabaseManager.isInitialized, isTrue);
      expect(DatabaseManager.currentDatabaseName, databaseName);
      final version = await DatabaseManager.currentDatabase.query(
        'PRAGMA user_version',
      );
      expect(version.rows.single.single, DatabaseManager.schemaVersion);
      for (final table in DatabaseManager.tableNames) {
        expect(await count(table), 0, reason: table);
      }
    },
  );
}
