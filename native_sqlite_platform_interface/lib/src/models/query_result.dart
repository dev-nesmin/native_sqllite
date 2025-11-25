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

  /// Converts the result to a list of maps with typed accessors.
  List<TypedRow> toTypedList() {
    return toMapList().map((map) => TypedRow(map)).toList();
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

/// A typed wrapper around a query result row that provides type-safe accessors.
class TypedRow {
  final Map<String, Object?> _data;

  TypedRow(this._data);

  /// Gets a value by key, allowing dynamic type casting.
  Object? operator [](String key) => _data[key];

  /// Gets all keys in this row.
  Iterable<String> get keys => _data.keys;

  /// Gets all values in this row.
  Iterable<Object?> get values => _data.values;

  /// Gets a value as a String, with optional default.
  String getString(String key, [String defaultValue = '']) {
    final value = _data[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Gets a value as an int, with optional default.
  int getInt(String key, [int defaultValue = 0]) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Gets a value as a double, with optional default.
  double getDouble(String key, [double defaultValue = 0.0]) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Gets a value as a num (int or double), with optional default.
  num getNum(String key, [num defaultValue = 0]) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is num) return value;
    if (value is String) {
      return double.tryParse(value) ?? int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Gets a value as a bool, with optional default.
  bool getBool(String key, [bool defaultValue = false]) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }

  /// Formats a numeric value as a fixed decimal string.
  String getFormattedNumber(String key, int decimals,
      [String defaultValue = '0.00']) {
    final value = _data[key];
    if (value == null) return defaultValue;
    if (value is num) return value.toStringAsFixed(decimals);
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed.toStringAsFixed(decimals);
    }
    return defaultValue;
  }

  /// Gets the underlying map.
  Map<String, Object?> toMap() => Map.unmodifiable(_data);

  @override
  String toString() => _data.toString();
}
