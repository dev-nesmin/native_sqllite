import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/error_handler.dart';
import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/helpers/naming_conventions.dart';
import 'package:native_sqlite_generator/src/helpers/type_utils.dart';
import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/index_info.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';
import 'package:source_gen/source_gen.dart';

/// Analyzes a class annotated with @DbTable and extracts table information.
class TableAnalyzer {
  final GeneratorOptions? options;

  TableAnalyzer([this.options]);

  /// Type checkers for annotations
  static final _primaryKeyChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#PrimaryKey',
  );
  static final _columnChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#DbColumn',
  );
  static final _ignoreChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#Ignore',
  );
  static final _foreignKeyChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#ForeignKey',
  );
  static final _indexChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#Index',
  );
  static final _enumFieldChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#EnumField',
  );
  static final _useConverterChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#UseConverter',
  );
  static final _jsonFieldChecker = TypeChecker.fromUrl(
    'package:native_sqlite/native_sqlite.dart#JsonField',
  );

  /// Analyzes a class element and returns table information.
  TableInfo analyze(ClassElement element, ConstantReader annotation) {
    // Validate class
    _validateClass(element);

    // Get table name
    final className = element.name!;
    String tableName = annotation.peek('name')?.stringValue ?? className;

    // Apply naming convention if not explicitly provided in annotation
    if (annotation.peek('name')?.stringValue == null &&
        options != null &&
        options!.tableNameCase != 'none') {
      tableName = NamingConventions.format(className, options!.tableNameCase);
    }

    // Analyze columns
    final columns = _analyzeColumns(element);

    // Analyze indexes (both from Table annotation and @Index annotations)
    // Pass columns so we can map Dart names to SQL names
    final indexes = _analyzeIndexes(element, tableName, annotation, columns);

    // Get database name with fallback logic:
    // 1. First check @DbTable annotation
    // 2. Then check build.yaml config
    // 3. Finally fall back to 'default_app'
    String? databaseName = annotation.peek('database')?.stringValue;
    if (databaseName == null && options != null) {
      databaseName = options!.defaultDatabase ?? 'default_app';
    } else if (databaseName == null) {
      databaseName = 'default_app';
    }

    return TableInfo(
      dartName: className,
      sqlName: tableName,
      columns: columns,
      indexes: indexes,
      databaseName: databaseName,
    );
  }

  /// Validates that the class is suitable for table generation.
  void _validateClass(ClassElement element) {
    GeneratorError.validate(
      !element.isAbstract,
      'Table class must not be abstract',
      element,
    );
  }

  /// Analyzes all fields in the class and returns column information.
  List<ColumnInfo> _analyzeColumns(ClassElement element) {
    final columns = <ColumnInfo>[];

    for (final field in element.fields) {
      // Skip static fields and ignored fields
      if (field.isStatic || _isIgnored(field)) {
        continue;
      }

      final columnInfo = _analyzeColumn(field);
      columns.add(columnInfo);
    }

    // Validate that we have at least one column
    GeneratorError.validate(
      columns.isNotEmpty,
      'Table must have at least one column',
      element,
    );

    return columns;
  }

  /// Analyzes a single field and returns column information.
  ColumnInfo _analyzeColumn(FieldElement field) {
    final fieldName = field.name!;
    final dartType = field.type;

    // Get enum type first (if this is an enum field)
    final enumType = _getEnumType(field);

    // Get column name
    final columnName = _getColumnName(field);

    // Get SQL type (passing enum type for enum fields)
    final sqlType = _getSqlType(field, enumType);

    // Check if primary key
    final isPrimaryKey = _isPrimaryKey(field);

    // Check if auto increment
    final isAutoIncrement = isPrimaryKey && _isAutoIncrement(field);

    // Check nullability
    final isNullable = _isColumnNullable(field);

    // Check if unique
    final isUnique = _isUnique(field);

    // Get default value
    final defaultValue = _getDefaultValue(field);

    // Get foreign key info
    final foreignKeyInfo = _getForeignKeyInfo(field);

    // Get converter expression (if this field uses a custom type converter)
    final converterExpression = _getConverterExpression(field);

    // Check if this is a JSON field
    final isJsonField = _isJsonField(field);

    return ColumnInfo(
      dartName: fieldName,
      sqlName: columnName,
      dartType: dartType,
      sqlType: sqlType,
      isPrimaryKey: isPrimaryKey,
      isAutoIncrement: isAutoIncrement,
      isNullable: isNullable,
      isUnique: isUnique,
      defaultValue: defaultValue,
      foreignKeyTable: foreignKeyInfo?['table'] as String?,
      foreignKeyColumn: foreignKeyInfo?['column'] as String?,
      foreignKeyOnDelete: foreignKeyInfo?['onDelete'] as String?,
      foreignKeyOnUpdate: foreignKeyInfo?['onUpdate'] as String?,
      enumType: enumType,
      converterExpression: converterExpression,
      isJsonField: isJsonField,
    );
  }

  /// Checks if a field is ignored.
  bool _isIgnored(FieldElement field) {
    return _ignoreChecker.hasAnnotationOf(field);
  }

  /// Gets the column name for a field.
  String _getColumnName(FieldElement field) {
    final annotation = _columnChecker.firstAnnotationOf(field);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final name = reader.peek('name')?.stringValue;
      if (name != null) return name;
    }

    // Apply naming convention from options
    final dartName = field.name!;
    if (options != null && options!.columnNameCase != 'none') {
      return NamingConventions.format(dartName, options!.columnNameCase);
    }

    return dartName;
  }

  /// Gets the SQL type for a field.
  SqlType _getSqlType(FieldElement field, String enumType) {
    // Check for explicit type annotation
    final annotation = _columnChecker.firstAnnotationOf(field);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final explicitType = reader.peek('type')?.stringValue;
      if (explicitType != null) {
        return _parseSqlType(explicitType);
      }
    }

    // Infer from Dart type, passing enum type for enum fields
    return SqlType.fromDartType(field.type, enumType: enumType);
  }

  /// Parses an SQL type string.
  SqlType _parseSqlType(String type) {
    final upperType = type.toUpperCase();
    switch (upperType) {
      case 'INTEGER':
        return SqlType.integer;
      case 'REAL':
        return SqlType.real;
      case 'TEXT':
        return SqlType.text;
      case 'BLOB':
        return SqlType.blob;
      case 'NUMERIC':
        return SqlType.numeric;
      default:
        return SqlType.text;
    }
  }

  /// Checks if a field is a primary key.
  bool _isPrimaryKey(FieldElement field) {
    return _primaryKeyChecker.hasAnnotationOf(field);
  }

  /// Checks if a field is auto-increment.
  bool _isAutoIncrement(FieldElement field) {
    final annotation = _primaryKeyChecker.firstAnnotationOf(field);
    if (annotation == null) return false;

    final reader = ConstantReader(annotation);
    return reader.peek('autoIncrement')?.boolValue ?? false;
  }

  /// Checks if a column is nullable.
  bool _isColumnNullable(FieldElement field) {
    // Check if Column annotation explicitly sets nullable
    final annotation = _columnChecker.firstAnnotationOf(field);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final nullable = reader.peek('nullable')?.boolValue;
      if (nullable != null) {
        return nullable;
      }
    }

    // Fall back to Dart type nullability
    return field.type.nullabilitySuffix == NullabilitySuffix.question;
  }

  /// Checks if a field has a unique constraint.
  bool _isUnique(FieldElement field) {
    // Check for unique in @DbColumn annotation
    final annotation = _columnChecker.firstAnnotationOf(field);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      return reader.peek('unique')?.boolValue ?? false;
    }

    return false;
  }

  /// Gets the default value for a column.
  String? _getDefaultValue(FieldElement field) {
    final annotation = _columnChecker.firstAnnotationOf(field);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    return reader.peek('defaultValue')?.stringValue;
  }

  /// Gets foreign key information for a field.
  Map<String, dynamic>? _getForeignKeyInfo(FieldElement field) {
    final annotation = _foreignKeyChecker.firstAnnotationOf(field);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);

    return {
      'table': reader.read('table').stringValue,
      'column': reader.read('column').stringValue,
      'onDelete': reader.peek('onDelete')?.stringValue,
      'onUpdate': reader.peek('onUpdate')?.stringValue,
    };
  }

  /// Gets enum storage type for a field.
  String _getEnumType(FieldElement field) {
    final annotation = _enumFieldChecker.firstAnnotationOf(field);
    if (annotation == null) return 'ordinal'; // Default to ordinal

    final reader = ConstantReader(annotation);
    final enumTypeValue = reader.peek('type');

    if (enumTypeValue == null) return 'ordinal';

    // Read the enum value name
    final enumName = enumTypeValue.read('_name').stringValue;

    // Map EnumType enum to string
    switch (enumName) {
      case 'name':
        return 'name';
      case 'value':
        return 'value';
      case 'ordinal':
      default:
        return 'ordinal';
    }
  }

  /// Gets the type converter expression for a field.
  String? _getConverterExpression(FieldElement field) {
    final annotation = _useConverterChecker.firstAnnotationOf(field);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    final converterValue = reader.peek('converter');

    if (converterValue == null || converterValue.isNull) return null;

    // Get the revived constant
    final revived = converterValue.revive();

    // Build the converter expression from the revive data
    final typeName = revived.source.fragment;

    // Generate expression like: const ColorConverter()
    // Always use const since converters should be const
    return 'const $typeName()';
  }

  /// Checks if a field is marked with @JsonField.
  bool _isJsonField(FieldElement field) {
    return _jsonFieldChecker.hasAnnotationOf(field);
  }

  /// Analyzes indexes on a class.
  List<IndexInfo> _analyzeIndexes(
    ClassElement element,
    String tableName,
    ConstantReader tableAnnotation,
    List<ColumnInfo> columns,
  ) {
    final indexes = <IndexInfo>[];

    // Create a map of Dart property names to SQL column names
    final dartToSqlMap = <String, String>{};
    for (final column in columns) {
      dartToSqlMap[column.dartName] = column.sqlName;
    }

    // First, check for indexes defined in the @DbTable annotation
    final indexesFromTable = tableAnnotation.peek('indexes');
    if (indexesFromTable != null && !indexesFromTable.isNull) {
      final indexesList = indexesFromTable.listValue;
      for (final indexValue in indexesList) {
        final dartColumns = indexValue
            .toListValue()!
            .map((e) => e.toStringValue()!)
            .toList();

        // Convert Dart property names to SQL column names
        final sqlColumns = dartColumns.map((dartName) {
          final sqlName = dartToSqlMap[dartName];
          if (sqlName == null) {
            throw StateError(
              'Index references unknown column "$dartName" in table $tableName',
            );
          }
          return sqlName;
        }).toList();

        final indexName =
            'idx_${NamingUtils.toSnakeCase(tableName)}_${sqlColumns.join('_')}';

        indexes.add(
          IndexInfo(
            name: indexName,
            columns: sqlColumns,
            unique:
                false, // Indexes from Table annotation are not unique by default
          ),
        );
      }
    }

    // Then, check for @Index annotations on the class
    for (final annotation in _indexChecker.annotationsOf(element)) {
      final reader = ConstantReader(annotation);

      final name = reader.peek('name')?.stringValue;
      final dartColumns = reader
          .read('columns')
          .listValue
          .map((e) => e.toStringValue()!)
          .toList();
      final unique = reader.read('unique').boolValue;

      // Convert Dart property names to SQL column names
      final sqlColumns = dartColumns.map((dartName) {
        final sqlName = dartToSqlMap[dartName];
        if (sqlName == null) {
          throw StateError(
            'Index references unknown column "$dartName" in table $tableName',
          );
        }
        return sqlName;
      }).toList();

      final indexName =
          name ??
          'idx_${NamingUtils.toSnakeCase(tableName)}_${sqlColumns.join('_')}';

      indexes.add(
        IndexInfo(name: indexName, columns: sqlColumns, unique: unique),
      );
    }

    return indexes;
  }
}
