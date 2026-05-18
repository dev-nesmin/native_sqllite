import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:test/test.dart';

ColumnSchemaSnapshot _col({
  String dartName = 'id',
  String name = 'id',
  String type = 'INTEGER',
  bool nullable = false,
  bool primaryKey = true,
  bool autoIncrement = true,
  bool unique = false,
  String? defaultValue,
  String? foreignKey,
  bool isJsonField = false,
  bool hasConverter = false,
  String dartType = 'int',
}) {
  return ColumnSchemaSnapshot(
    dartName: dartName,
    name: name,
    type: type,
    nullable: nullable,
    primaryKey: primaryKey,
    autoIncrement: autoIncrement,
    unique: unique,
    defaultValue: defaultValue,
    foreignKey: foreignKey,
    isJsonField: isJsonField,
    hasConverter: hasConverter,
    dartType: dartType,
  );
}

void main() {
  group('ColumnSchemaSnapshot.toJson / fromJson', () {
    test('round-trips required fields', () {
      final col = _col();
      final restored = ColumnSchemaSnapshot.fromJson(col.toJson());

      expect(restored.dartName, col.dartName);
      expect(restored.name, col.name);
      expect(restored.type, col.type);
      expect(restored.nullable, col.nullable);
      expect(restored.primaryKey, col.primaryKey);
      expect(restored.autoIncrement, col.autoIncrement);
      expect(restored.unique, col.unique);
      expect(restored.isJsonField, col.isJsonField);
      expect(restored.hasConverter, col.hasConverter);
      expect(restored.dartType, col.dartType);
    });

    test('round-trips optional defaultValue', () {
      final col = _col(defaultValue: "'active'");
      final restored = ColumnSchemaSnapshot.fromJson(col.toJson());
      expect(restored.defaultValue, "'active'");
    });

    test('omits defaultValue from JSON when null', () {
      final col = _col(defaultValue: null);
      final json = col.toJson();
      expect(json.containsKey('defaultValue'), isFalse);
    });

    test('round-trips foreignKey', () {
      final col = _col(foreignKey: 'categories.id');
      final restored = ColumnSchemaSnapshot.fromJson(col.toJson());
      expect(restored.foreignKey, 'categories.id');
    });

    test('omits foreignKey from JSON when null', () {
      final col = _col(foreignKey: null);
      expect(col.toJson().containsKey('foreignKey'), isFalse);
    });

    test('round-trips isJsonField=true', () {
      final col = _col(isJsonField: true);
      final restored = ColumnSchemaSnapshot.fromJson(col.toJson());
      expect(restored.isJsonField, isTrue);
    });

    test('round-trips hasConverter=true', () {
      final col = _col(hasConverter: true);
      final restored = ColumnSchemaSnapshot.fromJson(col.toJson());
      expect(restored.hasConverter, isTrue);
    });
  });

  group('IndexSchemaSnapshot.toJson / fromJson', () {
    test('round-trips single-column non-unique index', () {
      final idx = IndexSchemaSnapshot(columns: ['email'], unique: false);
      final restored = IndexSchemaSnapshot.fromJson(idx.toJson());

      expect(restored.columns, ['email']);
      expect(restored.unique, isFalse);
    });

    test('round-trips multi-column unique index', () {
      final idx =
          IndexSchemaSnapshot(columns: ['first_name', 'last_name'], unique: true);
      final restored = IndexSchemaSnapshot.fromJson(idx.toJson());

      expect(restored.columns, ['first_name', 'last_name']);
      expect(restored.unique, isTrue);
    });
  });

  group('TableSchemaSnapshot.fromTableInfo', () {
    test('stores className, tableName, version', () {
      final snapshot = TableSchemaSnapshot.fromTableInfo(
        'User',
        'users',
        [],
        [],
        1,
      );

      expect(snapshot.className, 'User');
      expect(snapshot.tableName, 'users');
      expect(snapshot.version, 1);
    });

    test('generates non-empty hash', () {
      final snapshot =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      expect(snapshot.hash, isNotEmpty);
    });

    test('same data produces same hash', () {
      final a =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      final b =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      expect(a.hash, b.hash);
    });

    test('different tableName produces different hash', () {
      final a =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      final b =
          TableSchemaSnapshot.fromTableInfo('User', 'app_users', [], [], 1);
      expect(a.hash, isNot(b.hash));
    });

    test('different columns produce different hash', () {
      final col1 = _col(name: 'id');
      final col2 = _col(name: 'email', type: 'TEXT', primaryKey: false,
          autoIncrement: false, dartType: 'String');
      final a =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [col1], [], 1);
      final b =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [col2], [], 1);
      expect(a.hash, isNot(b.hash));
    });
  });

  group('TableSchemaSnapshot.toJson / fromJson', () {
    test('round-trips all fields', () {
      final snapshot = TableSchemaSnapshot.fromTableInfo(
        'Post',
        'posts',
        [_col(name: 'id'), _col(dartName: 'title', name: 'title', type: 'TEXT',
            primaryKey: false, autoIncrement: false, dartType: 'String')],
        [IndexSchemaSnapshot(columns: ['title'], unique: false)],
        2,
      );

      final restored = TableSchemaSnapshot.fromJson(snapshot.toJson());

      expect(restored.className, snapshot.className);
      expect(restored.tableName, snapshot.tableName);
      expect(restored.version, snapshot.version);
      expect(restored.hash, snapshot.hash);
      expect(restored.columns.length, snapshot.columns.length);
      expect(restored.indexes.length, snapshot.indexes.length);
    });

    test('columns round-trip correctly', () {
      final col = _col(name: 'id', primaryKey: true, autoIncrement: true);
      final snapshot =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [col], [], 1);

      final restored = TableSchemaSnapshot.fromJson(snapshot.toJson());
      expect(restored.columns.first.name, 'id');
      expect(restored.columns.first.primaryKey, isTrue);
    });

    test('empty columns and indexes serialize correctly', () {
      final snapshot =
          TableSchemaSnapshot.fromTableInfo('Tag', 'tags', [], [], 1);
      final restored = TableSchemaSnapshot.fromJson(snapshot.toJson());

      expect(restored.columns, isEmpty);
      expect(restored.indexes, isEmpty);
    });
  });

  group('TableSchemaSnapshot equality', () {
    test('two snapshots with same data are equal', () {
      final a =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      final b =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      expect(a, equals(b));
    });

    test('snapshots with different tableName are not equal', () {
      final a =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      final b =
          TableSchemaSnapshot.fromTableInfo('User', 'app_users', [], [], 1);
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal snapshots', () {
      final a =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      final b =
          TableSchemaSnapshot.fromTableInfo('User', 'users', [], [], 1);
      expect(a.hashCode, b.hashCode);
    });
  });
}
