import 'dart:convert';
import 'dart:io';

import 'package:native_sqlite_generator/src/migration/schema_comparator.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// Column mapping for data migration
class _ColumnMapping {
  final List<String> oldColumns;
  final List<String> newColumns;

  _ColumnMapping({required this.oldColumns, required this.newColumns});
}

/// Database-wide schema containing multiple tables
class DatabaseSchema {
  final String version;
  final DateTime generatedAt;
  final List<TableSchemaSnapshot> tables;

  DatabaseSchema({
    required this.version,
    required this.generatedAt,
    required this.tables,
  });

  factory DatabaseSchema.fromJson(Map<String, dynamic> json) {
    final tablesJson = json['tables'] as List;
    final tables = tablesJson
        .map((t) => TableSchemaSnapshot.fromJson(t as Map<String, dynamic>))
        .toList();

    return DatabaseSchema(
      version: json['version'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      tables: tables,
    );
  }
}

/// Generates migration SQL between schema versions
class MigrateCommand {
  final bool verbose;

  MigrateCommand(this.verbose);

  Future<void> execute(List<String> args) async {
    print('🔄 Generating migration...\n');

    // Parse arguments
    String? fromPath;
    String? toPath;
    String? outputPath;

    for (int i = 0; i < args.length; i++) {
      if (args[i] == '--from' && i + 1 < args.length) {
        fromPath = args[i + 1];
      } else if (args[i] == '--to' && i + 1 < args.length) {
        toPath = args[i + 1];
      } else if (args[i] == '--output' && i + 1 < args.length) {
        outputPath = args[i + 1];
      }
    }

    if (fromPath == null || toPath == null) {
      print('❌ Error: Missing required arguments\n');
      print('Usage: dart run native_sqlite_generator migrate \\');
      print('  --from <old-schema.json> \\');
      print('  --to <new-schema.json> \\');
      print('  --output <migration.sql> (optional)');
      print('');
      print('Example:');
      print('  dart run native_sqlite_generator migrate \\');
      print('    --from test_schemas/schema_v1.json \\');
      print('    --to test_schemas/schema_v2.json \\');
      print('    --output migrations/001_v1_to_v2.sql');
      exit(1);
    }

    try {
      // Load schemas
      final fromSchema = await _loadDatabaseSchema(fromPath);
      final toSchema = await _loadDatabaseSchema(toPath);

      if (fromSchema == null) {
        print('❌ Error: Could not load schema from: $fromPath\n');
        exit(1);
      }

      if (toSchema == null) {
        print('❌ Error: Could not load schema from: $toPath\n');
        exit(1);
      }

      if (verbose) {
        print(
            'From: ${fromSchema.version} (${fromSchema.tables.length} tables)');
        print('To:   ${toSchema.version} (${toSchema.tables.length} tables)');
        print('');
      }

      // Generate migration SQL
      final migrationSql = _generateDatabaseMigrationSql(fromSchema, toSchema);

      if (migrationSql.isEmpty) {
        print('✅ No changes detected!');
        print('');
        print('The schemas are identical.');
        return;
      }

      // Output
      if (outputPath != null) {
        final outputFile = File(outputPath);
        await outputFile.create(recursive: true);
        await outputFile.writeAsString(migrationSql);

        print('✅ Migration generated successfully!');
        print('');
        print('Output: $outputPath');
        print('From version: ${fromSchema.version}');
        print('To version:   ${toSchema.version}');
      } else {
        print('Generated Migration SQL:');
        print('═' * 60);
        print(migrationSql);
        print('═' * 60);
        print('');
        print('💡 Use --output to save to a file');
      }
    } catch (e, stackTrace) {
      print('❌ Error generating migration: $e');
      if (verbose) {
        print('');
        print('Stack trace:');
        print(stackTrace);
      }
      exit(1);
    }
  }

  Future<DatabaseSchema?> _loadDatabaseSchema(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DatabaseSchema.fromJson(json);
    } catch (e) {
      if (verbose) {
        print('⚠️  Error loading schema from $filePath: $e');
      }
      return null;
    }
  }

