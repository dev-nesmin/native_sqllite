part of native_sqlite;

/// Annotation to mark a field as a database column.
class DbColumn {
  /// The name of the column in the database.
  /// If not specified, the field name will be used.
  final String? name;

  /// Whether this column is nullable.
  /// By default, inferred from the Dart type.
  final bool? nullable;

  /// Whether this column should have a UNIQUE constraint.
  final bool unique;

  /// Default value for the column (as SQL expression).
  final String? defaultValue;

  /// Type hint for special SQLite types.
  /// Examples: 'TEXT', 'INTEGER', 'REAL', 'BLOB'
  /// By default, inferred from the Dart type.
  final String? type;

  const DbColumn({
    this.name,
    this.nullable,
    this.unique = false,
    this.defaultValue,
    this.type,
  });
}
