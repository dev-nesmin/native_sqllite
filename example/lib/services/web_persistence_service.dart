import 'package:native_sqlite/native_sqlite.dart';

/// Stores and reads a browser-launch counter in SQLite.
abstract final class WebPersistenceService {
  static const _table = 'web_launch_counter';

  /// Records one application launch and returns the updated count.
  static Future<int> recordLaunch(NativeSqliteDatabase database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS $_table ('
      'id INTEGER PRIMARY KEY CHECK (id = 1), '
      'launch_count INTEGER NOT NULL)',
    );
    await database.execute(
      'INSERT INTO $_table (id, launch_count) VALUES (1, 1) '
      'ON CONFLICT(id) DO UPDATE SET launch_count = launch_count + 1',
    );
    return readLaunchCount(database);
  }

  /// Reads the number of browser launches recorded in SQLite.
  static Future<int> readLaunchCount(NativeSqliteDatabase database) async {
    final result = await database.query(
      'SELECT launch_count FROM $_table WHERE id = 1',
    );
    return result.rows.isEmpty ? 0 : result.rows.single.single! as int;
  }
}
