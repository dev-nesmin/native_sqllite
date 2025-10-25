import 'native_generator.dart';

/// Generates Swift code for iOS
class NativeSwiftGenerator {
  final String databaseName;
  final bool includeExamples;

  NativeSwiftGenerator({
    required this.databaseName,
    required this.includeExamples,
  });

  String generateSchema(TableModel model) {
    final buffer = StringBuffer();

    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Schema constants for ${model.className} table.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' * Generated from: lib/models/${_toSnakeCase(model.className)}.dart');
    buffer.writeln(' */');
    buffer.writeln('public enum ${model.className}Schema {');
    buffer.writeln('    public static let tableName = "${model.tableName}"');
    buffer.writeln();
    buffer.writeln('    // Column names');

    for (final field in model.fields) {
      final constantName = _toCamelCase(field.fieldName);
      buffer.writeln('    public static let $constantName = "${field.columnName}"');
    }

    buffer.writeln();
    buffer.writeln('    // CREATE TABLE SQL');
    buffer.writeln('    public static let createTableSql = """');
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
    buffer.writeln('        """');
    buffer.writeln('}');

    return buffer.toString();
  }

  String generateHelper(TableModel model) {
    final buffer = StringBuffer();
    final primaryKey = model.fields.firstWhere(
      (f) => f.isPrimaryKey,
      orElse: () => model.fields.first,
    );

    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Struct for ${model.className}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('public struct ${model.className} {');

    for (final field in model.fields) {
      final swiftType = _getSwiftType(field);
      buffer.writeln('    public let ${field.fieldName}: $swiftType');
    }

    buffer.writeln();
    buffer.writeln('    public init(');
    final initParams = <String>[];
    for (final field in model.fields) {
      final swiftType = _getSwiftType(field);
      final defaultValue = field.isPrimaryKey && field.autoIncrement ? ' = nil' : '';
      initParams.add('        ${field.fieldName}: $swiftType$defaultValue');
    }
    buffer.writeln(initParams.join(',\n'));
    buffer.writeln('    ) {');

    for (final field in model.fields) {
      buffer.writeln('        self.${field.fieldName} = ${field.fieldName}');
    }

    buffer.writeln('    }');
    buffer.writeln('}');
    buffer.writeln();

    buffer.writeln('/**');
    buffer.writeln(' * Helper class for ${model.className} CRUD operations.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    if (includeExamples) {
      buffer.writeln(' *');
      buffer.writeln(' * Example usage:');
      buffer.writeln(' * ```');
      buffer.writeln(' * let helper = ${model.className}Helper(databaseName: "$databaseName")');
      buffer.writeln(' * let id = try helper.insert(${model.className}(...))');
      buffer.writeln(' * let item = try helper.findById(id)');
      buffer.writeln(' * ```');
    }
    buffer.writeln(' */');
    buffer.writeln('public class ${model.className}Helper {');
    buffer.writeln('    private let databaseName: String');
    buffer.writeln('    private let manager = NativeSqliteManager.shared');
    buffer.writeln();
    buffer.writeln('    public init(databaseName: String) {');
    buffer.writeln('        self.databaseName = databaseName');
    buffer.writeln('    }');
    buffer.writeln();

    // Insert method
    buffer.writeln('    public func insert(_ entity: ${model.className}) throws -> Int {');
    buffer.writeln('        var values: [String: Any] = [:]');
    for (final field in model.fields) {
      if (field.isPrimaryKey && field.autoIncrement) continue;

      final value = _serializeSwift(field, 'entity.${field.fieldName}');
      buffer.writeln('        values[${model.className}Schema.${_toCamelCase(field.fieldName)}] = $value');
    }
    buffer.writeln('        return try manager.insert(name: databaseName, table: ${model.className}Schema.tableName, values: values)');
    buffer.writeln('    }');
    buffer.writeln();

    // FindById method
    buffer.writeln('    public func findById(_ id: Int) throws -> ${model.className}? {');
    buffer.writeln('        let result = try manager.query(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            sql: "SELECT * FROM \\(${model.className}Schema.tableName) WHERE \\(${model.className}Schema.${_toCamelCase(primaryKey.fieldName)}) = ? LIMIT 1",');
    buffer.writeln('            arguments: [id]');
    buffer.writeln('        )');
    buffer.writeln('        guard let rows = result["rows"] as? [[Any?]], !rows.isEmpty,');
    buffer.writeln('              let columns = result["columns"] as? [String] else {');
    buffer.writeln('            return nil');
    buffer.writeln('        }');
    buffer.writeln('        return fromRow(columns: columns, row: rows[0])');
    buffer.writeln('    }');
    buffer.writeln();

    // FindAll method
    buffer.writeln('    public func findAll() throws -> [${model.className}] {');
    buffer.writeln('        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \\(${model.className}Schema.tableName)")');
    buffer.writeln('        guard let rows = result["rows"] as? [[Any?]],');
    buffer.writeln('              let columns = result["columns"] as? [String] else {');
    buffer.writeln('            return []');
    buffer.writeln('        }');
    buffer.writeln('        return rows.map { fromRow(columns: columns, row: $0) }');
    buffer.writeln('    }');
    buffer.writeln();

    // FromRow helper
    buffer.writeln('    private func fromRow(columns: [String], row: [Any?]) -> ${model.className} {');
    buffer.writeln('        var columnMap: [String: Int] = [:]');
    buffer.writeln('        for (index, column) in columns.enumerated() {');
    buffer.writeln('            columnMap[column] = index');
    buffer.writeln('        }');
    buffer.writeln('        return ${model.className}(');

    final fieldInits = <String>[];
    for (final field in model.fields) {
      final value = _deserializeSwift(field, 'row[columnMap[${model.className}Schema.${_toCamelCase(field.fieldName)}]!]');
      fieldInits.add('            ${field.fieldName}: $value');
    }
    buffer.writeln(fieldInits.join(',\n'));
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getSwiftType(FieldModel field) {
    final baseType = field.dartType.replaceAll('?', '');
    String swiftType;

    if (baseType == 'int' || baseType == 'Int' || baseType == 'DateTime') {
      swiftType = 'Int';
    } else if (baseType == 'double' || baseType == 'Double') {
      swiftType = 'Double';
    } else if (baseType == 'String') {
      swiftType = 'String';
    } else if (baseType == 'bool') {
      swiftType = 'Bool';
    } else {
      swiftType = 'Any';
    }

    return field.isNullable ? '$swiftType?' : swiftType;
  }

  String _serializeSwift(FieldModel field, String accessor) {
    if (field.dartType.contains('bool')) {
      return field.isNullable
          ? '$accessor.map { $0 ? 1 : 0 } ?? NSNull()'
          : '$accessor ? 1 : 0';
    }
    return field.isNullable ? '$accessor ?? NSNull()' : accessor;
  }

  String _deserializeSwift(FieldModel field, String accessor) {
    final baseType = field.dartType.replaceAll('?', '');

    if (baseType == 'int' || baseType == 'Int' || baseType == 'DateTime') {
      return field.isNullable ? '$accessor as? Int' : '$accessor as! Int';
    } else if (baseType == 'double' || baseType == 'Double') {
      return field.isNullable ? '$accessor as? Double' : '$accessor as! Double';
    } else if (baseType == 'String') {
      return field.isNullable ? '$accessor as? String' : '$accessor as! String';
    } else if (baseType == 'bool') {
      return field.isNullable
          ? '($accessor as? Int).map { $0 == 1 }'
          : '($accessor as! Int) == 1';
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

  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }
}
