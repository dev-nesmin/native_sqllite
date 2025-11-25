import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/helpers/type_utils.dart';
import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Generates a type-safe query builder class for a table.
class QueryBuilderGenerator {
  /// Generates the query builder class code.
  String generate(TableInfo table) {
    final className = table.dartName;
    final queryClassName = '${className}QueryBuilder';

    final buffer = StringBuffer();

    // Class header
    buffer.writeln('// Query builder for $className');
    buffer.writeln('class $queryClassName {');
    buffer.writeln('  final String _databaseName;');
    buffer.writeln('  final List<String> _whereConditions = [];');
    buffer.writeln('  final List<Object?> _whereArgs = [];');
    buffer.writeln('  String? _orderBy;');
    buffer.writeln('  int? _limit;');
    buffer.writeln('  int? _offset;');
    buffer.writeln();
    buffer.writeln('  $queryClassName(this._databaseName);');
    buffer.writeln();

    // Generate filter methods for each column
    for (final column in table.columns) {
      if (column.isPrimaryKey && column.isAutoIncrement) {
        continue; // Skip auto-increment primary keys
      }
      _generateFilterMethods(buffer, column, queryClassName);
    }

    // Generate sort methods for each column
    for (final column in table.columns) {
      _generateSortMethods(buffer, column, queryClassName);
    }

    // Generate pagination methods
    _generatePaginationMethods(buffer, queryClassName);

    // Generate execution methods
    _generateExecutionMethods(buffer, table, queryClassName);

    // Helper methods
    _generateHelperMethods(buffer, table);

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  /// Generates filter methods based on column type.
  void _generateFilterMethods(
    StringBuffer buffer,
    ColumnInfo column,
    String queryClassName,
  ) {
    final fieldName = column.dartName;
    final sqlName = column.sqlName;
    final dartType = column.dartType;

    if (TypeUtils.isString(dartType)) {
      _generateStringFilters(
          buffer, fieldName, sqlName, queryClassName, column.isNullable);
    } else if (TypeUtils.isInt(dartType) ||
        TypeUtils.isDouble(dartType) ||
        TypeUtils.isNum(dartType)) {
      _generateNumericFilters(buffer, fieldName, sqlName, queryClassName,
          column.isNullable, TypeUtils.getBaseTypeName(dartType));
    } else if (TypeUtils.isDateTime(dartType)) {
      _generateDateTimeFilters(
          buffer, fieldName, sqlName, queryClassName, column.isNullable);
    } else if (TypeUtils.isDuration(dartType)) {
      _generateDurationFilters(
          buffer, fieldName, sqlName, queryClassName, column.isNullable);
    } else if (TypeUtils.isBool(dartType)) {
      _generateBoolFilters(
          buffer, fieldName, sqlName, queryClassName, column.isNullable);
    } else if (TypeUtils.isEnum(dartType)) {
      _generateEnumFilters(
          buffer,
          fieldName,
          sqlName,
          queryClassName,
          column.isNullable,
          TypeUtils.getBaseTypeName(dartType),
          column.enumType);
    }

    // Add isNull/isNotNull for nullable fields
    if (column.isNullable) {
      buffer.writeln('  /// Filter where $fieldName is null.');
      buffer.writeln('  $queryClassName ${fieldName}IsNull() {');
      buffer.writeln('    _whereConditions.add(\'$sqlName IS NULL\');');
      buffer.writeln('    return this;');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  /// Filter where $fieldName is not null.');
      buffer.writeln('  $queryClassName ${fieldName}IsNotNull() {');
      buffer.writeln('    _whereConditions.add(\'$sqlName IS NOT NULL\');');
      buffer.writeln('    return this;');
      buffer.writeln('  }');
      buffer.writeln();
    }
  }

  void _generateStringFilters(
    StringBuffer buffer,
    String fieldName,
    String sqlName,
    String queryClassName,
    bool isNullable,
  ) {
    final nullCheck = isNullable ? '?' : '';

    buffer.writeln('  /// Filter where $fieldName equals [value].');
    buffer.writeln(
        '  $queryClassName ${fieldName}EqualTo(String$nullCheck value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    buffer.writeln('    _whereArgs.add(value);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName contains [value].');
    buffer.writeln('  $queryClassName ${fieldName}Contains(String value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName LIKE ?\');');
    buffer.writeln('    _whereArgs.add(\'%\$value%\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName starts with [value].');
    buffer.writeln('  $queryClassName ${fieldName}StartsWith(String value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName LIKE ?\');');
    buffer.writeln('    _whereArgs.add(\'\$value%\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName ends with [value].');
    buffer.writeln('  $queryClassName ${fieldName}EndsWith(String value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName LIKE ?\');');
    buffer.writeln('    _whereArgs.add(\'%\$value\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateNumericFilters(
    StringBuffer buffer,
    String fieldName,
    String sqlName,
    String queryClassName,
    bool isNullable,
    String typeName,
  ) {
    final nullCheck = isNullable ? '?' : '';

    buffer.writeln('  /// Filter where $fieldName equals [value].');
    buffer.writeln(
        '  $queryClassName ${fieldName}EqualTo($typeName$nullCheck value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    buffer.writeln('    _whereArgs.add(value);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is greater than [value].');
    buffer.writeln(
        '  $queryClassName ${fieldName}GreaterThan($typeName value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName > ?\');');
    buffer.writeln('    _whereArgs.add(value);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is less than [value].');
    buffer.writeln('  $queryClassName ${fieldName}LessThan($typeName value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName < ?\');');
    buffer.writeln('    _whereArgs.add(value);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is between [min] and [max].');
    buffer.writeln(
        '  $queryClassName ${fieldName}Between($typeName min, $typeName max) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName BETWEEN ? AND ?\');');
    buffer.writeln('    _whereArgs.add(min);');
    buffer.writeln('    _whereArgs.add(max);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateDateTimeFilters(
    StringBuffer buffer,
    String fieldName,
    String sqlName,
    String queryClassName,
    bool isNullable,
  ) {
    final nullCheck = isNullable ? '?' : '';

    buffer.writeln('  /// Filter where $fieldName equals [value].');
    buffer.writeln(
        '  $queryClassName ${fieldName}EqualTo(DateTime$nullCheck value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    buffer.writeln(
        '    _whereArgs.add(value${isNullable ? '?' : ''}.millisecondsSinceEpoch);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is after [value].');
    buffer.writeln('  $queryClassName ${fieldName}After(DateTime value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName > ?\');');
    buffer.writeln('    _whereArgs.add(value.millisecondsSinceEpoch);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is before [value].');
    buffer.writeln('  $queryClassName ${fieldName}Before(DateTime value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName < ?\');');
    buffer.writeln('    _whereArgs.add(value.millisecondsSinceEpoch);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer
        .writeln('  /// Filter where $fieldName is between [start] and [end].');
    buffer.writeln(
        '  $queryClassName ${fieldName}Between(DateTime start, DateTime end) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName BETWEEN ? AND ?\');');
    buffer.writeln('    _whereArgs.add(start.millisecondsSinceEpoch);');
    buffer.writeln('    _whereArgs.add(end.millisecondsSinceEpoch);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateDurationFilters(
    StringBuffer buffer,
    String fieldName,
    String sqlName,
    String queryClassName,
    bool isNullable,
  ) {
    final nullCheck = isNullable ? '?' : '';

    buffer.writeln('  /// Filter where $fieldName equals [value].');
    buffer.writeln(
        '  $queryClassName ${fieldName}EqualTo(Duration$nullCheck value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    buffer.writeln(
        '    _whereArgs.add(value${isNullable ? '?' : ''}.inMilliseconds);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is greater than [value].');
    buffer
        .writeln('  $queryClassName ${fieldName}GreaterThan(Duration value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName > ?\');');
    buffer.writeln('    _whereArgs.add(value.inMilliseconds);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is less than [value].');
    buffer.writeln('  $queryClassName ${fieldName}LessThan(Duration value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName < ?\');');
    buffer.writeln('    _whereArgs.add(value.inMilliseconds);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateBoolFilters(
    StringBuffer buffer,
    String fieldName,
    String sqlName,
    String queryClassName,
    bool isNullable,
  ) {
    buffer.writeln('  /// Filter where $fieldName is true.');
    buffer.writeln('  $queryClassName ${fieldName}IsTrue() {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    buffer.writeln('    _whereArgs.add(1);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is false.');
    buffer.writeln('  $queryClassName ${fieldName}IsFalse() {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    buffer.writeln('    _whereArgs.add(0);');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateEnumFilters(
    StringBuffer buffer,
    String fieldName,
    String sqlName,
    String queryClassName,
    bool isNullable,
    String enumType,
    String enumStorageType,
  ) {
    final nullCheck = isNullable ? '?' : '';

    buffer.writeln('  /// Filter where $fieldName equals [value].');
    buffer.writeln(
        '  $queryClassName ${fieldName}EqualTo($enumType$nullCheck value) {');
    buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
    if (enumStorageType == 'name') {
      buffer.writeln('    _whereArgs.add(value${isNullable ? '?' : ''}.name);');
    } else {
      buffer
          .writeln('    _whereArgs.add(value${isNullable ? '?' : ''}.index);');
    }
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateSortMethods(
    StringBuffer buffer,
    ColumnInfo column,
    String queryClassName,
  ) {
    final fieldName = column.dartName;
    final sqlName = column.sqlName;

    buffer.writeln('  /// Sort by $fieldName in ascending order.');
    buffer.writeln(
        '  $queryClassName sortBy${NamingUtils.toPascalCase(fieldName)}Asc() {');
    buffer.writeln('    _orderBy = \'$sqlName ASC\';');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Sort by $fieldName in descending order.');
    buffer.writeln(
        '  $queryClassName sortBy${NamingUtils.toPascalCase(fieldName)}Desc() {');
    buffer.writeln('    _orderBy = \'$sqlName DESC\';');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generatePaginationMethods(
    StringBuffer buffer,
    String queryClassName,
  ) {
    buffer.writeln('  /// Limit the number of results.');
    buffer.writeln('  $queryClassName limit(int value) {');
    buffer.writeln('    _limit = value;');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Skip [value] results.');
    buffer.writeln('  $queryClassName offset(int value) {');
    buffer.writeln('    _offset = value;');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateExecutionMethods(
    StringBuffer buffer,
    TableInfo table,
    String queryClassName,
  ) {
    final className = table.dartName;
    final tableName = table.sqlName;

    buffer.writeln('  /// Execute the query and return all matching records.');
    buffer.writeln('  Future<List<$className>> findAll() async {');
    buffer.writeln('    final sql = _buildQuery();');
    buffer.writeln(
        '    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);');
    buffer.writeln('    return result.toMapList().map(_fromMap).toList();');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
        '  /// Execute the query and return the first matching record.');
    buffer.writeln('  Future<$className?> findFirst() async {');
    buffer.writeln('    _limit = 1;');
    buffer.writeln('    final results = await findAll();');
    buffer.writeln('    return results.isEmpty ? null : results.first;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Count the number of matching records.');
    buffer.writeln('  Future<int> count() async {');
    buffer.writeln('    final whereClause = _whereConditions.isEmpty');
    buffer.writeln('        ? \'\'');
    buffer
        .writeln('        : \' WHERE \${_whereConditions.join(\' AND \')}\';');
    buffer.writeln(
        '    final sql = \'SELECT COUNT(*) as count FROM $tableName\$whereClause\';');
    buffer.writeln(
        '    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);');
    buffer.writeln('    final rows = result.toMapList();');
    buffer
        .writeln('    return rows.isEmpty ? 0 : rows.first[\'count\'] as int;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Delete all matching records.');
    buffer.writeln('  Future<int> deleteAll() async {');
    buffer.writeln('    final whereClause = _whereConditions.isEmpty');
    buffer.writeln('        ? null');
    buffer.writeln('        : _whereConditions.join(\' AND \');');
    buffer.writeln('    return NativeSqlite.delete(');
    buffer.writeln('      _databaseName,');
    buffer.writeln('      \'$tableName\',');
    buffer.writeln('      where: whereClause,');
    buffer.writeln('      whereArgs: _whereArgs.isEmpty ? null : _whereArgs,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateHelperMethods(
    StringBuffer buffer,
    TableInfo table,
  ) {
    final tableName = table.sqlName;
    final className = table.dartName;

    buffer.writeln('  String _buildQuery() {');
    buffer.writeln('    final whereClause = _whereConditions.isEmpty');
    buffer.writeln('        ? \'\'');
    buffer
        .writeln('        : \' WHERE \${_whereConditions.join(\' AND \')}\';');
    buffer.writeln(
        '    final orderClause = _orderBy == null ? \'\' : \' ORDER BY \$_orderBy\';');
    buffer.writeln(
        '    final limitClause = _limit == null ? \'\' : \' LIMIT \$_limit\';');
    buffer.writeln(
        '    final offsetClause = _offset == null ? \'\' : \' OFFSET \$_offset\';');
    buffer.writeln(
        '    return \'SELECT * FROM $tableName\$whereClause\$orderClause\$limitClause\$offsetClause\';');
    buffer.writeln('  }');
    buffer.writeln();

    // Generate _fromMap method (same as in repository)
    buffer.writeln('  $className _fromMap(Map<String, Object?> map) {');
    buffer.writeln('    return $className(');
    for (final column in table.columns) {
      final fieldName = column.dartName;
      final accessor = 'map[\'${column.sqlName}\']';
      final deserialize = column.deserializeExpression(accessor);
      buffer.writeln('      $fieldName: $deserialize,');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
  }
}
