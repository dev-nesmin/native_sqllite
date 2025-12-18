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

    // UUID helper
    if (table.primaryKey?.useLocalUuid == true) {
      buffer.writeln();
      _generateUuidHelper(buffer);
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates the insert method.
  void _generateInsertMethod(StringBuffer buffer, TableInfo table) {
    // If we have a primary key, we return it. Otherwise we return int (row ID).
    // If we have a primary key, we return it. Otherwise we return int (row ID).
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

    // Handle UUID generation if needed
    final pk = table.primaryKey;
    if (pk != null && pk.useLocalUuid) {
      buffer.writeln(
        '    final id = entity.${pk.dartName} ?? _generateUuid();',
      );
    }

    buffer.writeln('    final id = await NativeSqlite.insert(');
    buffer.writeln('      databaseName,');
    buffer.writeln("      '${table.sqlName}',");
    buffer.writeln('      {');

    // Add all columns except auto-increment PK
    // for UUID PKs, we include them
    for (final column in table.columns) {
      if (column.isAutoIncrement) continue;

      String value;
      if (column.isPrimaryKey && column.useLocalUuid) {
        value = 'id';
      } else {
        value = column.serializeExpression('entity.${column.dartName}');
      }
      buffer.writeln("        '${column.sqlName}': $value,");
    }

    buffer.writeln('      },');
    buffer.writeln('    );');

    // Return the appropriate ID
    if (pk != null && pk.useLocalUuid) {
      buffer.writeln('    return id as String;');
    } else if (pk != null && !pk.isAutoIncrement) {
      // If manually set ID (not auto-inc, not UUID), return what was passed
      // But NativeSqlite.insert returns the ROWID (int), so we might need to return entity.id
      // EXCEPT: If the PK is not an int (e.g. String), insert() still returns rowid.
      // So we should return the entity's ID.
      buffer.writeln('    return entity.${pk.dartName}!;');
    } else {
      // For auto-increment int, return the result from insert()
      buffer.writeln('    return id;');
    }
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

  /// Generates a random UUID (v4-like).
  void _generateUuidHelper(StringBuffer buffer) {
    buffer.writeln('  /// Generates a random UUID.');
    buffer.writeln('  String _generateUuid() {');
    buffer.writeln('    final random = Random.secure();');
    buffer.writeln(
      '    final values = List<int>.generate(16, (i) => random.nextInt(256));',
    );
    buffer.writeln('    values[6] = (values[6] & 0x0f) | 0x40; // version 4');
    buffer.writeln('    values[8] = (values[8] & 0x3f) | 0x80; // variant 10');
    buffer.writeln(
      '    return values.map((b) => b.toRadixString(16).padLeft(2, "0")).join("")',
    );
    buffer.writeln(
      '        .replaceFirstMapped(RegExp(r"(.{8})(.{4})(.{4})(.{4})(.{12})"), (m) => "\${m[1]}-\${m[2]}-\${m[3]}-\${m[4]}-\${m[5]}");',
    );
    buffer.writeln('  }');
  }
}
