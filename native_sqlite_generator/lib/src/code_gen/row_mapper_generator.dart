import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Generates the single row decoder shared by a table's repository and query
/// builder.
class RowMapperGenerator {
  String generate(TableInfo table) {
    final buffer = StringBuffer()
      ..writeln(
        '${table.dartName} ${table.rowMapperName}(Map<String, Object?> map) {',
      )
      ..writeln('  return ${table.dartName}(');

    for (final parameter in table.constructorParameters) {
      final column = parameter.column;
      final value = column.deserializeExpression("map['${column.sqlName}']");
      final prefix = parameter.isNamed ? '${column.dartName}: ' : '';
      buffer.writeln('    $prefix$value,');
    }

    buffer
      ..writeln('  );')
      ..writeln('}');
    return buffer.toString();
  }
}
