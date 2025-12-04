import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NativeSqlite Integration Test', () {
    late String dbPath;
    const dbName = 'integration_test.db';

    setUp(() async {
      // Ensure clean state
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/$dbName');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore if file doesn't exist or other errors during cleanup
        print('Cleanup error: $e');
      }
    });

    testWidgets('Open, Insert, Query, Close', (WidgetTester tester) async {
      // 1. Open Database
      final path = await NativeSqlite.open(
        config: DatabaseConfig(
          name: dbName,
          version: 1,
          onCreate: [
            'CREATE TABLE test_table (id INTEGER PRIMARY KEY, value TEXT)',
          ],
        ),
      );

      expect(path, isNotEmpty);
      dbPath = path;

      // 2. Insert
      final id = await NativeSqlite.insert(dbName, 'test_table', {
        'value': 'Hello World',
      });
      expect(id, greaterThan(0));

      // 3. Query
      final result = await NativeSqlite.query(
        dbName,
        'SELECT * FROM test_table WHERE id = ?',
        [id],
      );

      final rows = result.toMapList();
      expect(rows.length, 1);
      expect(rows.first['value'], 'Hello World');

      // 4. Close
      await NativeSqlite.close(dbName);
    });
  });
}
