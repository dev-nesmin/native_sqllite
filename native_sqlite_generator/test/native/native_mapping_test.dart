import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/native/native_column.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';
import 'package:native_sqlite_generator/src/native_kotlin_generator.dart';
import 'package:native_sqlite_generator/src/native_swift_generator.dart';
import 'package:test/test.dart';

ColumnSchemaSnapshot _col(
  String name,
  String dartType,
  String type, {
  bool nullable = false,
  bool primaryKey = false,
  bool unique = false,
  String? defaultValue,
  String? foreignKey,
  bool hasConverter = false,
  bool isJsonField = false,
  String? enumType,
  List<String>? enumValues,
}) => ColumnSchemaSnapshot(
  dartName: name,
  name: name,
  type: type,
  nullable: nullable,
  primaryKey: primaryKey,
  autoIncrement: primaryKey,
  unique: unique,
  defaultValue: defaultValue,
  foreignKey: foreignKey,
  foreignKeyOnDelete: foreignKey == null ? null : 'CASCADE',
  isJsonField: isJsonField,
  hasConverter: hasConverter,
  dartType: dartType,
  enumType: enumType,
  enumValues: enumValues,
);

void main() {
  final table = TableSchemaSnapshot.fromTableInfo(
    'Item',
    'items',
    [
      _col('id', 'int?', 'INTEGER', nullable: true, primaryKey: true),
      _col('code', 'String', 'TEXT', unique: true),
      _col('status', 'String', 'TEXT', defaultValue: "'new'"),
      _col('ownerId', 'int', 'INTEGER', foreignKey: 'users.id'),
      _col('createdAt', 'DateTime', 'INTEGER'),
      _col('ttl', 'Duration?', 'INTEGER', nullable: true),
      _col(
        'state',
        'State',
        'INTEGER',
        enumType: 'ordinal',
        enumValues: ['open', 'closed'],
      ),
      _col('color', 'Color', 'INTEGER', hasConverter: true),
      _col('meta', 'Map<String, dynamic>?', 'TEXT', nullable: true, isJsonField: true),
    ],
    const [
      IndexSchemaSnapshot(columns: ['code', 'status'], unique: true, name: 'idx_code'),
      IndexSchemaSnapshot(columns: ['ownerId'], unique: false),
    ],
    1,
  );

  group('SchemaSql', () {
    test('matches the Dart CREATE TABLE format', () {
      expect(
        SchemaSql.createTable(table),
        'CREATE TABLE items (id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'code TEXT NOT NULL UNIQUE, status TEXT NOT NULL DEFAULT \'new\', '
        'ownerId INTEGER NOT NULL, createdAt INTEGER NOT NULL, ttl INTEGER, '
        'state INTEGER NOT NULL, color INTEGER NOT NULL, meta TEXT, '
        'FOREIGN KEY (ownerId) REFERENCES users(id) ON DELETE CASCADE)',
      );
    });

    test('creates named and default-named indexes', () {
      expect(SchemaSql.createIndexes(table), [
        'CREATE UNIQUE INDEX idx_code ON items (code, status)',
        'CREATE INDEX idx_items_ownerId ON items (ownerId)',
      ]);
    });
  });

  group('NativeColumn', () {
    NativeColumn of(String name) =>
        NativeColumn.of(table.columns.firstWhere((c) => c.dartName == name));

    test('maps known Dart types to typed kinds', () {
      expect(of('createdAt').kind, NativeKind.dateTime);
      expect(of('ttl').kind, NativeKind.duration);
      expect(of('state').kind, NativeKind.enumeration);
      expect(of('ownerId').kind, NativeKind.integer);
    });

    test('exposes converter and JSON columns as stored values', () {
      expect(of('color').kind, NativeKind.integer);
      expect(of('color').rawStorage, isTrue);
      expect(of('meta').kind, NativeKind.text);
      expect(of('meta').rawStorage, isTrue);
    });

    test('rejects conflicting enum definitions', () {
      final other = TableSchemaSnapshot.fromTableInfo('Other', 'others', [
        _col(
          'state',
          'State',
          'INTEGER',
          enumType: 'ordinal',
          enumValues: ['a', 'b'],
        ),
      ], const [], 1);
      expect(() => NativeEnum.collect([table, other]), throwsStateError);
    });
  });

  test('Kotlin uses java.time types and generated enums', () {
    final code = NativeKotlinGenerator(
      packageName: 'com.example',
      databaseName: 'db',
      includeExamples: false,
    ).generateHelper(table);

    expect(code, contains('import java.time.Instant'));
    expect(code, contains('val createdAt: Instant'));
    expect(code, contains('val ttl: Duration?'));
    expect(code, contains('val state: State'));
    expect(code, contains('/** Raw value stored by the Dart TypeConverter'));
    expect(code, contains('entity.createdAt.toEpochMilli()'));
    expect(code, contains('State.entries[('));
    expect(code, isNot(contains('DateTime')));
    expect(code, isNot(contains('Json.')));
  });

  test('Kotlin CREATE_TABLE_SQL is a compile-time constant', () {
    final code = NativeKotlinGenerator(
      packageName: 'com.example',
      databaseName: 'db',
      includeExamples: false,
    ).generateSchema(table);
    expect(code, contains('const val CREATE_TABLE_SQL = "CREATE TABLE items ('));
    expect(code, isNot(contains('trimIndent')));
  });

  test('Swift uses Foundation types and throwing row decoding', () {
    final code = NativeSwiftGenerator(
      databaseName: 'db',
      includeExamples: false,
    ).generateHelper(table);

    expect(code, contains('import native_sqlite_ios'));
    expect(code, contains('public let createdAt: Date'));
    expect(code, contains('public let ttl: TimeInterval?'));
    expect(code, contains('public let state: State'));
    expect(code, contains('GeneratedValue.milliseconds(entity.createdAt)'));
    expect(code, contains('throws -> Item {'));
    expect(code, isNot(contains('as!')));
  });
}
