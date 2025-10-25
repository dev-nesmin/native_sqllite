import 'native_generator.dart';

/// Generates Kotlin code for Android
class NativeKotlinGenerator {
  final String packageName;
  final String databaseName;
  final bool includeExamples;

  NativeKotlinGenerator({
    required this.packageName,
    required this.databaseName,
    required this.includeExamples,
  });

  String generateSchema(TableModel model) {
    final buffer = StringBuffer();

    buffer.writeln('package $packageName');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Schema constants for ${model.className} table.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' * Generated from: lib/models/${_toSnakeCase(model.className)}.dart');
    buffer.writeln(' */');
    buffer.writeln('object ${model.className}Schema {');
    buffer.writeln('    const val TABLE_NAME = "${model.tableName}"');
    buffer.writeln();
    buffer.writeln('    // Column names');

    for (final field in model.fields) {
      final constantName = _toScreamingSnakeCase(field.fieldName);
      buffer.writeln('    const val $constantName = "${field.columnName}"');
    }

    buffer.writeln();
    buffer.writeln('    // CREATE TABLE SQL');
    buffer.writeln('    const val CREATE_TABLE_SQL = """');
    buffer.write('        CREATE TABLE ${model.tableName} (');

    final columnDefs = <String>[];
    for (final field in model.fields) {
      final parts = <String>[field.columnName, field.sqlType];

      if (field.isPrimaryKey) {
        parts.add('PRIMARY KEY');
        if (field.autoIncrement) {
          parts.add('AUTOINCREMENT');
        }
      }

      if (!field.isNullable && !field.isPrimaryKey) {
        parts.add('NOT NULL');
      }

      if (field.isUnique && !field.isPrimaryKey) {
        parts.add('UNIQUE');
      }

      columnDefs.add(parts.join(' '));
    }

    buffer.write('\n');
    buffer.write(columnDefs.map((def) => '            $def').join(',\n'));
    buffer.writeln('\n        )');
    buffer.writeln('    """.trimIndent()');
    buffer.writeln('}');

