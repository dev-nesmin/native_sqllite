/// Wraps a SQL identifier in double-quotes to prevent keyword conflicts and
/// injection through schema-derived names.
String _q(String identifier) => '"$identifier"';

/// Generates SQL migration statements by comparing old and new schemas
class MigrationSqlGenerator {
  /// Generate migration SQL for a table that changed
  static List<String> generateMigrationSql({
    required String tableName,
    required Map<String, dynamic> oldSchema,
    required Map<String, dynamic> newSchema,
  }) {
    final migrations = <String>[];

    final oldColumns = _parseColumns(oldSchema);
    final newColumns = _parseColumns(newSchema);

    // Detect column changes
    final oldColumnNames = oldColumns.keys.toSet();
    final newColumnNames = newColumns.keys.toSet();

    final addedColumns = newColumnNames.difference(oldColumnNames);
    final removedColumns = oldColumnNames.difference(newColumnNames);
    final commonColumns = oldColumnNames.intersection(newColumnNames);

    // Check for type/constraint changes in common columns
    final modifiedColumns = <String>[];
    for (final colName in commonColumns) {
      if (_columnChanged(oldColumns[colName]!, newColumns[colName]!)) {
        modifiedColumns.add(colName);
      }
    }

    // Simple case: Only adding nullable columns (can use ALTER TABLE ADD COLUMN)
    if (removedColumns.isEmpty &&
        modifiedColumns.isEmpty &&
        addedColumns.isNotEmpty) {
      for (final colName in addedColumns) {
        final col = newColumns[colName]!;
        if (col['nullable'] == true || col['defaultValue'] != null) {
          final sql = _generateAddColumnSql(tableName, col);
          migrations.add(sql);
        } else {
          // Non-nullable without default requires table recreation
          return _generateTableRecreationSql(
            tableName,
            oldColumns,
            newColumns,
            removedColumns,
          );
        }
      }
      return migrations;
    }

    // Complex case: Removals, modifications, or non-nullable additions
    // Requires table recreation
    if (removedColumns.isNotEmpty || modifiedColumns.isNotEmpty) {
      return _generateTableRecreationSql(
        tableName,
        oldColumns,
        newColumns,
        removedColumns,
      );
    }

    return migrations;
  }

  static Map<String, Map<String, dynamic>> _parseColumns(
    Map<String, dynamic> schema,
  ) {
    final columns = <String, Map<String, dynamic>>{};
    if (schema['columns'] is List) {
      for (final col in schema['columns'] as List) {
        final colMap = col as Map<String, dynamic>;
        final name = colMap['name'] as String;
        columns[name] = colMap;
      }
    }
    return columns;
  }

  static bool _columnChanged(
    Map<String, dynamic> oldCol,
    Map<String, dynamic> newCol,
  ) {
    return oldCol['type'] != newCol['type'] ||
        oldCol['nullable'] != newCol['nullable'] ||
        oldCol['primaryKey'] != newCol['primaryKey'] ||
        oldCol['unique'] != newCol['unique'] ||
        oldCol['defaultValue'] != newCol['defaultValue'];
  }

  static String _generateAddColumnSql(
    String tableName,
    Map<String, dynamic> column,
  ) {
    final colName = column['name'] as String;
    final colType = column['type'] as String;
    final nullable = column['nullable'] as bool? ?? true;
    final defaultValue = column['defaultValue'] as String?;

    final parts = <String>[
      'ALTER TABLE ${_q(tableName)} ADD COLUMN ${_q(colName)} $colType',
    ];

    if (!nullable) {
      parts.add('NOT NULL');
    }

    if (defaultValue != null) {
      parts.add('DEFAULT $defaultValue');
    }

    return '${parts.join(' ')};';
  }

