import 'dart:convert';
import 'dart:io';

import 'package:native_sqlite_generator/src/migration/schema_tracking_builder.dart'
    show migrationFormat;
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';

/// The migration data embedded in generated database managers (Dart, Kotlin
/// and Swift), built from the schema snapshots so every platform upgrades a
/// database identically.
class MigrationSteps {
  MigrationSteps._();

  /// Versioned steps (`steps[v]` upgrades version `v - 1` to `v`) from the
  /// snapshots in [schemasDirectory], with the current version's step taken
  /// from [currentSchemaJson] (the build's native_sqlite_schema.json).
  ///
  /// Snapshots written before [migrationFormat] are skipped: their SQL was
  /// never applied at runtime and may reference wrong column names.
  /// [onSkipped] receives the name of each skipped file that had SQL.
  static Map<int, List<String>> load({
    required String? currentSchemaJson,
    String schemasDirectory = 'lib/generated/schemas',
    void Function(String file)? onSkipped,
  }) {
    final steps = <int, List<String>>{};

    void add(Map<String, dynamic> schema, String source) {
      final version = schema['schemaVersion'] as int?;
      final migrations = schema['migrations'] as List? ?? const [];
      if (version == null || migrations.isEmpty) return;
      if (schema['migrationFormat'] != migrationFormat) {
        onSkipped?.call(source);
        return;
      }
      steps[version] = [
        for (final migration in migrations.cast<Map<String, dynamic>>())
          ...(migration['sql'] as List).cast<String>(),
      ];
    }

    final directory = Directory(schemasDirectory);
    if (directory.existsSync()) {
      for (final file in directory.listSync().whereType<File>()) {
        if (!file.path.endsWith('.json')) continue;
        add(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          file.uri.pathSegments.last,
        );
      }
    }
    if (currentSchemaJson != null) {
      add(
        jsonDecode(currentSchemaJson) as Map<String, dynamic>,
        'native_sqlite_schema.json',
      );
    }

    return Map.fromEntries(
      steps.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Idempotent statements run after every upgrade: create any table or
  /// index of the current schema that is missing (e.g. databases upgraded
  /// by generator versions whose migrations never ran).
  static List<String> ensureSchema(List<TableSchemaSnapshot> tables) {
    return [
      for (final table in tables)
        SchemaSql.createTable(table, ifNotExists: true),
      for (final table in tables)
        ...SchemaSql.createIndexes(table, ifNotExists: true),
    ];
  }

  /// Table snapshots of a native_sqlite_schema.json document.
  static List<TableSchemaSnapshot> tablesOf(String schemaJson) {
    final schemas =
        (jsonDecode(schemaJson) as Map<String, dynamic>)['schemas'] as List? ??
        const [];
    return [
      for (final schema in schemas.cast<Map<String, dynamic>>())
        TableSchemaSnapshot.fromJson(schema),
    ];
  }
}
