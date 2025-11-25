import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// Represents a schema change operation
enum SchemaChangeType {
  /// Table was created
  createTable,

  /// Table was dropped
  dropTable,

  /// Table was renamed
  renameTable,

  /// Column was added
  addColumn,

  /// Column was dropped
  dropColumn,

  /// Column was renamed
  renameColumn,

  /// Column type was changed
  modifyColumn,

  /// Index was added
  addIndex,

  /// Index was dropped
  dropIndex,
}

/// Represents a single schema change operation
class SchemaChange {
  final SchemaChangeType type;
  final String? tableName;
  final String? oldTableName;
  final String? newTableName;
  final ColumnSchemaSnapshot? column;
  final ColumnSchemaSnapshot? oldColumn;
  final ColumnSchemaSnapshot? newColumn;
  final IndexSchemaSnapshot? index;
  final String? description;

  const SchemaChange({
    required this.type,
    this.tableName,
    this.oldTableName,
    this.newTableName,
    this.column,
    this.oldColumn,
    this.newColumn,
    this.index,
    this.description,
  });

  @override
  String toString() {
    switch (type) {
      case SchemaChangeType.createTable:
        return 'CREATE TABLE $tableName';
      case SchemaChangeType.dropTable:
        return 'DROP TABLE $tableName';
      case SchemaChangeType.renameTable:
        return 'RENAME TABLE $oldTableName TO $newTableName';
      case SchemaChangeType.addColumn:
        return 'ADD COLUMN $tableName.${column?.name} ${column?.type}';
      case SchemaChangeType.dropColumn:
        return 'DROP COLUMN $tableName.${column?.name}';
      case SchemaChangeType.renameColumn:
        return 'RENAME COLUMN $tableName.${oldColumn?.name} TO ${newColumn?.name}';
      case SchemaChangeType.modifyColumn:
        return 'MODIFY COLUMN $tableName.${column?.name} ${column?.type}';
      case SchemaChangeType.addIndex:
        return 'CREATE INDEX ON $tableName (${index?.columns.join(", ")})';
      case SchemaChangeType.dropIndex:
        return 'DROP INDEX ON $tableName (${index?.columns.join(", ")})';
    }
  }
}

/// Compares schema snapshots and detects changes
class SchemaComparator {
  /// Compares two schema snapshots and returns the list of changes
  static List<SchemaChange> compareSchemas(
    TableSchemaSnapshot? oldSchema,
    TableSchemaSnapshot newSchema,
  ) {
    final changes = <SchemaChange>[];

    // If old schema is null, it's a new table
    if (oldSchema == null) {
      changes.add(SchemaChange(
        type: SchemaChangeType.createTable,
        tableName: newSchema.tableName,
        description: 'Create new table ${newSchema.tableName}',
      ));
      return changes;
    }

    // Check if table was renamed
    if (oldSchema.className == newSchema.className &&
        oldSchema.tableName != newSchema.tableName) {
      changes.add(SchemaChange(
        type: SchemaChangeType.renameTable,
        oldTableName: oldSchema.tableName,
        newTableName: newSchema.tableName,
        description:
            'Rename table ${oldSchema.tableName} to ${newSchema.tableName}',
      ));
    }

    // Compare columns
    changes.addAll(_compareColumns(oldSchema, newSchema));

    // Compare indexes
    changes.addAll(_compareIndexes(oldSchema, newSchema));

    return changes;
  }

