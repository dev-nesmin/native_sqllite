import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/naming_conventions.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// Repairs schema snapshots written by generator versions whose schema
/// tracking ignored the naming options, so they recorded Dart names while the
/// real tables (created from the generated Dart schema) use converted names.
///
/// Without this, fixing the naming would look like every column was dropped
/// and re-added, and the generated migration would recreate tables and lose
/// data on devices.
class LegacySnapshotCorrection {
  LegacySnapshotCorrection(this.options);

  final GeneratorOptions options;

  /// Older generator versions built snapshots without applying
  /// `table_name_case`, so a table could be recorded under its class name.
  /// Returns the key of such a legacy entry for [current], if any.
  String? findLegacyTableKey(
    Map<String, Map<String, dynamic>> previousTables,
    TableSchemaSnapshot current,
  ) {
    final legacyName = current.className;
    final entry = previousTables[legacyName];
    if (entry == null || entry['className'] != current.className) return null;
    final conventional = options.tableNameCase == 'none'
        ? current.className
        : NamingConventions.format(current.className, options.tableNameCase);
    return conventional == current.tableName ? legacyName : null;
  }

  /// Older generator versions built snapshots without applying
  /// `column_name_case`, recording each column under its Dart name even
  /// though the real table (created from the generated Dart schema) uses the
  /// converted name. Rewrites such names to the current ones.
  ///
  /// A name is only corrected when it equals the Dart field name AND the
  /// current name is exactly what the naming convention produces for that
  /// field. Genuine renames (e.g. a new `@DbColumn(name: ...)`) don't match
  /// and are still detected as schema changes.
  ({Map<String, dynamic> schema, bool changed}) correct(
    Map<String, dynamic> previous,
    TableSchemaSnapshot current,
  ) {
    final currentByDartName = {for (final c in current.columns) c.dartName: c};
    final renames = <String, String>{};
    final columns = <Map<String, dynamic>>[];

    for (final raw in previous['columns'] as List) {
      final column = Map<String, dynamic>.from(raw as Map);
      final dartName = column['dartName'] as String;
      final oldName = column['name'] as String;
      final match = currentByDartName[dartName];
      if (match != null &&
          oldName != match.name &&
          oldName == dartName &&
          options.columnNameCase != 'none' &&
          NamingConventions.format(dartName, options.columnNameCase) ==
              match.name) {
        renames[oldName] = match.name;
        column['name'] = match.name;
      }
      columns.add(column);
    }

    final tableRenamed = previous['tableName'] != current.tableName;
    if (renames.isEmpty && !tableRenamed) {
      return (schema: previous, changed: false);
    }

    final indexes = [
      for (final raw in previous['indexes'] as List? ?? const [])
        {
          ...Map<String, dynamic>.from(raw as Map),
          'columns': [
            for (final c in (raw['columns'] as List).cast<String>())
              renames[c] ?? c,
          ],
        },
    ];

    return (
      schema: {
        ...previous,
        'tableName': current.tableName,
        'columns': columns,
        'indexes': indexes,
      },
      changed: true,
    );
  }
}
