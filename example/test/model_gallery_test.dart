import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/generated/database_manager.dart';
import 'package:native_sqlite_example/services/model_gallery_service.dart';

void main() {
  const databaseName = 'model_gallery_test';
  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;

  setUpAll(() {
    backend = NativeSqliteTesting.useFfi();
  });

  setUp(() async {
    await NativeSqlite.deleteDatabase(databaseName);
    database = await NativeSqlite.open(
      DatabaseConfig(
        name: databaseName,
        onCreate: DatabaseManager.onCreateStatements,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(databaseName);
  });

  tearDownAll(() {
    backend.dispose();
  });

  test('every gallery model saves and reads back equivalent values', () async {
    final results = await ModelGalleryService(database).runAll();

    expect(results, hasLength(13));
    expect(
      results
          .where((result) => !result.passed)
          .map((result) => '${result.model}: ${result.detail}'),
      isEmpty,
    );
  });

  test('new annotations produce their promised SQLite schema', () async {
    await ModelGalleryService(database).runAll();

    final attachmentType = await database.query(
      'SELECT typeof("bytes") FROM "attachments" LIMIT 1',
    );
    expect(attachmentType.rows.single.single, 'blob');

    final styledTags = await database.query(
      'SELECT "tags" FROM "styled_items" LIMIT 1',
    );
    expect(styledTags.rows.single.single, startsWith('['));
    expect(styledTags.rows.single.single, contains('comma,value'));

    final indexes = (await database.query(
      'PRAGMA index_list("tags")',
    )).toMapList();
    expect(
      indexes,
      contains(
        allOf(
          containsPair('name', 'idx_tags_label_unique'),
          containsPair('unique', 1),
        ),
      ),
    );
    final columns = (await database.query(
      'PRAGMA table_info("tags")',
    )).toMapList();
    expect(columns.map((column) => column['name']), contains('label_text'));
  });
}
