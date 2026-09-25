import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/helpers/type_utils.dart';
import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';
import 'package:native_sqlite_generator/src/sql/sql_identifier.dart';

/// Generates a type-safe query builder class for a table.
class QueryBuilderGenerator {
  /// Generates the query builder class code.
  String generate(TableInfo table) {
    final className = table.dartName;
    final queryClassName = '${className}QueryBuilder';

    final buffer = StringBuffer();

    // Class header
    buffer.writeln('/// Generated query builder for [$className].');
    buffer.writeln('///');
    buffer.writeln(
      '/// Regenerate with `flutter pub run build_runner build` after changing the model.',
    );
    buffer.writeln('class $queryClassName {');
    buffer.writeln('  final NativeSqliteDatabase _database;');
    buffer.writeln('  final List<String> _whereConditions = [];');
    buffer.writeln('  final List<Object?> _whereArgs = [];');
    buffer.writeln('  final List<String> _orderBy = [];');
    buffer.writeln('  int? _limit;');
    buffer.writeln('  int? _offset;');
    buffer.writeln();
    buffer.writeln('  $queryClassName(this._database);');
    buffer.writeln();

    // Generate filter methods for each column
    for (final column in table.columns) {
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
    final sqlName = quoteSqlIdentifier(column.sqlName);
    final dartType = column.dartType;

    if (TypeUtils.isString(dartType)) {
      _generateStringFilters(
        buffer,
        fieldName,
        sqlName,
        queryClassName,
        column.isNullable,
      );
    } else if (TypeUtils.isInt(dartType) ||
        TypeUtils.isDouble(dartType) ||
        TypeUtils.isNum(dartType)) {
      _generateNumericFilters(
        buffer,
        fieldName,
        sqlName,
        queryClassName,
        column.isNullable,
        TypeUtils.getBaseTypeName(dartType),
      );
    } else if (TypeUtils.isDateTime(dartType)) {
      _generateDateTimeFilters(
        buffer,
        fieldName,
        sqlName,
        queryClassName,
        column.isNullable,
      );
    } else if (TypeUtils.isDuration(dartType)) {
      _generateDurationFilters(
        buffer,
        fieldName,
        sqlName,
        queryClassName,
        column.isNullable,
      );
    } else if (TypeUtils.isBool(dartType)) {
      _generateBoolFilters(
        buffer,
        fieldName,
        sqlName,
        queryClassName,
        column.isNullable,
      );
    } else if (TypeUtils.isEnum(dartType)) {
      _generateEnumFilters(
        buffer,
        fieldName,
        sqlName,
        queryClassName,
        column.isNullable,
        TypeUtils.getBaseTypeName(dartType),
        column.enumType,
      );
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
      '  $queryClassName ${fieldName}EqualTo(String$nullCheck value) {',
    );
    if (isNullable) {
      buffer.writeln('    if (value == null) {');
      buffer.writeln('      _whereConditions.add(\'$sqlName IS NULL\');');
      buffer.writeln('    } else {');
      buffer.writeln('      _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('      _whereArgs.add(value);');
      buffer.writeln('    }');
    } else {
      buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('    _whereArgs.add(value);');
    }
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName contains [value].');
    buffer.writeln('  $queryClassName ${fieldName}Contains(String value) {');
    buffer.writeln(
      '    _whereConditions.add(${_dartStringLiteral("$sqlName LIKE ? ESCAPE '\\'")});',
    );
    buffer.writeln('    _whereArgs.add(\'%\${_escapeLike(value)}%\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName starts with [value].');
    buffer.writeln('  $queryClassName ${fieldName}StartsWith(String value) {');
    buffer.writeln(
      '    _whereConditions.add(${_dartStringLiteral("$sqlName LIKE ? ESCAPE '\\'")});',
    );
    buffer.writeln('    _whereArgs.add(\'\${_escapeLike(value)}%\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName ends with [value].');
    buffer.writeln('  $queryClassName ${fieldName}EndsWith(String value) {');
    buffer.writeln(
      '    _whereConditions.add(${_dartStringLiteral("$sqlName LIKE ? ESCAPE '\\'")});',
    );
    buffer.writeln('    _whereArgs.add(\'%\${_escapeLike(value)}\');');
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
      '  $queryClassName ${fieldName}EqualTo($typeName$nullCheck value) {',
    );
    if (isNullable) {
      buffer.writeln('    if (value == null) {');
      buffer.writeln('      _whereConditions.add(\'$sqlName IS NULL\');');
      buffer.writeln('    } else {');
      buffer.writeln('      _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('      _whereArgs.add(value);');
      buffer.writeln('    }');
    } else {
      buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('    _whereArgs.add(value);');
    }
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is greater than [value].');
    buffer.writeln(
      '  $queryClassName ${fieldName}GreaterThan($typeName value) {',
    );
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
      '  $queryClassName ${fieldName}Between($typeName min, $typeName max) {',
    );
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
      '  $queryClassName ${fieldName}EqualTo(DateTime$nullCheck value) {',
    );
    if (isNullable) {
      buffer.writeln('    if (value == null) {');
      buffer.writeln('      _whereConditions.add(\'$sqlName IS NULL\');');
      buffer.writeln('    } else {');
      buffer.writeln('      _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('      _whereArgs.add(value.millisecondsSinceEpoch);');
      buffer.writeln('    }');
    } else {
      buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('    _whereArgs.add(value.millisecondsSinceEpoch);');
    }
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

    buffer.writeln(
      '  /// Filter where $fieldName is between [start] and [end].',
    );
    buffer.writeln(
      '  $queryClassName ${fieldName}Between(DateTime start, DateTime end) {',
    );
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
      '  $queryClassName ${fieldName}EqualTo(Duration$nullCheck value) {',
    );
    if (isNullable) {
      buffer.writeln('    if (value == null) {');
      buffer.writeln('      _whereConditions.add(\'$sqlName IS NULL\');');
      buffer.writeln('    } else {');
      buffer.writeln('      _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('      _whereArgs.add(value.inMilliseconds);');
      buffer.writeln('    }');
    } else {
      buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
      buffer.writeln('    _whereArgs.add(value.inMilliseconds);');
    }
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Filter where $fieldName is greater than [value].');
    buffer.writeln(
      '  $queryClassName ${fieldName}GreaterThan(Duration value) {',
    );
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
      '  $queryClassName ${fieldName}EqualTo($enumType$nullCheck value) {',
    );
    if (isNullable) {
      buffer.writeln('    if (value == null) {');
      buffer.writeln('      _whereConditions.add(\'$sqlName IS NULL\');');
      buffer.writeln('    } else {');
      buffer.writeln('      _whereConditions.add(\'$sqlName = ?\');');
      if (enumStorageType == 'name') {
        buffer.writeln('      _whereArgs.add(value.name);');
      } else {
        buffer.writeln('      _whereArgs.add(value.index);');
      }
      buffer.writeln('    }');
    } else {
      buffer.writeln('    _whereConditions.add(\'$sqlName = ?\');');
      if (enumStorageType == 'name') {
        buffer.writeln('    _whereArgs.add(value.name);');
      } else {
        buffer.writeln('    _whereArgs.add(value.index);');
      }
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
    final sqlName = quoteSqlIdentifier(column.sqlName);

    buffer.writeln('  /// Sort by $fieldName in ascending order.');
    buffer.writeln(
      '  $queryClassName sortBy${NamingUtils.toPascalCase(fieldName)}Asc() {',
    );
    buffer.writeln('    _orderBy');
    buffer.writeln('      ..clear()');
    buffer.writeln('      ..add(\'$sqlName ASC\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Sort by $fieldName in descending order.');
    buffer.writeln(
      '  $queryClassName sortBy${NamingUtils.toPascalCase(fieldName)}Desc() {',
    );
    buffer.writeln('    _orderBy');
    buffer.writeln('      ..clear()');
    buffer.writeln('      ..add(\'$sqlName DESC\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Then sort by $fieldName in ascending order.');
    buffer.writeln(
      '  $queryClassName thenBy${NamingUtils.toPascalCase(fieldName)}Asc() {',
    );
    buffer.writeln('    _orderBy.add(\'$sqlName ASC\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Then sort by $fieldName in descending order.');
    buffer.writeln(
      '  $queryClassName thenBy${NamingUtils.toPascalCase(fieldName)}Desc() {',
    );
    buffer.writeln('    _orderBy.add(\'$sqlName DESC\');');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generatePaginationMethods(StringBuffer buffer, String queryClassName) {
    buffer.writeln('  /// Limit the number of results.');
    buffer.writeln('  $queryClassName limit(int value) {');
    buffer.writeln(
      "    if (value < 0) throw ArgumentError.value(value, 'value', 'must not be negative');",
    );
    buffer.writeln('    _limit = value;');
    buffer.writeln('    return this;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Skip [value] results.');
    buffer.writeln('  $queryClassName offset(int value) {');
    buffer.writeln(
      "    if (value < 0) throw ArgumentError.value(value, 'value', 'must not be negative');",
    );
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
    final quotedTableName = quoteSqlIdentifier(table.sqlName);

    buffer.writeln('  /// Execute the query and return all matching records.');
    buffer.writeln('  Future<List<$className>> findAll() async {');
    buffer.writeln('    final sql = toSql();');
    buffer.writeln(
      '    final result = await _database.query(sql, _whereArgs);',
    );
    buffer.writeln(
      '    return result.toMapList().map(${table.rowMapperName}).toList();',
    );
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
      '  /// Execute the query and return the first matching record.',
    );
    buffer.writeln('  Future<$className?> findFirst() async {');
    buffer.writeln('    final result = await _database.query(');
    buffer.writeln('      _buildQuery(limitOverride: 1),');
    buffer.writeln('      _whereArgs,');
    buffer.writeln('    );');
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln(
      '    return rows.isEmpty ? null : ${table.rowMapperName}(rows.first);',
    );
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Count the number of matching records.');
    buffer.writeln('  Future<int> count() async {');
    buffer.writeln('    final whereClause = _whereConditions.isEmpty');
    buffer.writeln('        ? \'\'');
    buffer.writeln(
      '        : \' WHERE \${_whereConditions.join(\' AND \')}\';',
    );
    buffer.writeln(
      '    final sql = \'SELECT COUNT(*) as count FROM $quotedTableName\$whereClause\';',
    );
    buffer.writeln(
      '    final result = await _database.query(sql, _whereArgs);',
    );
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln(
      '    return rows.isEmpty ? 0 : rows.first[\'count\'] as int;',
    );
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Delete all matching records.');
    buffer.writeln('  Future<int> deleteAll() async {');
    buffer.writeln('    final whereClause = _whereConditions.isEmpty');
    buffer.writeln('        ? null');
    buffer.writeln('        : _whereConditions.join(\' AND \');');
    buffer.writeln('    return _database.delete(');
    buffer.writeln('      \'${table.sqlName}\',');
    buffer.writeln('      where: whereClause,');
    buffer.writeln('      whereArgs: _whereArgs.isEmpty ? null : _whereArgs,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateHelperMethods(StringBuffer buffer, TableInfo table) {
    final tableName = quoteSqlIdentifier(table.sqlName);

    buffer.writeln('  /// The parameterized SQL represented by this builder.');
    buffer.writeln('  String toSql() => _buildQuery();');
    buffer.writeln();
    buffer.writeln('  /// Alias for [toSql], intended for logs and debuggers.');
    buffer.writeln('  String get debugSql => toSql();');
    buffer.writeln();
    buffer.writeln('  /// Bound values in placeholder order.');
    buffer.writeln(
      '  List<Object?> get arguments => List<Object?>.unmodifiable(_whereArgs);',
    );
    buffer.writeln();
    buffer.writeln('  String _buildQuery({int? limitOverride}) {');
    buffer.writeln('    final whereClause = _whereConditions.isEmpty');
    buffer.writeln('        ? \'\'');
    buffer.writeln(
      '        : \' WHERE \${_whereConditions.join(\' AND \')}\';',
    );
    buffer.writeln(
      '    final orderClause = _orderBy.isEmpty ? \'\' : \' ORDER BY \${_orderBy.join(\', \')}\';',
    );
    buffer.writeln('    final effectiveLimit = limitOverride ?? _limit;');
    buffer.writeln(
      "    final limitClause = effectiveLimit != null ? ' LIMIT \$effectiveLimit' : (_offset == null ? '' : ' LIMIT -1');",
    );
    buffer.writeln(
      '    final offsetClause = _offset == null ? \'\' : \' OFFSET \$_offset\';',
    );
    buffer.writeln(
      '    return \'SELECT * FROM $tableName\$whereClause\$orderClause\$limitClause\$offsetClause\';',
    );
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  static String _escapeLike(String value) => value');
    buffer.writeln(r"      .replaceAll(r'\', r'\\')");
    buffer.writeln(r"      .replaceAll('%', r'\%')");
    buffer.writeln(r"      .replaceAll('_', r'\_');");
  }

  static String _dartStringLiteral(String value) {
    return "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";
  }
}
