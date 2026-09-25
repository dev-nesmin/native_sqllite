import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/constructor_parameter_info.dart';
import 'package:native_sqlite_generator/src/models/index_info.dart';

/// Information about a table to be generated.
class TableInfo {
  TableInfo({
    required this.dartName,
    required this.sqlName,
    required this.columns,
    required this.constructorParameters,
    required this.indexes,
    required this.databaseName,
  });

  /// The Dart class name.
  final String dartName;

  /// The SQL table name.
  final String sqlName;

  /// The columns in this table.
  final List<ColumnInfo> columns;

  /// Columns in the order and style expected by the unnamed constructor.
  final List<ConstructorParameterInfo> constructorParameters;

  /// The indexes on this table.
  final List<IndexInfo> indexes;

  /// The default database name for this table.
  /// Comes from @DbTable annotation, build.yaml config, or defaults to 'default_app'.
  final String databaseName;

  /// Gets the primary key column, if any.
  ColumnInfo? get primaryKey {
    try {
      return columns.firstWhere((c) => c.isPrimaryKey);
    } catch (_) {
      return null;
    }
  }

  /// Gets all columns except the primary key.
  List<ColumnInfo> get nonPrimaryColumns {
    return columns.where((c) => !c.isPrimaryKey).toList();
  }

  /// Gets the schema class name.
  String get schemaClassName => NamingUtils.getSchemaClassName(dartName);

  /// Gets the repository class name.
  String get repositoryClassName =>
      NamingUtils.getRepositoryClassName(dartName);

  /// Name of the single row mapper shared by the repository and query builder.
  String get rowMapperName => '_${dartName}FromMap';

  /// Whether this table has a primary key.
  bool get hasPrimaryKey => primaryKey != null;

  /// Whether this table has indexes.
  bool get hasIndexes => indexes.isNotEmpty;

  /// Whether this table has JSON fields.
  bool get hasJsonFields => columns.any((c) => c.isJsonField);

  @override
  String toString() {
    return 'TableInfo($dartName -> $sqlName, ${columns.length} columns)';
  }
}
