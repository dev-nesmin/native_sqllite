/// Result of a SQL query.
class QueryResult {
  /// The column names in the result set.
  final List<String> columns;

  /// The rows returned by the query.
  /// Each row is a list of values corresponding to the columns.
  final List<List<Object?>> rows;

  const QueryResult({
    required this.columns,
    required this.rows,
  });

  /// Converts the result to a list of maps, where each map represents a row.
  List<Map<String, Object?>> toMapList() {
    return rows.map((row) {
      final map = <String, Object?>{};
      for (var i = 0; i < columns.length; i++) {
        map[columns[i]] = i < row.length ? row[i] : null;
      }
      return map;
    }).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'columns': columns,
      'rows': rows,
    };
  }

  factory QueryResult.fromMap(Map<String, dynamic> map) {
    final columns = (map['columns'] as List<dynamic>).cast<String>();
    final rows = (map['rows'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).cast<Object?>())
        .toList();

    return QueryResult(
      columns: columns,
      rows: rows,
    );
  }

  @override
  String toString() {
    return 'QueryResult(columns: $columns, rows: ${rows.length} rows)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QueryResult) return false;
    if (columns.length != other.columns.length) return false;
    if (rows.length != other.rows.length) return false;

    for (var i = 0; i < columns.length; i++) {
      if (columns[i] != other.columns[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return Object.hash(columns, rows.length);
  }
}
