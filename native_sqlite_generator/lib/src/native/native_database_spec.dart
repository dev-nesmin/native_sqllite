import 'dart:convert';

import 'package:build/build.dart';
import 'package:native_sqlite_generator/src/migration/migration_steps.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// What the generated native DatabaseManagers need to open a database
/// exactly like the Dart one: the same version, create statements,
/// migration steps and repair statements.
class NativeDatabaseSpec {
  NativeDatabaseSpec({
    required this.databaseName,
    required this.schemaVersion,
    required this.tables,
    required this.migrations,
    required this.ensureSchema,
  });

  factory NativeDatabaseSpec.fromSchemaJson(
    String schemaJson, {
    required String databaseName,
  }) {
    final json = jsonDecode(schemaJson) as Map<String, dynamic>;
    final snapshotTables = MigrationSteps.tablesOf(schemaJson);
    return NativeDatabaseSpec(
      databaseName: databaseName,
      schemaVersion: json['schemaVersion'] as int,
      tables: _topologicalSort(snapshotTables),
      migrations: MigrationSteps.load(
        currentSchemaJson: schemaJson,
        onSkipped: (file) => log.warning(
          'Ignoring migrations in $file: written by an older generator '
          'whose migrations were never applied.',
        ),
      ),
      ensureSchema: MigrationSteps.ensureSchema(snapshotTables),
    );
  }

  static List<TableSchemaSnapshot> _topologicalSort(
    List<TableSchemaSnapshot> tables,
  ) {
    final byName = {for (final table in tables) table.tableName: table};
    final sorted = <TableSchemaSnapshot>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(TableSchemaSnapshot table) {
      if (visited.contains(table.tableName) ||
          visiting.contains(table.tableName)) {
        return;
      }
      visiting.add(table.tableName);
      for (final column in table.columns) {
        final reference = column.foreignKey;
        if (reference == null) continue;
        final referencedTable = byName[reference.split('.').first];
        if (referencedTable != null) visit(referencedTable);
      }
      visiting.remove(table.tableName);
      visited.add(table.tableName);
      sorted.add(table);
    }

    for (final table in tables) {
      visit(table);
    }
    return sorted;
  }

  final String databaseName;
  final int schemaVersion;
  final List<TableSchemaSnapshot> tables;
  final Map<int, List<String>> migrations;
  final List<String> ensureSchema;

  /// Applies an optional namespace to model-derived native types. SQL names,
  /// migration statements, and the Dart schema snapshot remain unchanged.
  NativeDatabaseSpec withNativeTypePrefix(String prefix) {
    if (prefix.isEmpty) return this;
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(prefix)) {
      throw FormatException(
        'native_type_prefix must be a valid Kotlin/Swift identifier prefix; '
        'got "$prefix".',
      );
    }

    return NativeDatabaseSpec(
      databaseName: databaseName,
      schemaVersion: schemaVersion,
      tables: [
        for (final table in tables)
          table.copyWith(
            className: '$prefix${table.className}',
            columns: [
              for (final column in table.columns)
                if (column.isEnum)
                  column.copyWithDartType(
                    '$prefix${column.dartType.replaceAll('?', '')}'
                    '${column.dartType.endsWith('?') ? '?' : ''}',
                  )
                else
                  column,
            ],
          ),
      ],
      migrations: migrations,
      ensureSchema: ensureSchema,
    );
  }
}