  static List<String> _generateTableRecreationSql(
    String tableName,
    Map<String, Map<String, dynamic>> oldColumns,
    Map<String, Map<String, dynamic>> newColumns,
    Set<String> removedColumns,
  ) {
    final migrations = <String>[];

    // 1. Create new table with temporary name
    final newTableSql = _buildCreateTableSql('${tableName}_new', newColumns);
    migrations.add(newTableSql);

    // 2. Copy data from old table to new table (only common columns)
    final commonColumns = oldColumns.keys
        .where(
          (col) => newColumns.containsKey(col) && !removedColumns.contains(col),
        )
        .toList();

    if (commonColumns.isNotEmpty) {
      final columnsList = commonColumns.map(_q).join(', ');
      migrations.add(
        'INSERT INTO ${_q('${tableName}_new')} ($columnsList) '
        'SELECT $columnsList FROM ${_q(tableName)};',
      );
    }

    // 3. Drop old table
    migrations.add('DROP TABLE ${_q(tableName)};');

    // 4. Rename new table to original name
    migrations.add(
      'ALTER TABLE ${_q('${tableName}_new')} RENAME TO ${_q(tableName)};',
    );

    return migrations;
  }

  static String _buildCreateTableSql(
    String tableName,
    Map<String, Map<String, dynamic>> columns,
  ) {
    final columnDefs = <String>[];

    for (final col in columns.values) {
      final parts = <String>[];
      final colName = col['name'] as String;
      final colType = col['type'] as String;

      parts.add('${_q(colName)} $colType');

      if (col['primaryKey'] == true) {
        parts.add('PRIMARY KEY');
        if (col['autoIncrement'] == true) {
          parts.add('AUTOINCREMENT');
        }
      }

      if (col['nullable'] == false && col['primaryKey'] != true) {
        parts.add('NOT NULL');
      }

      if (col['unique'] == true && col['primaryKey'] != true) {
        parts.add('UNIQUE');
      }

      if (col['defaultValue'] != null) {
        parts.add('DEFAULT ${col['defaultValue']}');
      }

      if (col['foreignKey'] != null) {
        final fkParts = (col['foreignKey'] as String).split('.');
        if (fkParts.length == 2) {
          var fkClause = 'REFERENCES ${_q(fkParts[0])}(${_q(fkParts[1])})';
          final onDelete = col['foreignKeyOnDelete'] as String?;
          final onUpdate = col['foreignKeyOnUpdate'] as String?;
          if (onDelete != null) fkClause += ' ON DELETE $onDelete';
          if (onUpdate != null) fkClause += ' ON UPDATE $onUpdate';
          parts.add(fkClause);
        }
      }

      columnDefs.add(parts.join(' '));
    }

    return 'CREATE TABLE ${_q(tableName)} (${columnDefs.join(', ')});';
  }

  /// Generate user-friendly migration summary
  static String generateMigrationSummary({
    required String tableName,
    required Map<String, dynamic> oldSchema,
    required Map<String, dynamic> newSchema,
  }) {
    final oldColumns = _parseColumns(oldSchema);
    final newColumns = _parseColumns(newSchema);

    final oldColumnNames = oldColumns.keys.toSet();
    final newColumnNames = newColumns.keys.toSet();

    final addedColumns = newColumnNames.difference(oldColumnNames);
    final removedColumns = oldColumnNames.difference(newColumnNames);

    final changes = <String>[];

    if (addedColumns.isNotEmpty) {
      changes.add('Added columns: ${addedColumns.join(", ")}');
    }

    if (removedColumns.isNotEmpty) {
      changes.add('Removed columns: ${removedColumns.join(", ")}');
    }

    // Check for type changes
    for (final colName in oldColumnNames.intersection(newColumnNames)) {
      final oldCol = oldColumns[colName]!;
      final newCol = newColumns[colName]!;

      if (oldCol['type'] != newCol['type']) {
        changes.add(
          'Changed $colName type: ${oldCol['type']} → ${newCol['type']}',
        );
      }

      if (oldCol['nullable'] != newCol['nullable']) {
        final nullStr = newCol['nullable'] == true ? 'nullable' : 'NOT NULL';
        changes.add('Changed $colName to $nullStr');
      }
    }

    return changes.isEmpty ? 'Schema updated' : changes.join('; ');
  }
}
