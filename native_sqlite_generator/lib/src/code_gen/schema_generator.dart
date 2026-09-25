import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';

/// Generates table schema code.
class SchemaGenerator {
  /// Generates the schema class for a table.
  String generate(TableInfo table) {
    final buffer = StringBuffer();
    final snapshot = SchemaSnapshotHelper.createSnapshot(table, 0);

    buffer.writeln('/// Generated table schema for [${table.dartName}].');
    buffer.writeln('///');
    buffer.writeln(
      '/// Regenerate with `flutter pub run build_runner build` after changing the model.',
    );
    buffer.writeln('abstract class ${table.schemaClassName} {');
    buffer.writeln(
      '  static const String tableName = ${_dartString(table.sqlName)};',
    );
    buffer.writeln();

    // Generate CREATE TABLE SQL
    buffer.writeln(
      '  static const String createTableSql = '
      '${_dartString(SchemaSql.createTable(snapshot))};',
    );

    // Generate index SQL if any
    if (table.hasIndexes) {
      buffer.writeln();
      buffer.writeln('  static const List<String> indexSql = [');
      for (final sql in SchemaSql.createIndexes(snapshot)) {
        buffer.writeln('    ${_dartString(sql)},');
      }
      buffer.writeln('  ];');
    }

    // Generate column name constants
    buffer.writeln();
    buffer.writeln('  // Column names');
    for (final column in table.columns) {
      final constantName = NamingUtils.getColumnConstantName(column.dartName);
      buffer.writeln(
        '  static const String $constantName = '
        '${_dartString(column.sqlName)};',
      );
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _dartString(String value) {
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll(r'$', r'\$');
    return "'$escaped'";
  }
}
