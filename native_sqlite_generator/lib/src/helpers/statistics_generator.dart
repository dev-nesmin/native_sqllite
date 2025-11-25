import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Generates statistics about generated code for documentation purposes.
class StatisticsGenerator {
  /// Generates statistics comment block for a table.
  ///
  /// Returns a formatted comment block with:
  /// - Total field count
  /// - Type distribution
  /// - Index count
  /// - Special fields (primary key, foreign keys, unique constraints)
  static String generate(TableInfo table) {
    final buffer = StringBuffer();

    buffer.writeln('/// Statistics:');
    buffer.writeln('/// - Total fields: ${table.columns.length}');

    // Type distribution
    final typeDistribution = _getTypeDistribution(table);
    if (typeDistribution.isNotEmpty) {
      buffer.writeln('/// - Type distribution:');
      typeDistribution.forEach((type, count) {
        buffer.writeln('///   - $type: $count');
      });
    }

    // Index information
    if (table.indexes.isNotEmpty) {
      buffer.writeln('/// - Indexes: ${table.indexes.length}');
    }

    // Special field counts
    final pkCount = table.columns.where((c) => c.isPrimaryKey).length;
    if (pkCount > 0) {
      buffer.writeln('/// - Primary keys: $pkCount');
    }

    final fkCount = table.columns.where((c) => c.hasForeignKey).length;
    if (fkCount > 0) {
      buffer.writeln('/// - Foreign keys: $fkCount');
    }

    final uniqueCount = table.columns.where((c) => c.isUnique).length;
    if (uniqueCount > 0) {
      buffer.writeln('/// - Unique constraints: $uniqueCount');
    }

    final nullableCount = table.columns.where((c) => c.isNullable).length;
    if (nullableCount > 0) {
      buffer.writeln('/// - Nullable fields: $nullableCount');
    }

    final jsonFields = table.columns.where((c) => c.isJsonField).length;
    if (jsonFields > 0) {
      buffer.writeln('/// - JSON fields: $jsonFields');
    }

    final converterFields = table.columns.where((c) => c.hasConverter).length;
    if (converterFields > 0) {
      buffer.writeln('/// - Custom converters: $converterFields');
    }

    return buffer.toString().trim();
  }

  /// Gets the distribution of Dart types in the table.
  static Map<String, int> _getTypeDistribution(TableInfo table) {
    final distribution = <String, int>{};

    for (final column in table.columns) {
      final typeName = _getSimpleTypeName(column.dartType.toString());
      distribution[typeName] = (distribution[typeName] ?? 0) + 1;
    }

    return Map.fromEntries(
      distribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)), // Sort by count desc
    );
  }

  /// Simplifies a type name for display.
  ///
  /// Examples:
  /// - "String" -> "String"
  /// - "int?" -> "int"
  /// - "List<String>" -> "List<String>"
  static String _getSimpleTypeName(String fullType) {
    // Remove nullability suffix
    String type = fullType.replaceAll('?', '');

    // Clean up any extra whitespace
    type = type.trim();

    return type;
  }

  /// Generates a compact one-line summary for headers.
  static String generateSummary(TableInfo table) {
    final parts = <String>[];

    parts.add('${table.columns.length} fields');

    if (table.indexes.isNotEmpty) {
      parts.add('${table.indexes.length} indexes');
    }

    final fkCount = table.columns.where((c) => c.hasForeignKey).length;
    if (fkCount > 0) {
      parts.add('$fkCount foreign keys');
    }

    return parts.join(', ');
  }
}
