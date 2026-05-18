import 'package:native_sqlite_generator/src/migration/schema_comparator.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:test/test.dart';

TableSchemaSnapshot _makeSnapshot({
  String className = 'User',
  String tableName = 'users',
  List<ColumnSchemaSnapshot> columns = const [],
  List<IndexSchemaSnapshot> indexes = const [],
  int version = 1,
}) {
  return TableSchemaSnapshot.fromTableInfo(
    className,
    tableName,
    columns,
    indexes,
    version,
  );
}

ColumnSchemaSnapshot _col({
  String dartName = 'id',
  String name = 'id',
  String type = 'INTEGER',
  bool nullable = false,
  bool primaryKey = false,
  bool autoIncrement = false,
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
  group('SchemaComparator.compareSchemas', () {
    test('returns createTable when oldSchema is null', () {
      final newSchema = _makeSnapshot(tableName: 'users');

      final changes = SchemaComparator.compareSchemas(null, newSchema);

      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.createTable);
      expect(changes.first.tableName, 'users');
    });

    test('returns no changes for identical schemas', () {
      final col = _col(dartName: 'id', name: 'id');
      final schema = _makeSnapshot(columns: [col]);

      final changes = SchemaComparator.compareSchemas(schema, schema);

      expect(changes, isEmpty);
    });

    test('detects table rename when className matches but tableName differs',
        () {
      final old = _makeSnapshot(className: 'User', tableName: 'users');
      final next = _makeSnapshot(className: 'User', tableName: 'app_users');

      final changes = SchemaComparator.compareSchemas(old, next);

      final rename = changes
          .where((c) => c.type == SchemaChangeType.renameTable)
          .toList();
      expect(rename, hasLength(1));
      expect(rename.first.oldTableName, 'users');
      expect(rename.first.newTableName, 'app_users');
    });

    test('detects added column', () {
      final idCol = _col(dartName: 'id', name: 'id');
      final nameCol = _col(
          dartName: 'name', name: 'name', type: 'TEXT', dartType: 'String');
      final old = _makeSnapshot(columns: [idCol]);
      final next = _makeSnapshot(columns: [idCol, nameCol]);

      final changes = SchemaComparator.compareSchemas(old, next);

      final added = changes
          .where((c) => c.type == SchemaChangeType.addColumn)
          .toList();
      expect(added, hasLength(1));
      expect(added.first.column?.name, 'name');
    });

    test('detects dropped column', () {
      final idCol = _col(dartName: 'id', name: 'id');
      final nameCol = _col(
          dartName: 'name', name: 'name', type: 'TEXT', dartType: 'String');
      final old = _makeSnapshot(columns: [idCol, nameCol]);
      final next = _makeSnapshot(columns: [idCol]);

      final changes = SchemaComparator.compareSchemas(old, next);

      final dropped = changes
          .where((c) => c.type == SchemaChangeType.dropColumn)
          .toList();
      expect(dropped, hasLength(1));
      expect(dropped.first.column?.name, 'name');
    });

    test('detects modified column (type change)', () {
      final old = _makeSnapshot(
        columns: [_col(dartName: 'score', name: 'score', type: 'INTEGER')],
      );
      final next = _makeSnapshot(
        columns: [_col(dartName: 'score', name: 'score', type: 'REAL')],
      );

      final changes = SchemaComparator.compareSchemas(old, next);

      final modified = changes
          .where((c) => c.type == SchemaChangeType.modifyColumn)
          .toList();
      expect(modified, hasLength(1));
      expect(modified.first.newColumn?.type, 'REAL');
    });

    test('detects modified column (nullable change)', () {
      final old = _makeSnapshot(
        columns: [
          _col(dartName: 'bio', name: 'bio', type: 'TEXT', nullable: false),
        ],
      );
      final next = _makeSnapshot(
        columns: [
          _col(dartName: 'bio', name: 'bio', type: 'TEXT', nullable: true),
        ],
      );

      final changes = SchemaComparator.compareSchemas(old, next);

      expect(
        changes.any((c) => c.type == SchemaChangeType.modifyColumn),
        isTrue,
      );
    });

    test('detects renamed column (same dartName, different SQL name)', () {
      final old = _makeSnapshot(
        columns: [
          _col(dartName: 'userName', name: 'user_name', type: 'TEXT'),
        ],
      );
      final next = _makeSnapshot(
        columns: [
          _col(dartName: 'userName', name: 'username', type: 'TEXT'),
        ],
      );

      final changes = SchemaComparator.compareSchemas(old, next);

      final renamed = changes
          .where((c) => c.type == SchemaChangeType.renameColumn)
          .toList();
      expect(renamed, hasLength(1));
      expect(renamed.first.oldColumn?.name, 'user_name');
      expect(renamed.first.newColumn?.name, 'username');
    });

    test('detects added index', () {
      final old = _makeSnapshot(indexes: []);
      final next = _makeSnapshot(
        indexes: [IndexSchemaSnapshot(columns: ['email'], unique: true)],
      );

      final changes = SchemaComparator.compareSchemas(old, next);

      final added =
          changes.where((c) => c.type == SchemaChangeType.addIndex).toList();
      expect(added, hasLength(1));
      expect(added.first.index?.columns, ['email']);
    });

    test('detects dropped index', () {
      final old = _makeSnapshot(
        indexes: [IndexSchemaSnapshot(columns: ['email'], unique: false)],
      );
      final next = _makeSnapshot(indexes: []);

      final changes = SchemaComparator.compareSchemas(old, next);

      final dropped =
          changes.where((c) => c.type == SchemaChangeType.dropIndex).toList();
      expect(dropped, hasLength(1));
    });

    test('does not detect change when index columns and unique are identical',
        () {
      final idx = IndexSchemaSnapshot(columns: ['email'], unique: true);
      final schema = _makeSnapshot(indexes: [idx]);

      final changes = SchemaComparator.compareSchemas(schema, schema);

      expect(changes.where((c) => c.type == SchemaChangeType.addIndex), isEmpty);
      expect(changes.where((c) => c.type == SchemaChangeType.dropIndex),
          isEmpty);
    });
  });

  group('SchemaComparator.requiresTableRecreation', () {
    test('returns true when dropColumn change exists', () {
      final changes = [
        SchemaChange(
          type: SchemaChangeType.dropColumn,
          tableName: 'users',
        ),
      ];
      expect(SchemaComparator.requiresTableRecreation(changes), isTrue);
    });

    test('returns true when renameColumn change exists', () {
      final changes = [
        SchemaChange(
          type: SchemaChangeType.renameColumn,
          tableName: 'users',
        ),
      ];
      expect(SchemaComparator.requiresTableRecreation(changes), isTrue);
    });

    test('returns true when modifyColumn change exists', () {
      final changes = [
        SchemaChange(
          type: SchemaChangeType.modifyColumn,
          tableName: 'users',
        ),
      ];
      expect(SchemaComparator.requiresTableRecreation(changes), isTrue);
    });

    test('returns false for addColumn only', () {
      final changes = [
        SchemaChange(
          type: SchemaChangeType.addColumn,
          tableName: 'users',
        ),
      ];
      expect(SchemaComparator.requiresTableRecreation(changes), isFalse);
    });

    test('returns false for addIndex only', () {
      final changes = [
        SchemaChange(
          type: SchemaChangeType.addIndex,
          tableName: 'users',
        ),
      ];
      expect(SchemaComparator.requiresTableRecreation(changes), isFalse);
    });

    test('returns false for empty changes', () {
      expect(SchemaComparator.requiresTableRecreation([]), isFalse);
    });
  });

  group('SchemaChange.toString', () {
    test('createTable format', () {
      final change = SchemaChange(
          type: SchemaChangeType.createTable, tableName: 'users');
      expect(change.toString(), 'CREATE TABLE users');
    });

    test('dropTable format', () {
      final change =
          SchemaChange(type: SchemaChangeType.dropTable, tableName: 'users');
      expect(change.toString(), 'DROP TABLE users');
    });

    test('renameTable format', () {
      final change = SchemaChange(
        type: SchemaChangeType.renameTable,
        oldTableName: 'users',
        newTableName: 'app_users',
      );
      expect(change.toString(), 'RENAME TABLE users TO app_users');
    });

    test('addColumn format', () {
      final col = _col(name: 'bio', type: 'TEXT');
      final change = SchemaChange(
        type: SchemaChangeType.addColumn,
        tableName: 'users',
        column: col,
      );
      expect(change.toString(), contains('ADD COLUMN'));
      expect(change.toString(), contains('bio'));
    });

    test('addIndex format', () {
      final idx = IndexSchemaSnapshot(columns: ['email', 'name'], unique: true);
      final change = SchemaChange(
        type: SchemaChangeType.addIndex,
        tableName: 'users',
        index: idx,
      );
      expect(change.toString(), contains('CREATE INDEX'));
      expect(change.toString(), contains('email'));
    });
  });
}
