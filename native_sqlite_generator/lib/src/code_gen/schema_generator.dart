import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:native_sqlite_generator/src/models/column_info.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Generates table schema code.
class SchemaGenerator {
  /// Generates the schema class for a table.
  String generate(TableInfo table) {
    final buffer = StringBuffer();

    buffer.writeln('// Table schema for ${table.dartName}');
    buffer.writeln('abstract class ${table.schemaClassName} {');
    buffer.writeln("  static const String tableName = '${table.sqlName}';");
    buffer.writeln();

    // Generate CREATE TABLE SQL
    buffer.writeln("  static const String createTableSql = '''");
    buffer.writeln(_generateCreateTableSql(table));
    buffer.writeln("  ''';");

    // Generate index SQL if any
    if (table.hasIndexes) {
      buffer.writeln();
      buffer.writeln('  static const List<String> indexSql = [');
      for (final index in table.indexes) {
        buffer.writeln("    '''${index.generateSql(table.sqlName)}''',");
      }
      buffer.writeln('  ];');
    }

    // Generate column name constants
    buffer.writeln();
    buffer.writeln('  // Column names');
    for (final column in table.columns) {
      final constantName = NamingUtils.getColumnConstantName(column.dartName);
      buffer.writeln(
          "  static const String $constantName = '${column.sqlName}';");
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates the CREATE TABLE SQL statement.
  String _generateCreateTableSql(TableInfo table) {
    final lines = <String>[];

    lines.add('    CREATE TABLE ${table.sqlName} (');

    // Generate column definitions
    final columnDefs = table.columns
        .map((column) => _generateColumnDefinition(column))
        .map((def) => '      $def')
        .toList();

    // Generate foreign key constraints
    final foreignKeys = table.columns
        .where((c) => c.hasForeignKey)
        .map((column) => _generateForeignKeyConstraint(column))
        .map((fk) => '      $fk')
        .toList();

    final allConstraints = [...columnDefs, ...foreignKeys];
    lines.add(allConstraints.join(',\n'));
    lines.add('    )');

    return lines.join('\n');
  }

  /// Generates a column definition.
  String _generateColumnDefinition(ColumnInfo column) {
    final parts = <String>[
      column.sqlName,
      column.sqlType.sqlName,
    ];

    if (column.isPrimaryKey) {
      parts.add('PRIMARY KEY');
      if (column.isAutoIncrement) {
        parts.add('AUTOINCREMENT');
      }
    }

    if (!column.isNullable && !column.isPrimaryKey) {
      parts.add('NOT NULL');
    }

    if (column.isUnique && !column.isPrimaryKey) {
      parts.add('UNIQUE');
    }

    if (column.defaultValue != null) {
      parts.add('DEFAULT ${column.defaultValue}');
    }

    return parts.join(' ');
  }

  /// Generates a foreign key constraint.
  String _generateForeignKeyConstraint(ColumnInfo column) {
    if (!column.hasForeignKey) return '';

    final parts = <String>[
      'FOREIGN KEY (${column.sqlName})',
      'REFERENCES ${column.foreignKeyTable}(${column.foreignKeyColumn})',
    ];

    if (column.foreignKeyOnDelete != null) {
      parts.add('ON DELETE ${column.foreignKeyOnDelete}');
    }

    if (column.foreignKeyOnUpdate != null) {
      parts.add('ON UPDATE ${column.foreignKeyOnUpdate}');
    }

    return parts.join(' ');
  }
}