    return buffer.toString();
  }

  String generateHelper(TableModel model) {
    final buffer = StringBuffer();
    final primaryKey = model.fields.firstWhere(
      (f) => f.isPrimaryKey,
      orElse: () => model.fields.first,
    );

    buffer.writeln('package $packageName');
    buffer.writeln();
    buffer.writeln('import android.content.ContentValues');
    buffer.writeln('import dev.nesmin.native_sqlite.NativeSqliteManager');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Data class for ${model.className}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('data class ${model.className}(');

    final params = <String>[];
    for (final field in model.fields) {
      final kotlinType = _getKotlinType(field);
      final defaultValue = field.isPrimaryKey && field.autoIncrement ? ' = null' : '';
      params.add('    val ${field.fieldName}: $kotlinType$defaultValue');
    }
    buffer.writeln(params.join(',\n'));
    buffer.writeln(')');
    buffer.writeln();

    buffer.writeln('/**');
    buffer.writeln(' * Helper class for ${model.className} CRUD operations.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    if (includeExamples) {
      buffer.writeln(' *');
      buffer.writeln(' * Example usage:');
      buffer.writeln(' * ```');
      buffer.writeln(' * val helper = ${model.className}Helper("$databaseName")');
      buffer.writeln(' * val id = helper.insert(${model.className}(...))');
      buffer.writeln(' * val item = helper.findById(id)');
      buffer.writeln(' * ```');
    }
    buffer.writeln(' */');
    buffer.writeln('class ${model.className}Helper(private val databaseName: String) {');
    buffer.writeln();

    // Insert method
    buffer.writeln('    fun insert(entity: ${model.className}): Long {');
    buffer.writeln('        val values = ContentValues().apply {');
    for (final field in model.fields) {
      if (field.isPrimaryKey && field.autoIncrement) continue;

      final value = _serializeKotlin(field, 'entity.${field.fieldName}');
      buffer.writeln('            put(${model.className}Schema.${_toScreamingSnakeCase(field.fieldName)}, $value)');
    }
    buffer.writeln('        }');
    buffer.writeln('        return NativeSqliteManager.insert(databaseName, ${model.className}Schema.TABLE_NAME, values)');
    buffer.writeln('    }');
    buffer.writeln();

    // FindById method
    buffer.writeln('    fun findById(id: Long): ${model.className}? {');
    buffer.writeln('        val result = NativeSqliteManager.query(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            "SELECT * FROM \${${model.className}Schema.TABLE_NAME} WHERE \${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.fieldName)}} = ? LIMIT 1",');
    buffer.writeln('            listOf(id)');
    buffer.writeln('        )');
    buffer.writeln('        val rows = result["rows"] as? List<List<Any?>> ?: return null');
    buffer.writeln('        if (rows.isEmpty()) return null');
    buffer.writeln('        val columns = result["columns"] as List<String>');
    buffer.writeln('        return fromRow(columns, rows[0])');
    buffer.writeln('    }');
    buffer.writeln();

    // FindAll method
    buffer.writeln('    fun findAll(): List<${model.className}> {');
    buffer.writeln('        val result = NativeSqliteManager.query(databaseName, "SELECT * FROM \${${model.className}Schema.TABLE_NAME}")');
    buffer.writeln('        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()');
    buffer.writeln('        val columns = result["columns"] as List<String>');
    buffer.writeln('        return rows.map { fromRow(columns, it) }');
    buffer.writeln('    }');
    buffer.writeln();

    // FromRow helper
    buffer.writeln('    private fun fromRow(columns: List<String>, row: List<Any?>): ${model.className} {');
    buffer.writeln('        val columnMap = columns.withIndex().associate { it.value to it.index }');
    buffer.writeln('        return ${model.className}(');

    final fieldInits = <String>[];
    for (final field in model.fields) {
      final value = _deserializeKotlin(field, 'row[columnMap[${model.className}Schema.${_toScreamingSnakeCase(field.fieldName)}]!!]');
      fieldInits.add('            ${field.fieldName} = $value');
    }
    buffer.writeln(fieldInits.join(',\n'));
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getKotlinType(FieldModel field) {
    final baseType = field.dartType.replaceAll('?', '');
    String kotlinType;

    if (baseType == 'int' || baseType == 'Int' || baseType == 'DateTime') {
      kotlinType = 'Long';
    } else if (baseType == 'double' || baseType == 'Double') {
      kotlinType = 'Double';
    } else if (baseType == 'String') {
      kotlinType = 'String';
    } else if (baseType == 'bool') {
      kotlinType = 'Boolean';
    } else {
      kotlinType = 'Any';
    }

    return field.isNullable ? '$kotlinType?' : kotlinType;
  }

  String _serializeKotlin(FieldModel field, String accessor) {
    if (field.dartType.contains('bool')) {
      return field.isNullable
          ? '$accessor?.let { if (it) 1 else 0 }'
          : 'if ($accessor) 1 else 0';
    }
    return accessor;
  }

  String _deserializeKotlin(FieldModel field, String accessor) {
    final baseType = field.dartType.replaceAll('?', '');

    if (baseType == 'int' || baseType == 'Int' || baseType == 'DateTime') {
      return '$accessor as Long${field.isNullable ? "?" : ""}';
    } else if (baseType == 'double' || baseType == 'Double') {
      return '$accessor as Double${field.isNullable ? "?" : ""}';
    } else if (baseType == 'String') {
      return '$accessor as String${field.isNullable ? "?" : ""}';
    } else if (baseType == 'bool') {
      return field.isNullable
          ? '($accessor as? Long)?.let { it == 1L }'
          : '($accessor as Long) == 1L';
    }
    return accessor;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _toScreamingSnakeCase(String input) {
    return _toSnakeCase(input).toUpperCase();
  }
}