  String _generateDatabaseMigrationSql(
      DatabaseSchema fromSchema, DatabaseSchema toSchema) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // Header
    buffer.writeln('-- Migration generated: ${now.toIso8601String()}');
    buffer.writeln('-- From version: ${fromSchema.version}');
    buffer.writeln('-- To version:   ${toSchema.version}');
    buffer.writeln('');
    buffer.writeln(
        '-- =============================================================================');
    buffer.writeln('');

    // Begin transaction
    buffer.writeln('BEGIN TRANSACTION;');
    buffer.writeln('');

    // Compare tables
    final fromTables = {for (var t in fromSchema.tables) t.tableName: t};
    final toTables = {for (var t in toSchema.tables) t.tableName: t};

    // New tables
    for (final tableName in toTables.keys) {
      if (!fromTables.containsKey(tableName)) {
        buffer.writeln('-- Create new table: $tableName');
        buffer.writeln(_generateCreateTableSQL(toTables[tableName]!));
        buffer.writeln('');
      }
    }

    // Modified tables
    for (final tableName in fromTables.keys) {
      if (toTables.containsKey(tableName)) {
        final fromTable = fromTables[tableName]!;
        final toTable = toTables[tableName]!;
        final changes = SchemaComparator.compareSchemas(fromTable, toTable);

        if (changes.isNotEmpty) {
          buffer.writeln(
              '-- Update table: $tableName (${changes.length} changes)');
          buffer.writeln(_generateMigrationSql(changes, fromTable, toTable));
          buffer.writeln('');
        }
      }
    }

    // Dropped tables
    for (final tableName in fromTables.keys) {
      if (!toTables.containsKey(tableName)) {
        buffer.writeln('-- Drop table: $tableName');
        buffer.writeln('DROP TABLE IF EXISTS $tableName;');
        buffer.writeln('');
      }
    }

    // Commit transaction
    buffer.writeln('COMMIT;');

