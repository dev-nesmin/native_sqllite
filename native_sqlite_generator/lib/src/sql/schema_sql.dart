import 'package:native_sqlite_generator/src/helpers/naming_conventions.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// Builds schema SQL from a [TableSchemaSnapshot].
///
/// The statements are equivalent to the Dart `XxxSchema.createTableSql` and
/// `XxxSchema.indexSql` (see `SchemaGenerator` / `IndexInfo`). Native code
/// and migrations use this, so every path produces the same schema.
class SchemaSql {
  SchemaSql._();

  /// `CREATE TABLE` for [table], optionally under another [name] (used when
  /// rebuilding a table) or as `CREATE TABLE IF NOT EXISTS`.
  static String createTable(
    TableSchemaSnapshot table, {
    String? name,
    bool ifNotExists = false,
  }) {
    final definitions = <String>[
      for (final column in table.columns) _columnDefinition(column),
      for (final column in table.columns)
        if (column.foreignKey != null) _foreignKey(column),
    ];
    return 'CREATE TABLE ${ifNotExists ? 'IF NOT EXISTS ' : ''}'
        '${name ?? table.tableName} (${definitions.join(', ')})';
  }

  static List<String> createIndexes(
    TableSchemaSnapshot table, {
    bool ifNotExists = false,
  }) {
    return [
      for (final index in table.indexes)
        createIndex(table.tableName, index, ifNotExists: ifNotExists),
    ];
  }

  static String createIndex(
    String tableName,
    IndexSchemaSnapshot index, {
    bool ifNotExists = false,
  }) {
    return 'CREATE ${index.unique ? 'UNIQUE ' : ''}INDEX '
        '${ifNotExists ? 'IF NOT EXISTS ' : ''}'
        '${indexName(tableName, index)} '
        'ON $tableName (${index.columns.join(', ')})';
  }

  /// The index's name; snapshots written before names were recorded fall
  /// back to the analyzer's default naming.
  static String indexName(String tableName, IndexSchemaSnapshot index) =>
      index.name ?? _defaultIndexName(tableName, index.columns);

  static String _columnDefinition(ColumnSchemaSnapshot column) {
    final parts = <String>[column.name, column.type];
    if (column.primaryKey) {
      parts.add('PRIMARY KEY');
      if (column.autoIncrement) parts.add('AUTOINCREMENT');
    }
    if (!column.nullable && !column.primaryKey) parts.add('NOT NULL');
    if (column.unique && !column.primaryKey) parts.add('UNIQUE');
    if (column.defaultValue != null) parts.add('DEFAULT ${column.defaultValue}');
    return parts.join(' ');
  }

  static String _foreignKey(ColumnSchemaSnapshot column) {
    final reference = column.foreignKey!;
    final dot = reference.indexOf('.');
    final parts = <String>[
      'FOREIGN KEY (${column.name})',
      'REFERENCES ${reference.substring(0, dot)}(${reference.substring(dot + 1)})',
    ];
    if (column.foreignKeyOnDelete != null) {
      parts.add('ON DELETE ${column.foreignKeyOnDelete}');
    }
    if (column.foreignKeyOnUpdate != null) {
      parts.add('ON UPDATE ${column.foreignKeyOnUpdate}');
    }
    return parts.join(' ');
  }

  /// Same default as `TableAnalyzer._analyzeIndexes`, for snapshots written
  /// before index names were recorded.
  static String _defaultIndexName(String tableName, List<String> columns) =>
      'idx_${NamingConventions.toSnakeCase(tableName)}_${columns.join('_')}';
}
