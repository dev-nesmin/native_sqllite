import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';

void main() {
  group('QueryResult.toMapList', () {
    test('converts rows to list of maps', () {
      final result = QueryResult(
        columns: ['id', 'name', 'email'],
        rows: [
          [1, 'Alice', 'alice@example.com'],
          [2, 'Bob', 'bob@example.com'],
        ],
      );

      final maps = result.toMapList();

      expect(maps.length, 2);
      expect(maps[0], {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'});
      expect(maps[1], {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'});
    });

    test('returns empty list for empty result', () {
      final result = QueryResult(columns: ['id', 'name'], rows: []);
      expect(result.toMapList(), isEmpty);
    });

    test('fills missing columns with null when row is shorter', () {
      final result = QueryResult(
        columns: ['id', 'name', 'email'],
        rows: [
          [1, 'Alice'],
        ],
      );

      final maps = result.toMapList();
      expect(maps[0]['id'], 1);
      expect(maps[0]['name'], 'Alice');
      expect(maps[0]['email'], isNull);
    });

    test('handles null values in rows', () {
      final result = QueryResult(
        columns: ['id', 'bio'],
        rows: [
          [1, null],
        ],
      );

      final maps = result.toMapList();
      expect(maps[0]['bio'], isNull);
    });
  });

  group('QueryResult.toTypedList', () {
    test('wraps each row as TypedRow', () {
      final result = QueryResult(
        columns: ['id', 'name'],
        rows: [
          [1, 'Alice'],
        ],
      );

      final typed = result.toTypedList();
      expect(typed, hasLength(1));
      expect(typed.first['name'], 'Alice');
    });
  });

  group('QueryResult.toMap / fromMap', () {
    test('round-trips columns and rows through toMap/fromMap', () {
      final original = QueryResult(
        columns: ['id', 'name'],
        rows: [
          [1, 'Alice'],
          [2, 'Bob'],
        ],
      );

      final restored = QueryResult.fromMap(original.toMap());
      expect(restored.columns, original.columns);
      expect(restored.rows.length, original.rows.length);
    });

    test('fromMap with empty rows', () {
      final result = QueryResult.fromMap({
        'columns': ['id'],
        'rows': <dynamic>[],
      });

      expect(result.columns, ['id']);
      expect(result.rows, isEmpty);
    });
  });

  group('QueryResult equality and toString', () {
    test('two results with same columns and row count are equal', () {
      final a = QueryResult(
        columns: ['id', 'name'],
        rows: [
          [1, 'Alice'],
        ],
      );
      final b = QueryResult(
        columns: ['id', 'name'],
        rows: [
          [2, 'Bob'],
        ],
      );

      expect(a, equals(b));
    });

    test('results with different columns are not equal', () {
      final a = QueryResult(columns: ['id'], rows: []);
      final b = QueryResult(columns: ['name'], rows: []);

      expect(a, isNot(equals(b)));
    });

    test('toString includes column and row info', () {
      final result = QueryResult(
        columns: ['id', 'name'],
        rows: [
          [1, 'Alice'],
        ],
      );
      expect(result.toString(), contains('columns'));
      expect(result.toString(), contains('1 rows'));
    });
  });

  group('TypedRow', () {
    late TypedRow row;

    setUp(() {
      row = TypedRow({
        'id': 42,
        'name': 'Alice',
        'score': 9.5,
        'active': 1,
        'bio': null,
        'count': '7',
      });
    });

    test('operator[] returns value by key', () {
      expect(row['id'], 42);
      expect(row['name'], 'Alice');
    });

    test('operator[] returns null for missing key', () {
      expect(row['missing'], isNull);
    });

    test('getString returns string value', () {
      expect(row.getString('name'), 'Alice');
    });

    test('getString returns default for null value', () {
      expect(row.getString('bio'), '');
      expect(row.getString('bio', 'N/A'), 'N/A');
    });

    test('getString converts non-string via toString', () {
      expect(row.getString('id'), '42');
    });

    test('getInt returns int value', () {
      expect(row.getInt('id'), 42);
    });

    test('getInt parses string value', () {
      expect(row.getInt('count'), 7);
    });

    test('getInt returns default for null', () {
      expect(row.getInt('bio'), 0);
      expect(row.getInt('bio', -1), -1);
    });

    test('getDouble returns double value', () {
      expect(row.getDouble('score'), 9.5);
    });

    test('getDouble converts int to double', () {
      expect(row.getDouble('id'), 42.0);
    });

    test('getDouble returns default for null', () {
      expect(row.getDouble('bio'), 0.0);
    });

    test('getBool returns true for int 1', () {
      expect(row.getBool('active'), isTrue);
    });

    test('getBool returns false for int 0', () {
      final zeroRow = TypedRow({'flag': 0});
      expect(zeroRow.getBool('flag'), isFalse);
    });

    test('getBool returns default for null', () {
      expect(row.getBool('bio'), isFalse);
    });

    test('getBool parses string "true"', () {
      final strRow = TypedRow({'flag': 'true'});
      expect(strRow.getBool('flag'), isTrue);
    });

    test('getBool parses string "false"', () {
      final strRow = TypedRow({'flag': 'false'});
      expect(strRow.getBool('flag'), isFalse);
    });

    test('getFormattedNumber formats to fixed decimals', () {
      expect(row.getFormattedNumber('score', 2), '9.50');
    });

    test('getFormattedNumber returns default for null', () {
      expect(row.getFormattedNumber('bio', 2), '0.00');
    });

    test('keys exposes all row keys', () {
      expect(row.keys, containsAll(['id', 'name', 'score', 'active']));
    });

    test('toMap returns unmodifiable map', () {
      final map = row.toMap();
      expect(() => (map as dynamic)['newKey'] = 'x', throwsUnsupportedError);
    });

    test('toString returns string representation', () {
      expect(row.toString(), isA<String>());
      expect(row.toString(), contains('Alice'));
    });
  });
}