    return buffer.toString();
  }

  String _generateMigrationSql(
    List<SchemaChange> changes,
    TableSchemaSnapshot fromSchema,
    TableSchemaSnapshot toSchema,
  ) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // Header
    buffer.writeln('-- Migration generated: ${now.toIso8601String()}');
    buffer.writeln('-- From: ${fromSchema.tableName}');
    buffer.writeln('-- To:   ${toSchema.tableName}');
    buffer.writeln('-- Changes: ${changes.length}');
    buffer.writeln('');
    buffer.writeln(
        '-- =============================================================================');
    buffer.writeln('');

    // Check if table recreation is required
    final requiresRecreation =
        SchemaComparator.requiresTableRecreation(changes);

    if (requiresRecreation) {
      buffer
          .writeln('-- ⚠️  WARNING: This migration requires table recreation');
      buffer.writeln(
          '-- Data will be preserved but this operation cannot be easily rolled back');
      buffer.writeln('');
    }

    // Begin transaction
    buffer.writeln('BEGIN TRANSACTION;');
    buffer.writeln('');

    // If recreation is needed, do it all at once
    if (requiresRecreation) {
      buffer
          .writeln(_generateTableRecreationSQL(fromSchema, toSchema, changes));
    } else {
      // Generate SQL for each change
      for (final change in changes) {
        buffer.writeln('-- ${change.description ?? change.toString()}');
        buffer.writeln(_generateChangeSQL(change, fromSchema, toSchema));
        buffer.writeln('');
      }
    }

    // Commit transaction
    buffer.writeln('COMMIT;');
    buffer.writeln('');
    buffer.writeln('-- Migration complete');

    return buffer.toString();
  }

  /// Generates SQL for table recreation (required for DROP COLUMN, RENAME COLUMN, etc.)
  String _generateTableRecreationSQL(
    TableSchemaSnapshot fromSchema,
    TableSchemaSnapshot toSchema,
    List<SchemaChange> changes,
  ) {
    final buffer = StringBuffer();
    final tempTableName = '${toSchema.tableName}_new';

    buffer.writeln('-- Recreate table with new schema');
    buffer.writeln('');

    // 1. Create new table with new schema
    buffer.writeln('-- Step 1: Create new table');
    buffer.writeln(_generateCreateTableSQL(toSchema, tempTableName));
    buffer.writeln('');

    // 2. Copy data from old table to new table
    buffer.writeln('-- Step 2: Copy data');
    final columnMapping = _buildColumnMapping(fromSchema, toSchema, changes);
    buffer.writeln(
        'INSERT INTO $tempTableName (${columnMapping.newColumns.join(', ')})');
    buffer.writeln('  SELECT ${columnMapping.oldColumns.join(', ')}');
    buffer.writeln('  FROM ${fromSchema.tableName};');
    buffer.writeln('');

    // 3. Drop old table
    buffer.writeln('-- Step 3: Drop old table');
    buffer.writeln('DROP TABLE ${fromSchema.tableName};');
    buffer.writeln('');

    // 4. Rename new table
    buffer.writeln('-- Step 4: Rename new table');
    buffer
        .writeln('ALTER TABLE $tempTableName RENAME TO ${toSchema.tableName};');
    buffer.writeln('');

    // 5. Recreate indexes
    if (toSchema.indexes.isNotEmpty) {
      buffer.writeln('-- Step 5: Recreate indexes');
      for (final index in toSchema.indexes) {
        buffer.writeln(_generateAddIndexSQL(SchemaChange(
          type: SchemaChangeType.addIndex,
          tableName: toSchema.tableName,
          index: index,
        )));
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Builds column mapping for data migration
  _ColumnMapping _buildColumnMapping(
    TableSchemaSnapshot fromSchema,
    TableSchemaSnapshot toSchema,
    List<SchemaChange> changes,
  ) {
    final oldColumns = <String>[];
    final newColumns = <String>[];

    final renames = <String, String>{};
    for (final change in changes) {
      if (change.type == SchemaChangeType.renameColumn) {
        renames[change.oldColumn!.name] = change.newColumn!.name;
      }
    }

    for (final newColumn in toSchema.columns) {
      // Find corresponding old column
      final oldColumnName = renames.entries
          .firstWhere(
            (e) => e.value == newColumn.name,
            orElse: () => MapEntry(newColumn.name, newColumn.name),
          )
          .key;

      final oldColumn = fromSchema.columns.firstWhere(
        (c) => c.name == oldColumnName,
        orElse: () => fromSchema.columns.firstWhere(
          (c) => c.dartName == newColumn.dartName,
          orElse: () => newColumn, // New column, use default
        ),
      );

      newColumns.add(newColumn.name);

      if (oldColumn == newColumn ||
          fromSchema.columns.any((c) => c.name == oldColumnName)) {
        oldColumns.add(oldColumnName);
      } else {
        // New column - use default value
        if (newColumn.defaultValue != null) {
          oldColumns.add(newColumn.defaultValue!);
        } else if (newColumn.nullable) {
          oldColumns.add('NULL');
        } else {
          // Use type default
          oldColumns.add(_getTypeDefault(newColumn.type));
        }
      }
    }

    return _ColumnMapping(oldColumns: oldColumns, newColumns: newColumns);
  }

  String _getTypeDefault(String type) {
    switch (type.toUpperCase()) {
      case 'INTEGER':
        return '0';
      case 'REAL':
        return '0.0';
      case 'TEXT':
        return "''";
      case 'BLOB':
        return 'NULL';
      default:
        return 'NULL';
    }
  }

  String _generateChangeSQL(
    SchemaChange change,
    TableSchemaSnapshot fromSchema,
    TableSchemaSnapshot toSchema,
  ) {
    switch (change.type) {
      case SchemaChangeType.createTable:
        return _generateCreateTableSQL(toSchema);

      case SchemaChangeType.dropTable:
        return 'DROP TABLE IF EXISTS ${change.tableName};';

      case SchemaChangeType.renameTable:
        return 'ALTER TABLE ${change.oldTableName} RENAME TO ${change.newTableName};';

      case SchemaChangeType.addColumn:
        return _generateAddColumnSQL(change);

      case SchemaChangeType.dropColumn:
        return _generateDropColumnSQL(change, fromSchema);

      case SchemaChangeType.renameColumn:
        return _generateRenameColumnSQL(change, fromSchema);

      case SchemaChangeType.modifyColumn:
        return _generateModifyColumnSQL(change, fromSchema);

      case SchemaChangeType.addIndex:
        return _generateAddIndexSQL(change);

      case SchemaChangeType.dropIndex:
        return _generateDropIndexSQL(change);
    }
  }

  String _generateCreateTableSQL(TableSchemaSnapshot schema,
      [String? tableName]) {
    final buffer = StringBuffer();
    final name = tableName ?? schema.tableName;
    buffer.writeln('CREATE TABLE IF NOT EXISTS $name (');

    final columnDefs = <String>[];
    for (final column in schema.columns) {
      final parts = <String>[
        column.name,
        column.type,
      ];

      if (column.primaryKey) {
        parts.add('PRIMARY KEY');
        if (column.autoIncrement) {
          parts.add('AUTOINCREMENT');
        }
      }

      if (!column.nullable && !column.primaryKey) {
        parts.add('NOT NULL');
      }

      if (column.unique) {
        parts.add('UNIQUE');
      }

      if (column.defaultValue != null) {
        parts.add('DEFAULT ${column.defaultValue}');
      }

      columnDefs.add('  ${parts.join(' ')}');
    }

    buffer.writeln(columnDefs.join(',\n'));
    buffer.write(');');

    return buffer.toString();
  }

  String _generateAddColumnSQL(SchemaChange change) {
    if (change.column == null || change.tableName == null) {
      return '-- Error: Missing column information';
    }

    final column = change.column!;
    final parts = <String>[
      column.name,
      column.type,
    ];

    if (!column.nullable) {
      // If NOT NULL, need a default value for existing rows
      if (column.defaultValue != null) {
        parts.add('NOT NULL');
        parts.add('DEFAULT ${column.defaultValue}');
      } else {
        parts.add('DEFAULT NULL');
      }
    }

    return 'ALTER TABLE ${change.tableName} ADD COLUMN ${parts.join(' ')};';
  }

  String _generateDropColumnSQL(
      SchemaChange change, TableSchemaSnapshot schema) {
    // SQLite doesn't support DROP COLUMN before version 3.35.0
    // Need to recreate the table without the column
    final buffer = StringBuffer();

    buffer.writeln('-- SQLite: Drop column by recreating table');
    buffer.writeln('CREATE TABLE ${change.tableName}_new AS');
    buffer.writeln(
        '  SELECT ${_getColumnsExcept(schema, change.column?.name ?? '')}');
    buffer.writeln('  FROM ${change.tableName};');
    buffer.writeln('DROP TABLE ${change.tableName};');
    buffer.write(
        'ALTER TABLE ${change.tableName}_new RENAME TO ${change.tableName};');

    return buffer.toString();
  }

  String _generateRenameColumnSQL(
      SchemaChange change, TableSchemaSnapshot schema) {
    return 'ALTER TABLE ${change.tableName} RENAME COLUMN ${change.oldColumn?.name} TO ${change.newColumn?.name};';
  }

  String _generateModifyColumnSQL(
      SchemaChange change, TableSchemaSnapshot schema) {
    // SQLite doesn't support MODIFY COLUMN
    // Need to recreate the table
    final buffer = StringBuffer();

    buffer.writeln('-- SQLite: Modify column by recreating table');
    buffer
        .writeln('-- TODO: Implement table recreation for column type change');
    buffer.write(
        '-- Changing ${change.column?.name} type in ${change.tableName}');

    return buffer.toString();
  }

  String _generateAddIndexSQL(SchemaChange change) {
    if (change.index == null || change.tableName == null) {
      return '-- Error: Missing index information';
    }

    final index = change.index!;
    final indexName = 'idx_${change.tableName}_${index.columns.join('_')}';

    final uniqueClause = index.unique ? 'UNIQUE ' : '';
    return 'CREATE ${uniqueClause}INDEX IF NOT EXISTS $indexName ON ${change.tableName} (${index.columns.join(', ')});';
  }

  String _generateDropIndexSQL(SchemaChange change) {
    if (change.index == null) {
      return '-- Error: Missing index information';
    }

    final index = change.index!;
    final indexName = 'idx_${change.tableName}_${index.columns.join('_')}';

    return 'DROP INDEX IF EXISTS $indexName;';
  }

  String _getColumnsExcept(TableSchemaSnapshot schema, String excludeColumn) {
    return schema.columns
        .where((c) => c.name != excludeColumn)
        .map((c) => c.name)
        .join(', ');
  }
}
