import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/services/web_persistence_service.dart';

void main() {
  const name = 'web_persistence_service_test';
  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;

  setUpAll(() => backend = NativeSqliteTesting.useFfi());

  setUp(() async {
    await NativeSqlite.deleteDatabase(name);
    database = await NativeSqlite.open(DatabaseConfig(name: name));
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(name);
  });

  tearDownAll(() => backend.dispose());

  test('launch counter persists and increments atomically', () async {
    expect(await WebPersistenceService.recordLaunch(database), 1);
    expect(await WebPersistenceService.recordLaunch(database), 2);
    expect(await WebPersistenceService.readLaunchCount(database), 2);
  });
}
