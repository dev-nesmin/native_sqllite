import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
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

  static final _primaryKeyChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/primary_key.dart#PrimaryKey',
  );
  static final _columnChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/column.dart#DbColumn',
  );
  static final _ignoreChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/ignore.dart#Ignore',
  );
  static final _foreignKeyChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/foreign_key.dart#ForeignKey',
  );
  static final _indexChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/index.dart#Index',
  );
  static final _enumFieldChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/enum.dart#EnumField',
  );
  static final _useConverterChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/type_converter.dart#UseConverter',
  );
  static final _jsonFieldChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/json_field.dart#JsonField',
  );
  // Freezed annotation checker - using simple name check or fromUrl if package known
  static final _freezedChecker = TypeChecker.fromUrl(
    'package:freezed_annotation/freezed_annotation.dart#Freezed',
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
    final isFreezed = _isFreezed(element);

    // Abstract classes are allowed ONLY if they are Freezed classes
    if (element.isAbstract && !isFreezed) {
      GeneratorError.throwError(
        'Table class must not be abstract (unless using @freezed)',
        element,
      );
    }
  }

  bool _isFreezed(ClassElement element) {
    return _freezedChecker.hasAnnotationOf(element);
  }

  /// Analyzes all fields in the class and returns column information.
  List<ColumnInfo> _analyzeColumns(ClassElement element) {
    final columns = <ColumnInfo>[];
    final isFreezed = _isFreezed(element);

    if (isFreezed) {
      // For Frozen classes, examine the factory constructor parameters

      final constructor = element.constructors.firstWhere(
        (c) =>
            c.isFactory &&
            (c.name == 'default' || c.name == 'new' || (c.name ?? '').isEmpty),
        orElse: () => throw InvalidGenerationSourceError(
          'Freezed classes must have a default factory constructor.',
          element: element,
        ),
      );

      for (final param in constructor.formalParameters) {
        if (_isIgnored(param)) {
          continue;
        }

        final columnInfo = _analyzeParameter(param);
        columns.add(columnInfo);
      }
    } else {
      // Regular classes - check fields
      for (final field in element.fields) {
        // Skip static fields and ignored fields
        if (field.isStatic || _isIgnored(field)) {
          continue;
        }

        final columnInfo = _analyzeColumn(field);
        columns.add(columnInfo);
      }
    }

    // Validate that we have at least one column
    GeneratorError.validate(
      columns.isNotEmpty,
      'Table must have at least one column',
      element,
    );

    return columns;
  }

  // Wrapper to analyze a parameter (for freezed)
  ColumnInfo _analyzeParameter(FormalParameterElement param) {
    return _analyzeElement(element: param, name: param.name!, type: param.type);
  }

  /// Analyzes a single field and returns column information.
  ColumnInfo _analyzeColumn(FieldElement field) {
    return _analyzeElement(element: field, name: field.name!, type: field.type);
  }

  ColumnInfo _analyzeElement({
    required Element element,
    required String name,
    required DartType type,
  }) {
    final fieldName = name;
    final dartType = type;

    // Get enum type first (if this is an enum field)
    final enumType = _getEnumType(element);

    // Get column name
    final columnName = _getColumnName(element, name);

    // Get SQL type (passing enum type for enum fields)
    final sqlType = _getSqlType(element, dartType, enumType);

    // Check if primary key
    final isPrimaryKey = _isPrimaryKey(element);

    // Check if auto increment
    final isAutoIncrement = isPrimaryKey && _isAutoIncrement(element);

    // Check if use local UUID
    final useLocalUuid = isPrimaryKey && _isUseLocalUuid(element);

    // PROPERTIES VALIDATION
    if (isPrimaryKey) {
      if (isAutoIncrement && useLocalUuid) {
        throw InvalidGenerationSourceError(
          'PrimaryKey cannot have both autoIncrement=true and useLocalUuid=true.',
          element: element,
        );
      }

      if (isAutoIncrement && !TypeUtils.isInt(dartType)) {
        throw InvalidGenerationSourceError(
          'PrimaryKey with autoIncrement=true must be an integer field.',
          element: element,
        );
      }

      if (useLocalUuid) {
        if (!TypeUtils.isString(dartType)) {
          throw InvalidGenerationSourceError(
            'PrimaryKey with useLocalUuid=true must be a String field.',
            element: element,
          );
        }

        // For auto-generation on insert, the field MUST be nullable so we can detect when to generate it
        if (!TypeUtils.isNullable(dartType)) {
          throw InvalidGenerationSourceError(
            'PrimaryKey with useLocalUuid=true must be nullable. The UUID is generated when the field is null.',
            element: element,
          );
        }
      }
    }

    // Check nullability
    final isNullable = _isColumnNullable(element, dartType);

    // Check if unique
    final isUnique = _isUnique(element);

    // Get default value
    final defaultValue = _getDefaultValue(element);

    // Get foreign key info
    final foreignKeyInfo = _getForeignKeyInfo(element);

    // Get converter expression (if this field uses a custom type converter)
    final converterExpression = _getConverterExpression(element);

    // Check if this is a JSON field
    final isJsonField = _isJsonField(element);

    return ColumnInfo(
      dartName: fieldName,
      sqlName: columnName,
      dartType: dartType,
      sqlType: sqlType,
      isPrimaryKey: isPrimaryKey,
      isAutoIncrement: isAutoIncrement,
      useLocalUuid: useLocalUuid,
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
  bool _isIgnored(Element element) {
    // Check for @Ignore
    if (_ignoreChecker.hasAnnotationOf(element)) return true;

    // Check for @DbColumn(ignore: true)
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      return reader.peek('ignore')?.boolValue ?? false;
    }

    return false;
  }

  /// Gets the column name for a field.
  String _getColumnName(Element element, String defaultName) {
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final name = reader.peek('name')?.stringValue;
      if (name != null) return name;
    }

    // Apply naming convention from options
    final dartName = defaultName;
    if (options != null && options!.columnNameCase != 'none') {
      return NamingConventions.format(dartName, options!.columnNameCase);
    }

    return dartName;
  }

  /// Gets the SQL type for a field.
  SqlType _getSqlType(Element element, DartType type, String enumType) {
    // Check for explicit type annotation
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final explicitType = reader.peek('type')?.stringValue;
      if (explicitType != null) {
        return _parseSqlType(explicitType);
      }
    }

    // Infer from Dart type, passing enum type for enum fields
    return SqlType.fromDartType(type, enumType: enumType);
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
  bool _isPrimaryKey(Element element) {
    return _primaryKeyChecker.hasAnnotationOf(element);
  }

  /// Checks if a field is auto-increment.
  bool _isAutoIncrement(Element element) {
    final annotation = _primaryKeyChecker.firstAnnotationOf(element);
    if (annotation == null) return false;

    final reader = ConstantReader(annotation);
    return reader.peek('autoIncrement')?.boolValue ?? false;
  }

  /// Checks if a field should use a local UUID.
  bool _isUseLocalUuid(Element element) {
    final annotation = _primaryKeyChecker.firstAnnotationOf(element);
    if (annotation == null) return false;

    final reader = ConstantReader(annotation);
    return reader.peek('useLocalUuid')?.boolValue ?? false;
  }

  /// Checks if a column is nullable.
  bool _isColumnNullable(Element element, DartType type) {
    // Check if Column annotation explicitly sets nullable
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final nullable = reader.peek('nullable')?.boolValue;
      if (nullable != null) {
        return nullable;
      }
    }

    // Fall back to Dart type nullability
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  /// Checks if a field has a unique constraint.
  bool _isUnique(Element element) {
    // Check for unique in @DbColumn annotation
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      return reader.peek('unique')?.boolValue ?? false;
    }

    return false;
  }

  /// Gets the default value for a column.
  String? _getDefaultValue(Element element) {
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    return reader.peek('defaultValue')?.stringValue;
  }

  /// Gets foreign key information for a field.
  Map<String, dynamic>? _getForeignKeyInfo(Element element) {
    final annotation = _foreignKeyChecker.firstAnnotationOf(element);
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
  String _getEnumType(Element element) {
    final annotation = _enumFieldChecker.firstAnnotationOf(element);
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
  String? _getConverterExpression(Element element) {
    final annotation = _useConverterChecker.firstAnnotationOf(element);
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
  bool _isJsonField(Element element) {
    return _jsonFieldChecker.hasAnnotationOf(element);
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
