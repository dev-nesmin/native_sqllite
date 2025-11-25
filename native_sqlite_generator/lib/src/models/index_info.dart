/// Information about an index on a table.
class IndexInfo {
  IndexInfo({
    required this.name,
    required this.columns,
    required this.unique,
  });

  /// The index name.
  final String name;

  /// The columns in this index.
  final List<String> columns;

  /// Whether this is a unique index.
  final bool unique;

  /// Generates the CREATE INDEX SQL statement.
  String generateSql(String tableName) {
    final uniqueStr = unique ? 'UNIQUE ' : '';
    final columnsStr = columns.join(', ');
    return 'CREATE ${uniqueStr}INDEX $name ON $tableName ($columnsStr)';
  }

  @override
  String toString() {
    return 'IndexInfo($name on ${columns.join(", ")}, unique: $unique)';
  }
}
