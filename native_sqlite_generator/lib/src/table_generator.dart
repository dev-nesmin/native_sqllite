import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

/// Generator that creates table schemas and repository classes
/// from classes annotated with @Table.
class TableGenerator extends GeneratorForAnnotation<Table> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Table can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final tableName = annotation.peek('name')?.stringValue ??
        _toSnakeCase(className);

    final buffer = StringBuffer();

    // Add required imports
    buffer.writeln("import 'package:native_sqlite/native_sqlite.dart';");
    buffer.writeln();

    // Generate table schema
    final schema = _generateTableSchema(element, tableName);

    // Generate repository class
    final repository = _generateRepository(element, className, tableName);

    buffer.writeln('// Table schema for $className');
    buffer.writeln(schema);
    buffer.writeln();
    buffer.writeln('// Repository for $className');
    buffer.writeln(repository);

    return buffer.toString();
  }

  String _generateTableSchema(ClassElement element, String tableName) {
    final buffer = StringBuffer();
    final className = element.name;

    buffer.writeln('abstract class ${className}Schema {');
    buffer.writeln('  static const String tableName = \'$tableName\';');
    buffer.writeln();
    buffer.writeln('  static const String createTableSql = \'\'\'');
    buffer.write('    CREATE TABLE $tableName (');

    final fields = _getAnnotatedFields(element);
    final columnDefs = <String>[];
    final foreignKeys = <String>[];
    final indexes = <String>[];

    for (final field in fields) {
      final columnDef = _generateColumnDefinition(field);
      if (columnDef != null) {
        columnDefs.add(columnDef);
      }

      // Check for foreign key
      final foreignKey = _getForeignKey(field);
      if (foreignKey != null) {
        foreignKeys.add(foreignKey);
      }
    }

    buffer.write('\n');
    buffer.write(columnDefs.map((def) => '      $def').join(',\n'));

    if (foreignKeys.isNotEmpty) {
      buffer.write(',\n');
      buffer.write(foreignKeys.map((fk) => '      $fk').join(',\n'));
    }

    buffer.writeln('\n    )');
    buffer.writeln('  \'\'\';');

    // Generate index creation SQL
    final indexAnnotations = _getIndexAnnotations(element);
    if (indexAnnotations.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  static const List<String> indexSql = [');
      for (final index in indexAnnotations) {
        buffer.writeln('    \'\'\'$index\'\'\',');
      }
      buffer.writeln('  ];');
    }

    // Generate column name constants
    buffer.writeln();
    buffer.writeln('  // Column names');
    for (final field in fields) {
      final columnName = _getColumnName(field);
      final fieldName = field.name;
      final constantName = _toScreamingSnakeCase(fieldName);
      buffer.writeln('  static const String $constantName = \'$columnName\';');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateRepository(
    ClassElement element,
    String className,
    String tableName,
  ) {
    final buffer = StringBuffer();
    final fields = _getAnnotatedFields(element);
    final primaryKey = _getPrimaryKeyField(fields);

    buffer.writeln('class ${className}Repository {');
    buffer.writeln('  final String databaseName;');
    buffer.writeln();
    buffer.writeln('  const ${className}Repository(this.databaseName);');
    buffer.writeln();

    // Insert method
    _generateInsertMethod(buffer, className, tableName, fields);
    buffer.writeln();

    // Find by ID method (if primary key exists)
    if (primaryKey != null) {
      _generateFindByIdMethod(buffer, className, tableName, primaryKey);
      buffer.writeln();
    }

    // Find all method
    _generateFindAllMethod(buffer, className, tableName);
    buffer.writeln();

    // Update method
    if (primaryKey != null) {
      _generateUpdateMethod(buffer, className, tableName, fields, primaryKey);
      buffer.writeln();
    }

    // Delete method
    if (primaryKey != null) {
      _generateDeleteMethod(buffer, className, tableName, primaryKey);
      buffer.writeln();
    }

    // Delete all method
    _generateDeleteAllMethod(buffer, tableName);
    buffer.writeln();

    // Count method
    _generateCountMethod(buffer, tableName);
    buffer.writeln();

    // Query method
    _generateQueryMethod(buffer, className, tableName, fields);

    buffer.writeln('}');

    return buffer.toString();
  }

  void _generateInsertMethod(
    StringBuffer buffer,
    String className,
    String tableName,
    List<FieldElement> fields,
  ) {
    buffer.writeln('  /// Inserts a new $className into the database.');
    buffer.writeln('  /// Returns the ID of the inserted row.');
    buffer.writeln('  Future<int> insert($className entity) async {');
    buffer.writeln('    return NativeSqlite.insert(');
    buffer.writeln('      databaseName,');
    buffer.writeln('      \'$tableName\',');
    buffer.writeln('      {');

    for (final field in fields) {
      if (_isPrimaryKey(field) && _isAutoIncrement(field)) {
        continue; // Skip auto-increment primary keys
      }
      final columnName = _getColumnName(field);
      final fieldName = field.name;
      final value = _serializeFieldValue(field, 'entity.$fieldName');
      buffer.writeln('        \'$columnName\': $value,');
    }

    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  void _generateFindByIdMethod(
    StringBuffer buffer,
    String className,
    String tableName,
    FieldElement primaryKey,
  ) {
    final pkColumnName = _getColumnName(primaryKey);
    final pkType = primaryKey.type.getDisplayString(withNullability: false);

    buffer.writeln('  /// Finds a $className by its ID.');
    buffer.writeln('  /// Returns null if not found.');
    buffer.writeln('  Future<$className?> findById($pkType id) async {');
    buffer.writeln('    final result = await NativeSqlite.query(');
    buffer.writeln('      databaseName,');
    buffer.writeln('      \'SELECT * FROM $tableName WHERE $pkColumnName = ? LIMIT 1\',');
    buffer.writeln('      [id],');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln('    if (rows.isEmpty) return null;');
    buffer.writeln();
    buffer.writeln('    return _fromMap(rows.first);');
    buffer.writeln('  }');
  }

  void _generateFindAllMethod(
    StringBuffer buffer,
    String className,
    String tableName,
  ) {
    buffer.writeln('  /// Finds all ${className}s in the database.');
    buffer.writeln('  Future<List<$className>> findAll() async {');
    buffer.writeln('    final result = await NativeSqlite.query(');
    buffer.writeln('      databaseName,');
    buffer.writeln('      \'SELECT * FROM $tableName\',');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    return result.toMapList().map(_fromMap).toList();');
    buffer.writeln('  }');
  }

  void _generateUpdateMethod(
    StringBuffer buffer,
    String className,
    String tableName,
    List<FieldElement> fields,
    FieldElement primaryKey,
  ) {
    final pkColumnName = _getColumnName(primaryKey);
    final pkFieldName = primaryKey.name;

    buffer.writeln('  /// Updates an existing $className in the database.');
    buffer.writeln('  /// Returns the number of rows affected.');
    buffer.writeln('  Future<int> update($className entity) async {');
    buffer.writeln('    return NativeSqlite.update(');
    buffer.writeln('      databaseName,');
    buffer.writeln('      \'$tableName\',');
    buffer.writeln('      {');

    for (final field in fields) {
      if (_isPrimaryKey(field)) {
        continue; // Skip primary key in update values
      }
      final columnName = _getColumnName(field);
      final fieldName = field.name;
      final value = _serializeFieldValue(field, 'entity.$fieldName');
      buffer.writeln('        \'$columnName\': $value,');
    }

    buffer.writeln('      },');
    buffer.writeln('      where: \'$pkColumnName = ?\',');
    buffer.writeln('      whereArgs: [entity.$pkFieldName],');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  void _generateDeleteMethod(
    StringBuffer buffer,
    String className,
    String tableName,
    FieldElement primaryKey,
  ) {
    final pkColumnName = _getColumnName(primaryKey);
    final pkType = primaryKey.type.getDisplayString(withNullability: false);

    buffer.writeln('  /// Deletes a $className by its ID.');
    buffer.writeln('  /// Returns the number of rows deleted.');
    buffer.writeln('  Future<int> delete($pkType id) async {');
    buffer.writeln('    return NativeSqlite.delete(');
    buffer.writeln('      databaseName,');
    buffer.writeln('      \'$tableName\',');
    buffer.writeln('      where: \'$pkColumnName = ?\',');
    buffer.writeln('      whereArgs: [id],');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  void _generateDeleteAllMethod(StringBuffer buffer, String tableName) {
    buffer.writeln('  /// Deletes all records from the table.');
    buffer.writeln('  /// Returns the number of rows deleted.');
    buffer.writeln('  Future<int> deleteAll() async {');
    buffer.writeln('    return NativeSqlite.delete(databaseName, \'$tableName\');');
    buffer.writeln('  }');
  }

  void _generateCountMethod(StringBuffer buffer, String tableName) {
    buffer.writeln('  /// Returns the total count of records in the table.');
    buffer.writeln('  Future<int> count() async {');
    buffer.writeln('    final result = await NativeSqlite.query(');
    buffer.writeln('      databaseName,');
    buffer.writeln('      \'SELECT COUNT(*) as count FROM $tableName\',');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln('    if (rows.isEmpty) return 0;');
    buffer.writeln();
    buffer.writeln('    return rows.first[\'count\'] as int;');
    buffer.writeln('  }');
  }

  void _generateQueryMethod(
    StringBuffer buffer,
    String className,
    String tableName,
    List<FieldElement> fields,
  ) {
    buffer.writeln('  /// Executes a custom query and returns the results as $className objects.');
    buffer.writeln('  Future<List<$className>> query(String sql, [List<Object?>? arguments]) async {');
    buffer.writeln('    final result = await NativeSqlite.query(databaseName, sql, arguments);');
    buffer.writeln('    return result.toMapList().map(_fromMap).toList();');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Converts a map to a $className object.');
    buffer.writeln('  $className _fromMap(Map<String, Object?> map) {');
    buffer.writeln('    return $className(');

    for (final field in fields) {
      if (_isIgnored(field)) continue;

      final fieldName = field.name;
      final columnName = _getColumnName(field);
      final value = _deserializeFieldValue(field, 'map[\'$columnName\']');

      buffer.writeln('      $fieldName: $value,');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  String _deserializeFieldValue(FieldElement field, String accessor) {
    final dartType = field.type.getDisplayString(withNullability: false);
    final isNullable = field.type.nullabilitySuffix == NullabilitySuffix.question;

    if (dartType == 'DateTime') {
      if (isNullable) {
        return '$accessor != null ? DateTime.fromMillisecondsSinceEpoch($accessor as int) : null';
      }
      return 'DateTime.fromMillisecondsSinceEpoch($accessor as int)';
    } else if (dartType == 'bool') {
      if (isNullable) {
        return '$accessor != null ? ($accessor as int) == 1 : null';
      }
      return '($accessor as int) == 1';
    } else if (dartType == 'int') {
      if (isNullable) {
        return '$accessor as int?';
      }
      return '$accessor as int';
    } else if (dartType == 'double') {
      if (isNullable) {
        return '$accessor as double?';
      }
      return '$accessor as double';
    } else if (dartType == 'String') {
      if (isNullable) {
        return '$accessor as String?';
      }
      return '$accessor as String';
    }

    // For other types, just cast
    if (isNullable) {
      return '$accessor as $dartType?';
    }
    return '$accessor as $dartType';
  }

  String? _generateColumnDefinition(FieldElement field) {
    if (_isIgnored(field)) return null;

    final columnName = _getColumnName(field);
    final sqlType = _getSqlType(field);
    final isPk = _isPrimaryKey(field);
    final isAutoInc = isPk && _isAutoIncrement(field);
    final isNullable = field.type.nullabilitySuffix == NullabilitySuffix.question;
    final isUnique = _isUnique(field);
    final defaultValue = _getDefaultValue(field);

    final parts = <String>[columnName, sqlType];

    if (isPk) {
      parts.add('PRIMARY KEY');
      if (isAutoInc) {
        parts.add('AUTOINCREMENT');
      }
    }

    if (!isNullable && !isPk) {
      parts.add('NOT NULL');
    }

    if (isUnique && !isPk) {
      parts.add('UNIQUE');
    }

    if (defaultValue != null) {
      parts.add('DEFAULT $defaultValue');
    }

    return parts.join(' ');
  }

  String? _getForeignKey(FieldElement field) {
    final foreignKeyChecker = const TypeChecker.fromRuntime(ForeignKey);
    final annotation = foreignKeyChecker.firstAnnotationOf(field);

    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    final table = reader.read('table').stringValue;
    final column = reader.read('column').stringValue;
    final onDelete = reader.peek('onDelete')?.stringValue;
    final onUpdate = reader.peek('onUpdate')?.stringValue;

    final columnName = _getColumnName(field);
    final parts = <String>['FOREIGN KEY ($columnName) REFERENCES $table($column)'];

    if (onDelete != null) {
      parts.add('ON DELETE $onDelete');
    }

    if (onUpdate != null) {
      parts.add('ON UPDATE $onUpdate');
    }

    return parts.join(' ');
  }

  List<String> _getIndexAnnotations(ClassElement element) {
    final indexChecker = const TypeChecker.fromRuntime(Index);
    final indexes = <String>[];

    for (final annotation in indexChecker.annotationsOf(element)) {
      final reader = ConstantReader(annotation);
      final name = reader.peek('name')?.stringValue;
      final columns = reader.read('columns').listValue.map((e) => e.toStringValue()!).toList();
      final unique = reader.read('unique').boolValue;

      final tableName = element.name;
      final indexName = name ?? 'idx_${_toSnakeCase(tableName)}_${columns.join('_')}';
      final uniqueStr = unique ? 'UNIQUE ' : '';
      final indexSql = 'CREATE ${uniqueStr}INDEX $indexName ON ${_toSnakeCase(tableName)} (${columns.join(', ')})';
      indexes.add(indexSql);
    }

    return indexes;
  }

  List<FieldElement> _getAnnotatedFields(ClassElement element) {
    return element.fields.where((field) => !field.isStatic).toList();
  }

  FieldElement? _getPrimaryKeyField(List<FieldElement> fields) {
    for (final field in fields) {
      if (_isPrimaryKey(field)) {
        return field;
      }
    }
    return null;
  }

  bool _isPrimaryKey(FieldElement field) {
    final checker = const TypeChecker.fromRuntime(PrimaryKey);
    return checker.hasAnnotationOf(field);
  }

  bool _isAutoIncrement(FieldElement field) {
    final checker = const TypeChecker.fromRuntime(PrimaryKey);
    final annotation = checker.firstAnnotationOf(field);
    if (annotation == null) return false;

    final reader = ConstantReader(annotation);
    return reader.peek('autoIncrement')?.boolValue ?? false;
  }

  bool _isIgnored(FieldElement field) {
    final checker = const TypeChecker.fromRuntime(Ignore);
    return checker.hasAnnotationOf(field);
  }

  bool _isUnique(FieldElement field) {
    final checker = const TypeChecker.fromRuntime(Column);
    final annotation = checker.firstAnnotationOf(field);
    if (annotation == null) return false;

    final reader = ConstantReader(annotation);
    return reader.peek('unique')?.boolValue ?? false;
  }

  String? _getDefaultValue(FieldElement field) {
    final checker = const TypeChecker.fromRuntime(Column);
    final annotation = checker.firstAnnotationOf(field);
    if (annotation == null) return null;

    final reader = ConstantReader(annotation);
    return reader.peek('defaultValue')?.stringValue;
  }

  String _getColumnName(FieldElement field) {
    final checker = const TypeChecker.fromRuntime(Column);
    final annotation = checker.firstAnnotationOf(field);

    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final name = reader.peek('name')?.stringValue;
      if (name != null) return name;
    }

    return field.name;
  }

  String _getSqlType(FieldElement field) {
    // Check for explicit type annotation
    final checker = const TypeChecker.fromRuntime(Column);
    final annotation = checker.firstAnnotationOf(field);

    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final type = reader.peek('type')?.stringValue;
      if (type != null) return type;
    }

    // Infer from Dart type
    final dartType = field.type.getDisplayString(withNullability: false);

    if (dartType == 'int' || dartType == 'Int' || dartType == 'bool') {
      return 'INTEGER';
    } else if (dartType == 'double' || dartType == 'Double') {
      return 'REAL';
    } else if (dartType == 'String') {
      return 'TEXT';
    } else if (dartType == 'Uint8List' || dartType == 'List<int>') {
      return 'BLOB';
    } else if (dartType == 'DateTime') {
      return 'INTEGER'; // Store as milliseconds since epoch
    } else {
      return 'TEXT'; // Default to TEXT for custom types (will need serialization)
    }
  }

  String _serializeFieldValue(FieldElement field, String accessor) {
    final dartType = field.type.getDisplayString(withNullability: false);
    final isNullable = field.type.nullabilitySuffix == NullabilitySuffix.question;

    if (dartType == 'DateTime') {
      if (isNullable) {
        return '$accessor?.millisecondsSinceEpoch';
      }
      return '$accessor.millisecondsSinceEpoch';
    } else if (dartType == 'bool') {
      if (isNullable) {
        return '$accessor == true ? 1 : ($accessor == false ? 0 : null)';
      }
      return '$accessor ? 1 : 0';
    }

    return accessor;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _toScreamingSnakeCase(String input) {
    return _toSnakeCase(input).toUpperCase();
  }
}
