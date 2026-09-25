import 'package:native_sqlite_generator/src/models/table_info.dart';
import 'package:native_sqlite_generator/src/sql/sql_identifier.dart';

/// Generates repository code for database operations.
class RepositoryGenerator {
  /// Generates the repository class for a table.
  String generate(TableInfo table) {
    final buffer = StringBuffer();

    buffer.writeln('/// Generated repository for [${table.dartName}].');
    buffer.writeln('///');
    buffer.writeln(
      '/// Regenerate with `flutter pub run build_runner build` after changing the model.',
    );
    buffer.writeln('class ${table.repositoryClassName} {');
    buffer.writeln('  final NativeSqliteDatabase database;');
    buffer.writeln();

    buffer.writeln('  const ${table.repositoryClassName}(this.database);');

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

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates the insert method.
  void _generateInsertMethod(StringBuffer buffer, TableInfo table) {
    String returnType;
    if (table.hasPrimaryKey) {
      if (table.primaryKey!.useLocalUuid) {
        returnType = 'Future<String>';
      } else {
        returnType = 'Future<${table.primaryKey!.typeDisplayName}>';
      }
    } else {
      returnType = 'Future<int>';
    }

    buffer.writeln('  /// Inserts a new ${table.dartName} into the database.');
    buffer.writeln('  /// Returns the ID of the inserted row.');
    buffer.writeln('  $returnType insert(${table.dartName} entity) async {');

    final pk = table.primaryKey;
    if (pk != null && pk.useLocalUuid) {
      buffer.writeln(
        '    final primaryKeyValue = entity.${pk.dartName} ?? NativeSqliteUuid.generate();',
      );
    }

    final insertPrefix = pk?.useLocalUuid == true
        ? '    await'
        : '    final rowId = await';
    buffer.writeln('$insertPrefix database.insert(');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln('      {');

    // UUID primary keys are inserted; auto-increment keys are omitted.
    for (final column in table.columns) {
      if (column.isAutoIncrement) continue;

      String value;
      if (column.isPrimaryKey && column.useLocalUuid) {
        value = 'primaryKeyValue';
      } else {
        value = column.serializeExpression('entity.${column.dartName}');
      }
      buffer.writeln("        '${column.sqlName}': $value,");
    }

    buffer.writeln('      },');
    buffer.writeln('    );');

    if (pk != null && pk.useLocalUuid) {
      buffer.writeln('    return primaryKeyValue;');
    } else if (pk != null && !pk.isAutoIncrement) {
      // SQLite returns ROWID, which may differ from a caller-supplied key.
      buffer.writeln('    return entity.${pk.dartName}!;');
    } else {
      buffer.writeln('    return rowId;');
    }
    buffer.writeln('  }');
  }

  /// Generates the find by ID method.
  void _generateFindByIdMethod(StringBuffer buffer, TableInfo table) {
    final pk = table.primaryKey!;
    final quotedTable = quoteSqlIdentifier(table.sqlName);
    final quotedPrimaryKey = quoteSqlIdentifier(pk.sqlName);

    buffer.writeln('  /// Finds a ${table.dartName} by its ID.');
    buffer.writeln('  /// Returns null if not found.');
    buffer.writeln(
      '  Future<${table.dartName}?> findById(${pk.typeDisplayName} id) async {',
    );
    buffer.writeln('    final result = await database.query(');
    buffer.writeln(
      "      'SELECT * FROM $quotedTable WHERE $quotedPrimaryKey = ? LIMIT 1',",
    );
    buffer.writeln('      [id],');
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln('    final rows = result.toMapList();');
    buffer.writeln('    if (rows.isEmpty) return null;');
    buffer.writeln();
    buffer.writeln('    return ${table.rowMapperName}(rows.first);');
    buffer.writeln('  }');
  }

  /// Generates the find all method.
  void _generateFindAllMethod(StringBuffer buffer, TableInfo table) {
    final quotedTable = quoteSqlIdentifier(table.sqlName);
    buffer.writeln('  /// Finds all ${table.dartName}s in the database.');
    buffer.writeln('  Future<List<${table.dartName}>> findAll() async {');
    buffer.writeln('    final result = await database.query(');
    buffer.writeln("      'SELECT * FROM $quotedTable',");
    buffer.writeln('    );');
    buffer.writeln();
    buffer.writeln(
      '    return result.toMapList().map(${table.rowMapperName}).toList();',
    );
    buffer.writeln('  }');
  }

  /// Generates the update method.
  void _generateUpdateMethod(StringBuffer buffer, TableInfo table) {
    final pk = table.primaryKey!;
    final quotedPrimaryKey = quoteSqlIdentifier(pk.sqlName);

    buffer.writeln(
      '  /// Updates an existing ${table.dartName} in the database.',
    );
    buffer.writeln('  /// Returns the number of rows affected.');
    buffer.writeln('  Future<int> update(${table.dartName} entity) async {');
    buffer.writeln('    return database.update(');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln('      {');

    for (final column in table.nonPrimaryColumns) {
      final value = column.serializeExpression('entity.${column.dartName}');
      buffer.writeln("        '${column.sqlName}': $value,");
    }

    buffer.writeln('      },');
    buffer.writeln("      where: '$quotedPrimaryKey = ?',");
    buffer.writeln('      whereArgs: [entity.${pk.dartName}],');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Generates the delete method.
  void _generateDeleteMethod(StringBuffer buffer, TableInfo table) {
    final pk = table.primaryKey!;
    final quotedPrimaryKey = quoteSqlIdentifier(pk.sqlName);

    buffer.writeln('  /// Deletes a ${table.dartName} by its ID.');
    buffer.writeln('  /// Returns the number of rows deleted.');
    buffer.writeln('  Future<int> delete(${pk.typeDisplayName} id) async {');
    buffer.writeln('    return database.delete(');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln("      where: '$quotedPrimaryKey = ?',");
    buffer.writeln('      whereArgs: [id],');
    buffer.writeln('    );');
    buffer.writeln('  }');
  }

  /// Generates the delete all method.
  void _generateDeleteAllMethod(StringBuffer buffer, TableInfo table) {
    buffer.writeln('  /// Deletes all records from the table.');
    buffer.writeln('  /// Returns the number of rows deleted.');
    buffer.writeln('  Future<int> deleteAll() async {');
    buffer.writeln("    return database.delete('${table.sqlName}');");
    buffer.writeln('  }');
  }

  /// Generates the count method.
  void _generateCountMethod(StringBuffer buffer, TableInfo table) {
    final quotedTable = quoteSqlIdentifier(table.sqlName);
    buffer.writeln('  /// Returns the total count of records in the table.');
    buffer.writeln('  Future<int> count() async {');
    buffer.writeln('    final result = await database.query(');
    buffer.writeln("      'SELECT COUNT(*) as count FROM $quotedTable',");
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
    buffer.writeln('    return ${table.dartName}QueryBuilder(database);');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
      '  /// Executes a custom query and returns the results as ${table.dartName} objects.',
    );
    buffer.writeln(
      '  Future<List<${table.dartName}>> query(String sql, [List<Object?>? arguments]) async {',
    );
    buffer.writeln('    final result = await database.query(sql, arguments);');
    buffer.writeln(
      '    return result.toMapList().map(${table.rowMapperName}).toList();',
    );
    buffer.writeln('  }');
    buffer.writeln();
  }
}
