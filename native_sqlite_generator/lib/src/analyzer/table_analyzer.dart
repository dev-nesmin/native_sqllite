import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/errors/generator_errors.dart';
import 'package:native_sqlite_generator/src/helpers/error_handler.dart';
import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/helpers/naming_conventions.dart';
import 'package:native_sqlite_generator/src/helpers/type_utils.dart';
import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/constructor_parameter_info.dart';
import 'package:native_sqlite_generator/src/models/index_info.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';
import 'package:source_gen/source_gen.dart';

/// Analyzes a class annotated with @DbTable and extracts table information.
class TableAnalyzer {
  /// Generator options. Defaults match [GeneratorOptions]' defaults so every
  /// builder derives identical table/column names — the schema snapshot,
  /// generated Dart and native code must all describe the same database.
  final GeneratorOptions options;

  TableAnalyzer([GeneratorOptions? options])
    : options = options ?? const GeneratorOptions();

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
        options.tableNameCase != 'none') {
      tableName = NamingConventions.format(className, options.tableNameCase);
    }

    // Analyze columns
    final columnAnalysis = _analyzeColumns(element);
    final columns = columnAnalysis.columns;
    final constructorParameters = _analyzeConstructor(element, columnAnalysis);

    final primaryKeys = columns.where((column) => column.isPrimaryKey).toList();
    if (primaryKeys.isEmpty) {
      throw MissingPrimaryKeyError(element, tableName);
    }
    if (primaryKeys.length > 1) {
      throw MultiplePrimaryKeysError(
        element,
        primaryKeys.map((column) => column.dartName).toList(),
      );
    }
    // Analyze table-declared and class-level indexes.
    final indexes = _analyzeIndexes(element, tableName, annotation, columns);

    // The runtime database is selected by its handle. Keep this legacy
    // per-table value as metadata until the annotation API is finalized.
    final databaseName =
        annotation.peek('database')?.stringValue ?? 'default_app';

    return TableInfo(
      dartName: className,
      sqlName: tableName,
      columns: columns,
      constructorParameters: constructorParameters,
      indexes: indexes,
      databaseName: databaseName,
    );
  }

  /// Validates that the class is suitable for table generation.
  void _validateClass(ClassElement element) {
    final isFreezed = _isFreezed(element);

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
  _ColumnAnalysis _analyzeColumns(ClassElement element) {
    final columns = <ColumnInfo>[];
    final elements = <String, Element>{};
    final isFreezed = _isFreezed(element);

    if (isFreezed) {
      // Freezed models expose their persisted fields as factory parameters.

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
        elements[columnInfo.dartName] = param;
      }
    } else {
      // Regular classes include declared state from their superclass chain and
      // applied mixins. Synthetic fields created for getters/setters are not
      // model state and must never become columns.
      for (final field in _instanceFields(element)) {
        if (field.isStatic || field.isSynthetic || _isIgnored(field)) {
          continue;
        }

        if (field.name!.startsWith('_')) {
          throw InvalidGenerationSourceError(
            'Private database field "${field.name}" must be annotated with '
            '@Ignore().',
            element: field,
          );
        }

        final columnInfo = _analyzeColumn(field);
        columns.add(columnInfo);
        elements[columnInfo.dartName] = field;
      }
    }

    // Validate that we have at least one column
    GeneratorError.validate(
      columns.isNotEmpty,
      'Table must have at least one column',
      element,
    );

    return _ColumnAnalysis(columns, elements);
  }

  List<FieldElement> _instanceFields(ClassElement element) {
    final fields = <String, FieldElement>{};
    final visited = <InterfaceElement>{};

    void collect(InterfaceElement current) {
      if (!visited.add(current)) return;

      final supertype = current.supertype;
      if (supertype != null) collect(supertype.element);
      for (final mixin in current.mixins) {
        collect(mixin.element);
      }

      for (final field in current.fields) {
        final name = field.name;
        if (name != null) fields[name] = field;
      }
    }

    collect(element);
    return fields.values.toList();
  }

  List<ConstructorParameterInfo> _analyzeConstructor(
    ClassElement element,
    _ColumnAnalysis analysis,
  ) {
    final constructor = _isFreezed(element)
        ? element.constructors.firstWhere(
            (candidate) =>
                candidate.isFactory &&
                (candidate.name == 'default' ||
                    candidate.name == 'new' ||
                    (candidate.name ?? '').isEmpty),
            orElse: () => throw InvalidGenerationSourceError(
              'Freezed classes must have a default factory constructor.',
              element: element,
            ),
          )
        : element.unnamedConstructor;

    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'Table class ${element.name} must have an unnamed constructor whose '
        'parameters match its database fields.',
        element: element,
      );
    }

    final columnsByName = {
      for (final column in analysis.columns) column.dartName: column,
    };
    final mappedNames = <String>{};
    final result = <ConstructorParameterInfo>[];
    final parameters = constructor.formalParameters;
    final positional = parameters
        .where((parameter) => parameter.isPositional)
        .toList();
    var lastMappedPositional = -1;

    for (var index = 0; index < positional.length; index++) {
      if (columnsByName.containsKey(positional[index].name)) {
        lastMappedPositional = index;
      }
    }

    for (final parameter in parameters) {
      final name = parameter.name;
      final column = name == null ? null : columnsByName[name];

      if (column == null) {
        final positionalIndex = positional.indexOf(parameter);
        final mustProvide =
            parameter.isRequired ||
            (positionalIndex >= 0 && positionalIndex <= lastMappedPositional);
        if (mustProvide) {
          throw InvalidGenerationSourceError(
            'Constructor parameter "$name" has no matching database field. '
            'Make it an optional trailing parameter or add a field.',
            element: parameter,
          );
        }
        continue;
      }

      mappedNames.add(column.dartName);
      result.add(
        ConstructorParameterInfo(column: column, isNamed: parameter.isNamed),
      );
    }

    for (final column in analysis.columns) {
      if (mappedNames.contains(column.dartName)) continue;
      throw InvalidGenerationSourceError(
        'Database field "${column.dartName}" has no matching parameter in '
        'the unnamed constructor for ${element.name}. Add the parameter or '
        'annotate the field with @Ignore().',
        element: analysis.elements[column.dartName] ?? element,
      );
    }

    return result;
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

    // A converter changes both the generated codec and the physical SQLite
    // type. Analyze it before choosing the column type so TypeConverter<D, S>
    // is stored according to S rather than the model field's Dart type D.
    final converter = _getConverterInfo(element);

    // Get SQL type (passing enum type for enum fields)
    final sqlType = _getSqlType(
      element,
      converter?.storageType ?? dartType,
      enumType,
      converterStorageType: converter?.storageType,
    );

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
      converterExpression: converter?.expression,
      converterStorageType: converter?.storageType,
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
    if (options.columnNameCase != 'none') {
      return NamingConventions.format(dartName, options.columnNameCase);
    }

    return dartName;
  }

  /// Gets the SQL type for a field.
  SqlType _getSqlType(
    Element element,
    DartType type,
    String enumType, {
    DartType? converterStorageType,
  }) {
    // Check for explicit type annotation
    final annotation = _columnChecker.firstAnnotationOf(element);
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final explicitType = reader.peek('type')?.stringValue;
      if (explicitType != null) {
        final parsed = _parseSqlType(explicitType);
        if (converterStorageType != null) {
          final inferred = _sqlTypeForConverterStorage(
            converterStorageType,
            element,
          );
          if (parsed != inferred) {
            throw InvalidGenerationSourceError(
              '@DbColumn(type: "$explicitType") conflicts with the '
              'converter storage type '
              '${converterStorageType.getDisplayString()}, which maps to '
              '${inferred.sqlName}.',
              element: element,
              todo:
                  'Remove type: from @DbColumn or change it to '
                  "'${inferred.sqlName}'.",
            );
          }
        }
        return parsed;
      }
    }

    if (converterStorageType != null) {
      return _sqlTypeForConverterStorage(converterStorageType, element);
    }

    // Infer from Dart type, passing enum type for enum fields
    return SqlType.fromDartType(type, enumType: enumType);
  }

  SqlType _sqlTypeForConverterStorage(DartType type, Element element) {
    final baseType = TypeUtils.getBaseTypeName(type);
    const supported = {'int', 'double', 'num', 'String', 'Uint8List'};
    if (!supported.contains(baseType)) {
      throw InvalidGenerationSourceError(
        'TypeConverter storage type "$baseType" is not supported by SQLite.',
        element: element,
        todo:
            'Use int, double, num, String, or Uint8List as the converter '
            'storage type.',
      );
    }
    return SqlType.fromDartType(type);
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

  /// Gets the reconstructed converter and its SQL-facing storage type.
  _ConverterInfo? _getConverterInfo(Element element) {
    final annotation = _useConverterChecker.firstAnnotationOf(element);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    final converterValue = reader.peek('converter');

    if (converterValue == null || converterValue.isNull) return null;

    final object = converterValue.objectValue;
    final concreteType = object.type;
    if (concreteType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        '@UseConverter requires a TypeConverter instance.',
        element: element,
      );
    }

    InterfaceType? converterSupertype;
    for (final candidate in [concreteType, ...concreteType.allSupertypes]) {
      if (_typeConverterChecker.isExactlyType(candidate)) {
        converterSupertype = candidate;
        break;
      }
    }
    if (converterSupertype == null ||
        converterSupertype.typeArguments.length != 2) {
      throw InvalidGenerationSourceError(
        '@UseConverter requires a class that extends TypeConverter<D, S>.',
        element: element,
      );
    }

    // Revive the actual constant invocation so named constructors and every
    // positional/named argument survive code generation.
    final revived = converterValue.revive();
    final expression = _revivableToSource(revived, object, element.library!);

    return _ConverterInfo(
      expression: expression,
      storageType: converterSupertype.typeArguments[1],
    );
  }

  static final _typeConverterChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/type_converter.dart#TypeConverter',
  );

  String _revivableToSource(
    Revivable revived,
    DartObject object,
    LibraryElement context,
  ) {
    final arguments = <String>[
      ...revived.positionalArguments.map(
        (argument) => _constantToSource(argument, context),
      ),
      ...revived.namedArguments.entries.map(
        (entry) => '${entry.key}: ${_constantToSource(entry.value, context)}',
      ),
    ];

    if (revived.source.fragment.isEmpty) {
      final prefix = _prefixForReference(
        context,
        revived.source,
        revived.accessor.split('.').first,
      );
      return '$prefix${revived.accessor}';
    }

    final objectType = object.type;
    final typeReference =
        objectType is InterfaceType &&
            objectType.element.name == revived.source.fragment
        ? _typeToSource(objectType, context)
        : '${_prefixForReference(context, revived.source.removeFragment(), revived.source.fragment)}${revived.source.fragment}';
    final constructor = revived.accessor.isEmpty ? '' : '.${revived.accessor}';
    return 'const $typeReference$constructor(${arguments.join(', ')})';
  }

  String _constantToSource(DartObject object, LibraryElement context) {
    final reader = ConstantReader(object);
    if (reader.isNull) return 'null';
    if (reader.isBool) return '${reader.boolValue}';
    if (reader.isInt) return '${reader.intValue}';
    if (reader.isDouble) {
      final value = reader.doubleValue;
      if (value.isNaN) return 'double.nan';
      if (value == double.infinity) return 'double.infinity';
      if (value == double.negativeInfinity) return 'double.negativeInfinity';
      return '$value';
    }
    if (reader.isString) {
      return jsonEncode(reader.stringValue).replaceAll(r'$', r'\$');
    }
    if (reader.isSymbol) {
      return 'const Symbol(${jsonEncode(object.toSymbolValue())})';
    }
    if (reader.isType) return _typeToSource(reader.typeValue, context);
    if (reader.isList) {
      return 'const [${reader.listValue.map((value) => _constantToSource(value, context)).join(', ')}]';
    }
    if (reader.isSet) {
      return 'const {${reader.setValue.map((value) => _constantToSource(value, context)).join(', ')}}';
    }
    if (reader.isMap) {
      final entries = reader.mapValue.entries.map((entry) {
        final key = entry.key == null
            ? 'null'
            : _constantToSource(entry.key!, context);
        final value = entry.value == null
            ? 'null'
            : _constantToSource(entry.value!, context);
        return '$key: $value';
      });
      return 'const {${entries.join(', ')}}';
    }

    final record = object.toRecordValue();
    if (record != null) {
      final fields = <String>[
        ...record.positional.map((value) => _constantToSource(value, context)),
        ...record.named.entries.map(
          (entry) => '${entry.key}: ${_constantToSource(entry.value, context)}',
        ),
      ];
      if (record.positional.length == 1 && record.named.isEmpty) {
        return '(${fields.single},)';
      }
      return '(${fields.join(', ')})';
    }

    return _revivableToSource(reader.revive(), object, context);
  }

  String _typeToSource(DartType type, LibraryElement context) {
    if (type is InterfaceType) {
      final element = type.element;
      final prefix = _prefixForElement(context, element);
      final arguments = type.typeArguments.isEmpty
          ? ''
          : '<${type.typeArguments.map((argument) => _typeToSource(argument, context)).join(', ')}>';
      final nullable = type.nullabilitySuffix == NullabilitySuffix.question
          ? '?'
          : '';
      return '$prefix${element.name}$arguments$nullable';
    }
    return type.getDisplayString();
  }

  String _prefixForElement(
    LibraryElement context,
    InterfaceElement referenced,
  ) {
    if (context.uri == referenced.library.uri) return '';
    return _prefixForReference(
      context,
      referenced.library.uri,
      referenced.name!,
    );
  }

  String _prefixForReference(LibraryElement context, Uri source, String name) {
    String? prefixed;
    for (final import in context.firstFragment.libraryImports) {
      final imported = import.namespace.definedNames2[name];
      final matches = imported != null && imported.library?.uri == source;
      if (!matches && import.importedLibrary?.uri != source) continue;

      final prefix = import.prefix?.element.name;
      if (prefix == null) return '';
      prefixed ??= '$prefix.';
    }
    return prefixed ?? '';
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

    // Accept both the Dart field name and the resolved SQL column name. This
    // keeps model-oriented annotations ergonomic while allowing copied SQL
    // names from migrations and documentation.
    final columnNameToSql = <String, String>{};
    for (final column in columns) {
      columnNameToSql[column.dartName] = column.sqlName;
      columnNameToSql[column.sqlName] = column.sqlName;
    }

    // First, check for indexes defined in the @DbTable annotation
    final indexesFromTable = tableAnnotation.peek('indexes');
    if (indexesFromTable != null && !indexesFromTable.isNull) {
      final indexesList = indexesFromTable.listValue;
      for (final indexValue in indexesList) {
        final declaredColumns = indexValue
            .toListValue()!
            .map((e) => e.toStringValue()!)
            .toList();

        // Convert Dart property names to SQL column names
        final sqlColumns = declaredColumns.map((declaredName) {
          final sqlName = columnNameToSql[declaredName];
          if (sqlName == null) {
            throw InvalidGenerationSourceError(
              'Index references unknown column "$declaredName" in table '
              '$tableName.',
              element: element,
              todo:
                  'Use a Dart field name or its generated SQL column name. '
                  'Available columns: ${columnNameToSql.keys.join(', ')}.',
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
      final declaredColumns = reader
          .read('columns')
          .listValue
          .map((e) => e.toStringValue()!)
          .toList();
      final unique = reader.read('unique').boolValue;

      // Convert Dart property names to SQL column names
      final sqlColumns = declaredColumns.map((declaredName) {
        final sqlName = columnNameToSql[declaredName];
        if (sqlName == null) {
          throw InvalidGenerationSourceError(
            'Index references unknown column "$declaredName" in table '
            '$tableName.',
            element: element,
            todo:
                'Use a Dart field name or its generated SQL column name. '
                'Available columns: ${columnNameToSql.keys.join(', ')}.',
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

class _ColumnAnalysis {
  const _ColumnAnalysis(this.columns, this.elements);

  final List<ColumnInfo> columns;
  final Map<String, Element> elements;
}

class _ConverterInfo {
  const _ConverterInfo({required this.expression, required this.storageType});

  final String expression;
  final DartType storageType;
}
