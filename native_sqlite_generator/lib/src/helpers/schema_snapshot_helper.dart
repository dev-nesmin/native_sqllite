import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/index_info.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Helper class to convert TableInfo to schema snapshots
class SchemaSnapshotHelper {
  /// Converts TableInfo to TableSchemaSnapshot
  static TableSchemaSnapshot createSnapshot(
    TableInfo tableInfo,
    int version,
  ) {
    final columns = tableInfo.columns.map(_columnToSnapshot).toList();
    final indexes = tableInfo.indexes.map(_indexToSnapshot).toList();

    return TableSchemaSnapshot.fromTableInfo(
      tableInfo.dartName,
      tableInfo.sqlName,
      columns,
      indexes,
      version,
    );
  }

  /// Converts ColumnInfo to ColumnSchemaSnapshot
  static ColumnSchemaSnapshot _columnToSnapshot(ColumnInfo column) {
    return ColumnSchemaSnapshot(
      dartName: column.dartName,
      name: column.sqlName,
      type: column.sqlType.sqlName, // Use sqlName from SqlType enum
      nullable: column.isNullable,
      primaryKey: column.isPrimaryKey,
      autoIncrement: column.isAutoIncrement,
      unique: column.isUnique,
      defaultValue: column.defaultValue,
      foreignKey: column.foreignKeyTable != null
          ? '${column.foreignKeyTable}.${column.foreignKeyColumn}'
          : null,
      isJsonField: column.isJsonField,
      hasConverter: column.hasConverter,
      dartType: column.dartType.getDisplayString(),
    );
  }

  /// Converts IndexInfo to IndexSchemaSnapshot
  static IndexSchemaSnapshot _indexToSnapshot(IndexInfo index) {
    return IndexSchemaSnapshot(
      columns: index.columns,
      unique: index.unique,
    );
  }
}
