part of native_sqlite;

/// Annotation to create an index on specific columns.
class Index {
  /// The name of the index. If not specified, a name will be generated.
  final String? name;

  /// The columns to include in the index.
  final List<String> columns;

  /// Whether the index should enforce uniqueness.
  final bool unique;

  const Index({this.name, required this.columns, this.unique = false});
}
