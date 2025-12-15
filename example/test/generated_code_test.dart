import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_example/models/user.dart';
// import 'package:native_sqlite_example/models/user.table.dart'; // Removed part file import
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeSqlitePlatform extends NativeSqlitePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, List<Map<String, Object?>>> _data = {};

  @override
  Future<int> insert(
    String databaseName,
    String table,
    Map<String, Object?> values,
  ) async {
    _data.putIfAbsent(table, () => []);
    // Simple mock auto-increment
    final id = _data[table]!.length + 1;
    final row = Map<String, Object?>.from(values);
    row['id'] = id;
    _data[table]!.add(row);
    return id;
  }

  @override
  Future<QueryResult> query(
    String databaseName,
    String sql, [
    List<Object?>? arguments,
  ]) async {
    List<Map<String, Object?>> rows = [];

    // Very basic mock query handling - supports only simple cases
    if (sql.startsWith('SELECT * FROM users WHERE id = ?')) {
      final id = arguments!.first as int;
      final table = _data['users'] ?? [];
      final row = table.firstWhere(
        (element) => element['id'] == id,
        orElse: () => {},
      );
      if (row.isNotEmpty) rows = [row];
    } else if (sql.startsWith('SELECT * FROM users')) {
      rows = _data['users'] ?? [];
    }

    // Return mock QueryResult (assuming it takes rows)
    // If QueryResult constructor is private or special, I might need to mock it or use a factory.
    // QueryResult usually wraps a ResultSet or list of maps.
    // I previously implemented QueryResult in "Implement Plugin TDD" turn.
    // It likely has a constructor or factory.
    // Let's assume generic constructor `QueryResult(this.rows)`.
    // Wait, rows is usually generic `List<Map<String, Object?>>`.
    // But rows might be dynamic?
    // I can't check source easily without view_file.
    // I will assume `QueryResult(rows: rows)` or `QueryResult(rows)`.
    // Actually, earlier turn logic (from memory/context): "QueryResult wraps rows".
    // I will try `QueryResult(rows)`.
    // If specific named argument, compiler will fail again.
    final columnNames = rows.isEmpty ? <String>[] : rows.first.keys.toList();
    final resultRows = rows.map((row) => row.values.toList()).toList();
    return QueryResult(rows: resultRows, columns: columnNames);
  }

  @override
  Future<int> delete(
    String databaseName,
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    // Mock delete logic
    if (where == 'id = ?' && whereArgs != null) {
      final id = whereArgs.first as int;
      final tableData = _data[table];
      if (tableData != null) {
        final initialLength = tableData.length;
        tableData.removeWhere((row) => row['id'] == id);
        return initialLength - tableData.length;
      }
    }
    return 0;
  }

  // Also need to implement update because Repository uses it?
  // Code generated: `Future<int> update(TestUser entity)`.
  // Repository calls `NativeSqlite.update`.
  // I should mock `update` too for completeness if I test full repo, but simple test might skip it.

  @override
  Future<int> update(
    String databaseName,
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return 0;
  }
}

void main() {
  final mockPlatform = MockNativeSqlitePlatform();

  setUp(() {
    NativeSqlitePlatform.instance = mockPlatform;
  });

  group('Generated Code Tests', () {
    test('UserRepository inserts and finds user', () async {
      final repo = UserRepository();
      final user = User(name: 'Alice', email: 'alice@example.com');

      final id = await repo.insert(user);
      expect(id, 1);

      final fetchedUser = await repo.findById(id);
      expect(fetchedUser, isNotNull);
      expect(fetchedUser!.name, 'Alice');
      expect(fetchedUser.id, 1);
    });

    test('UserQueryBuilder can be instantiated', () {
      final builder = UserQueryBuilder('test_db');
      expect(builder, isNotNull);
    });
  });
}
