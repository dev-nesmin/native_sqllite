import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Generates repository code for database operations.
class RepositoryGenerator {
  /// Generates the repository class for a table.
  String generate(TableInfo table) {
    final buffer = StringBuffer();

    buffer.writeln('// Repository for ${table.dartName}');
    buffer.writeln('class ${table.repositoryClassName} {');
    buffer.writeln('  final String databaseName;');
    buffer.writeln();

    // Always generate optional parameter with default database name
    buffer.writeln(
      '  const ${table.repositoryClassName}([this.databaseName = \'${table.databaseName}\']);',
    );

    buffer.writeln();

    // Insert method
    _generateInsertMethod(buffer, table);
    buffer.writeln();

    // Find by ID method (if primary key exists)
    if (table.hasPrimaryKey) {
      _generateFindByIdMethod(buffer, table);
      buffer.writeln();
    }

    // Find all method
    _generateFindAllMethod(buffer, table);
    buffer.writeln();

    // Update method
    if (table.hasPrimaryKey) {
      _generateUpdateMethod(buffer, table);
      buffer.writeln();
    }

    // Delete method
    if (table.hasPrimaryKey) {
      _generateDeleteMethod(buffer, table);
      buffer.writeln();
    }

    // Delete all method
    _generateDeleteAllMethod(buffer, table);
    buffer.writeln();

    // Count method
    _generateCountMethod(buffer, table);
    buffer.writeln();

    // Query method
    _generateQueryMethod(buffer, table);

    // Helper methods
    _generateFromMapMethod(buffer, table);

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates the insert method.
  void _generateInsertMethod(StringBuffer buffer, TableInfo table) {
    buffer.writeln('  /// Inserts a new ${table.dartName} into the database.');
    buffer.writeln('  /// Returns the ID of the inserted row.');
    buffer.writeln('  Future<int> insert(${table.dartName} entity) async {');
    buffer.writeln('    return NativeSqlite.insert(');
    buffer.writeln('      databaseName,');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln('      {');

    final insertColumns = table.nonAutoIncrementColumns;
    if (insertColumns.isNotEmpty) {
      for (final column in insertColumns) {
        final value = column.serializeExpression('entity.${column.dartName}');
        buffer.writeln("        '${column.sqlName}': $value,");
      }
    }

    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Generates the find by ID method.
  void _generateFindByIdMethod(StringBuffer buffer, TableInfo table) {
    final pk = table.primaryKey!;

    buffer.writeln('  /// Finds a ${table.dartName} by its ID.');
    buffer.writeln('  /// Returns null if not found.');
    buffer.writeln(
      '  Future<${table.dartName}?> findById(${pk.typeDisplayName} id) async {',
    );
    buffer.writeln('    final result = await NativeSqlite.query(');
    buffer.writeln('      databaseName,');
    buffer.writeln(
      "      'SELECT * FROM ${table.sqlName} WHERE ${pk.sqlName} = ? LIMIT 1',",
    );
    buffer.writeln('      [id],');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln('    if (rows.isEmpty) return null;');
    buffer.writeln();
    buffer.writeln('    return _fromMap(rows.first);');
    buffer.writeln('  }');
  }

  /// Generates the find all method.
  void _generateFindAllMethod(StringBuffer buffer, TableInfo table) {
    buffer.writeln('  /// Finds all ${table.dartName}s in the database.');
    buffer.writeln('  Future<List<${table.dartName}>> findAll() async {');
    buffer.writeln('    final result = await NativeSqlite.query(');
    buffer.writeln('      databaseName,');
    buffer.writeln("      'SELECT * FROM ${table.sqlName}',");
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    return result.toMapList().map(_fromMap).toList();');
    buffer.writeln('  }');
  }

  /// Generates the update method.
  void _generateUpdateMethod(StringBuffer buffer, TableInfo table) {
    final pk = table.primaryKey!;

    buffer.writeln(
      '  /// Updates an existing ${table.dartName} in the database.',
    );
    buffer.writeln('  /// Returns the number of rows affected.');
    buffer.writeln('  Future<int> update(${table.dartName} entity) async {');
    buffer.writeln('    return NativeSqlite.update(');
    buffer.writeln('      databaseName,');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln('      {');

    for (final column in table.nonPrimaryColumns) {
      final value = column.serializeExpression('entity.${column.dartName}');
      buffer.writeln("        '${column.sqlName}': $value,");
    }

    buffer.writeln('      },');
    buffer.writeln("      where: '${pk.sqlName} = ?',");
    buffer.writeln('      whereArgs: [entity.${pk.dartName}],');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Generates the delete method.
  void _generateDeleteMethod(StringBuffer buffer, TableInfo table) {
    final pk = table.primaryKey!;

    buffer.writeln('  /// Deletes a ${table.dartName} by its ID.');
    buffer.writeln('  /// Returns the number of rows deleted.');
    buffer.writeln('  Future<int> delete(${pk.typeDisplayName} id) async {');
    buffer.writeln('    return NativeSqlite.delete(');
    buffer.writeln('      databaseName,');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln("      where: '${pk.sqlName} = ?',");
    buffer.writeln('      whereArgs: [id],');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Generates the delete all method.
  void _generateDeleteAllMethod(StringBuffer buffer, TableInfo table) {
    buffer.writeln('  /// Deletes all records from the table.');
    buffer.writeln('  /// Returns the number of rows deleted.');
    buffer.writeln('  Future<int> deleteAll() async {');
    buffer.writeln(
      "    return NativeSqlite.delete(databaseName, '${table.sqlName}');",
    );
    buffer.writeln('  }');
  }

  /// Generates the count method.
  void _generateCountMethod(StringBuffer buffer, TableInfo table) {
    buffer.writeln('  /// Returns the total count of records in the table.');
    buffer.writeln('  Future<int> count() async {');
    buffer.writeln('    final result = await NativeSqlite.query(');
    buffer.writeln('      databaseName,');
    buffer.writeln("      'SELECT COUNT(*) as count FROM ${table.sqlName}',");
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln('    if (rows.isEmpty) return 0;');
    buffer.writeln();
    buffer.writeln("    return rows.first['count'] as int;");
    buffer.writeln('  }');
  }

  /// Generates the query method.
  void _generateQueryMethod(StringBuffer buffer, TableInfo table) {
    // Add the query builder method
    buffer.writeln('  /// Creates a new query builder for type-safe queries.');
    buffer.writeln('  ${table.dartName}QueryBuilder queryBuilder() {');
    buffer.writeln('    return ${table.dartName}QueryBuilder(databaseName);');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
      '  /// Executes a custom query and returns the results as ${table.dartName} objects.',
    );
    buffer.writeln(
      '  Future<List<${table.dartName}>> query(String sql, [List<Object?>? arguments]) async {',
    );
    buffer.writeln(
      '    final result = await NativeSqlite.query(databaseName, sql, arguments);',
    );
    buffer.writeln('    return result.toMapList().map(_fromMap).toList();');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// Generates the fromMap helper method.
  void _generateFromMapMethod(StringBuffer buffer, TableInfo table) {
    buffer.writeln('  /// Converts a map to a ${table.dartName} object.');
    buffer.writeln('  ${table.dartName} _fromMap(Map<String, Object?> map) {');
    buffer.writeln('    return ${table.dartName}(');

    for (final column in table.columns) {
      final value = column.deserializeExpression("map['${column.sqlName}']");
      buffer.writeln('      ${column.dartName}: $value,');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
  }
}
