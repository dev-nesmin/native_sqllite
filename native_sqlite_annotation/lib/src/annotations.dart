/// Annotation to mark a class as a database table.
///
/// The class name will be used as the table name by default,
/// but you can override it with the [name] parameter.
///
/// Example:
/// ```dart
/// @Table(name: 'users')
/// class User {
///   @PrimaryKey(autoIncrement: true)
///   final int? id;
///
///   @Column()
///   final String name;
///
///   @Column(name: 'email_address', unique: true)
///   final String email;
///
///   const User({this.id, required this.name, required this.email});
/// }
/// ```
class Table {
  /// The name of the table in the database.
  /// If not specified, the class name will be converted to snake_case.
  final String? name;

  /// Indexes to create for this table.
  /// Each index is defined as a list of column names.
  final List<List<String>>? indexes;

  const Table({this.name, this.indexes});
}

/// Annotation to mark a field as the primary key.
class PrimaryKey {
  /// Whether the primary key should auto-increment.
  final bool autoIncrement;

  const PrimaryKey({this.autoIncrement = false});
}

/// Annotation to mark a field as a database column.
class Column {
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

  const Column({
    this.name,
    this.nullable,
    this.unique = false,
    this.defaultValue,
    this.type,
  });
}

/// Annotation to ignore a field during code generation.
class Ignore {
  const Ignore();
}

/// Annotation to define a foreign key relationship.
class ForeignKey {
  /// The table this foreign key references.
  final String table;

  /// The column in the referenced table.
  final String column;

  /// Action to take when the referenced row is deleted.
  /// Examples: 'CASCADE', 'SET NULL', 'RESTRICT', 'NO ACTION'
  final String? onDelete;

  /// Action to take when the referenced row is updated.
  /// Examples: 'CASCADE', 'SET NULL', 'RESTRICT', 'NO ACTION'
  final String? onUpdate;

  const ForeignKey({
    required this.table,
    required this.column,
    this.onDelete,
    this.onUpdate,
  });
}

/// Annotation to create an index on specific columns.
class Index {
  /// The name of the index. If not specified, a name will be generated.
  final String? name;

  /// The columns to include in the index.
  final List<String> columns;

  /// Whether the index should enforce uniqueness.
  final bool unique;

  const Index({
    this.name,
    required this.columns,
    this.unique = false,
  });
}
