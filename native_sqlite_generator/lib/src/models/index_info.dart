/// Information about an index on a table.
class IndexInfo {
  IndexInfo({required this.name, required this.columns, required this.unique});

  /// The index name.
  final String name;

  /// The columns in this index.
  final List<String> columns;

  /// Whether this is a unique index.
  final bool unique;

  @override
  String toString() {
    return 'IndexInfo($name on ${columns.join(", ")}, unique: $unique)';
  }
}
