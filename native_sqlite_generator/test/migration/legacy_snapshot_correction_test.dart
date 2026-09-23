import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/migration/legacy_snapshot_correction.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:test/test.dart';

ColumnSchemaSnapshot _col(String dartName, String name, {bool pk = false}) =>
    ColumnSchemaSnapshot(
      dartName: dartName,
      name: name,
      type: pk ? 'INTEGER' : 'TEXT',
      nullable: pk,
      primaryKey: pk,
      autoIncrement: pk,
      unique: false,
      isJsonField: false,
      hasConverter: false,
      dartType: pk ? 'int?' : 'String',
    );

TableSchemaSnapshot _table(
  String tableName,
  List<ColumnSchemaSnapshot> columns, {
  List<IndexSchemaSnapshot> indexes = const [],
}) => TableSchemaSnapshot.fromTableInfo(
  'Order',
  tableName,
  columns,
  indexes,
  1,
);

String _hash(Map<String, dynamic> json) {
  final s = TableSchemaSnapshot.fromJson(json);
  return TableSchemaSnapshot.computeHash(s.tableName, s.columns, s.indexes);
}

void main() {
  final correction = LegacySnapshotCorrection(const GeneratorOptions());

  final current = _table(
    'orders',
    [_col('id', 'id', pk: true), _col('userId', 'user_id')],
    indexes: [
      const IndexSchemaSnapshot(
        columns: ['user_id'],
        unique: false,
        name: 'idx_orders_user_id',
      ),
    ],
  );

  test('maps legacy Dart-named columns and indexes to the real names', () {
    final legacy = _table(
      'orders',
      [_col('id', 'id', pk: true), _col('userId', 'userId')],
      indexes: [const IndexSchemaSnapshot(columns: ['userId'], unique: false)],
    ).toJson();

    final result = correction.correct(legacy, current);

    expect(result.changed, isTrue);
    expect(
      (result.schema['columns'] as List).map((c) => c['name']),
      ['id', 'user_id'],
    );
    expect((result.schema['indexes'] as List).single['columns'], ['user_id']);
    // Corrected snapshot equals the current schema: no migration is generated.
    expect(_hash(result.schema), current.hash);
  });

  test('keeps genuine renames so they are still detected as changes', () {
    final renamed = _table('orders', [
      _col('id', 'id', pk: true),
      _col('userId', 'owner'), // e.g. @DbColumn(name: 'owner')
    ]);
    final legacy = _table('orders', [
      _col('id', 'id', pk: true),
      _col('userId', 'userId'),
    ]).toJson();

    final result = correction.correct(legacy, renamed);

    expect(result.changed, isFalse);
    expect(_hash(result.schema), isNot(renamed.hash));
  });

  test('leaves correct snapshots untouched', () {
    final result = correction.correct(current.toJson(), current);
    expect(result.changed, isFalse);
    expect(_hash(result.schema), current.hash);
  });

  test('finds a table recorded under its class name', () {
    final previous = {
      'Order': _table('Order', [_col('id', 'id', pk: true)]).toJson(),
    };
    // Unnamed @DbTable: the real table is the snake_case class name.
    final conventional = _table('order', [_col('id', 'id', pk: true)]);
    expect(correction.findLegacyTableKey(previous, conventional), 'Order');
    // Explicit @DbTable(name: 'orders') was never affected.
    expect(correction.findLegacyTableKey(previous, current), isNull);
    expect(correction.findLegacyTableKey({}, conventional), isNull);
  });

  test('hash ignores descriptive metadata but tracks foreign keys', () {
    final withName = _table('orders', current.columns);
    expect(
      TableSchemaSnapshot.computeHash('orders', current.columns, const [
        IndexSchemaSnapshot(columns: ['user_id'], unique: false),
      ]),
      current.hash,
    );
    final withFk = ColumnSchemaSnapshot(
      dartName: 'userId',
      name: 'user_id',
      type: 'TEXT',
      nullable: false,
      primaryKey: false,
      autoIncrement: false,
      unique: false,
      isJsonField: false,
      hasConverter: false,
      dartType: 'String',
      foreignKey: 'users.id',
    );
    expect(
      TableSchemaSnapshot.computeHash('orders', [
        current.columns.first,
        withFk,
      ], const []),
      isNot(withName.hash),
    );
  });
}
