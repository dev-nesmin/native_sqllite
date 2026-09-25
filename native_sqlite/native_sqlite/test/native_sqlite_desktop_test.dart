import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/desktop.dart';
import 'package:native_sqlite/native_sqlite.dart' hide NativeSqliteDesktop;
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart'
    show NativeSqlitePlatform;

void main() {
  test(
    'desktop backend registers and persists in an explicit directory',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'native_sqlite_desktop_test_',
      );
      addTearDown(() {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      });

      final backend = NativeSqliteDesktop(directory: directory.path);
      NativeSqlitePlatform.instance = backend;
      addTearDown(backend.dispose);

      final database = await NativeSqlite.open(
        DatabaseConfig(
          name: 'desktop',
          onCreate: const [
            'CREATE TABLE values_table (id INTEGER PRIMARY KEY, value TEXT)',
          ],
        ),
      );
      expect(database.path, startsWith(directory.path));
      await database.insert('values_table', {'value': 'persistent'});
      await database.close();

      final reopened = await NativeSqlite.open(
        DatabaseConfig(
          name: 'desktop',
          onCreate: const [
            'CREATE TABLE values_table (id INTEGER PRIMARY KEY, value TEXT)',
          ],
        ),
      );
      expect((await reopened.query('SELECT value FROM values_table')).rows, [
        ['persistent'],
      ]);
      await reopened.close();
    },
  );
}