  /// Compares columns between two schemas
  static List<SchemaChange> _compareColumns(
    TableSchemaSnapshot oldSchema,
    TableSchemaSnapshot newSchema,
  ) {
    final changes = <SchemaChange>[];
    final oldColumns = {for (var c in oldSchema.columns) c.name: c};
    final newColumns = {for (var c in newSchema.columns) c.name: c};

    // Find added columns
    for (final entry in newColumns.entries) {
      if (!oldColumns.containsKey(entry.key)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.addColumn,
          tableName: newSchema.tableName,
          column: entry.value,
          description:
              'Add column ${entry.value.name} ${entry.value.type} to ${newSchema.tableName}',
        ));
      }
    }

    // Find dropped columns
    for (final entry in oldColumns.entries) {
      if (!newColumns.containsKey(entry.key)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.dropColumn,
          tableName: newSchema.tableName,
          column: entry.value,
          description:
              'Drop column ${entry.value.name} from ${newSchema.tableName}',
        ));
      }
    }

    // Find modified columns
    for (final entry in newColumns.entries) {
      final oldColumn = oldColumns[entry.key];
      if (oldColumn != null) {
        final newColumn = entry.value;
        if (_isColumnModified(oldColumn, newColumn)) {
          changes.add(SchemaChange(
            type: SchemaChangeType.modifyColumn,
            tableName: newSchema.tableName,
            oldColumn: oldColumn,
            newColumn: newColumn,
            description:
                'Modify column ${newColumn.name} in ${newSchema.tableName}',
          ));
        }
      }
    }

    // Detect renamed columns (same dartName but different name)
    final oldByDartName = {for (var c in oldSchema.columns) c.dartName: c};
    final newByDartName = {for (var c in newSchema.columns) c.dartName: c};

    for (final entry in newByDartName.entries) {
      final oldColumn = oldByDartName[entry.key];
      final newColumn = entry.value;
      if (oldColumn != null && oldColumn.name != newColumn.name) {
        // This is a rename - remove the add/drop changes and add rename
        changes.removeWhere((c) =>
            c.type == SchemaChangeType.addColumn &&
                c.column?.name == newColumn.name ||
            c.type == SchemaChangeType.dropColumn &&
                c.column?.name == oldColumn.name);

        changes.add(SchemaChange(
          type: SchemaChangeType.renameColumn,
          tableName: newSchema.tableName,
          oldColumn: oldColumn,
          newColumn: newColumn,
          description:
              'Rename column ${oldColumn.name} to ${newColumn.name} in ${newSchema.tableName}',
        ));
      }
    }

    return changes;
  }

  /// Checks if a column has been modified
  static bool _isColumnModified(
    ColumnSchemaSnapshot oldColumn,
    ColumnSchemaSnapshot newColumn,
  ) {
    return oldColumn.type != newColumn.type ||
        oldColumn.nullable != newColumn.nullable ||
        oldColumn.primaryKey != newColumn.primaryKey ||
        oldColumn.autoIncrement != newColumn.autoIncrement ||
        oldColumn.unique != newColumn.unique ||
        oldColumn.defaultValue != newColumn.defaultValue ||
        oldColumn.foreignKey != newColumn.foreignKey ||
        oldColumn.isJsonField != newColumn.isJsonField ||
        oldColumn.hasConverter != newColumn.hasConverter;
  }

  /// Compares indexes between two schemas
  static List<SchemaChange> _compareIndexes(
    TableSchemaSnapshot oldSchema,
    TableSchemaSnapshot newSchema,
  ) {
    final changes = <SchemaChange>[];

    // Create a signature for each index (columns + unique)
    String indexSignature(IndexSchemaSnapshot idx) =>
        '${idx.columns.join(",")}_${idx.unique}';

    final oldIndexes = {
      for (var idx in oldSchema.indexes) indexSignature(idx): idx
    };
    final newIndexes = {
      for (var idx in newSchema.indexes) indexSignature(idx): idx
    };

    // Find added indexes
    for (final entry in newIndexes.entries) {
      if (!oldIndexes.containsKey(entry.key)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.addIndex,
          tableName: newSchema.tableName,
          index: entry.value,
          description:
              'Add index on ${newSchema.tableName} (${entry.value.columns.join(", ")})',
        ));
      }
    }

    // Find dropped indexes
    for (final entry in oldIndexes.entries) {
      if (!newIndexes.containsKey(entry.key)) {
        changes.add(SchemaChange(
          type: SchemaChangeType.dropIndex,
          tableName: newSchema.tableName,
          index: entry.value,
          description:
              'Drop index on ${newSchema.tableName} (${entry.value.columns.join(", ")})',
        ));
      }
    }

    return changes;
  }

  /// Checks if the changes require table recreation (SQLite limitation)
  static bool requiresTableRecreation(List<SchemaChange> changes) {
    return changes.any((change) =>
        change.type == SchemaChangeType.dropColumn ||
        change.type == SchemaChangeType.renameColumn ||
        change.type == SchemaChangeType.modifyColumn);
  }
}
