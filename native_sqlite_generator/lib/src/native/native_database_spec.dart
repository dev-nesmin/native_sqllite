import 'dart:convert';

import 'package:native_sqlite_generator/src/migration/migration_steps.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/utils/logger.dart';

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
    final tables = MigrationSteps.tablesOf(schemaJson);
    return NativeDatabaseSpec(
      databaseName: databaseName,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      tables: tables,
      migrations: MigrationSteps.load(
        currentSchemaJson: schemaJson,
        onSkipped: (file) => logger.warning(
          '⚠️  Ignoring migrations in $file: written by an older generator '
          'whose migrations were never applied.',
        ),
      ),
      ensureSchema: MigrationSteps.ensureSchema(tables),
    );
  }

  final String databaseName;
  final int schemaVersion;
  final List<TableSchemaSnapshot> tables;
  final Map<int, List<String>> migrations;
  final List<String> ensureSchema;
}
