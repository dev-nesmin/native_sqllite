part of native_sqlite;

/// Annotation to mark a class as a database table.
///
/// The class name will be used as the table name by default,
/// but you can override it with the [name] parameter.
///
/// Example:
/// ```dart
/// @DbTable(name: 'users', database: 'app.db')
/// class User {
///   @PrimaryKey(autoIncrement: true)
///   final int? id;
///
///   @DbColumn()
///   final String name;
///
///   @DbColumn(name: 'email_address', unique: true)
///   final String email;
///
///   const User({this.id, required this.name, required this.email});
/// }
/// ```
class DbTable {
  /// The name of the table in the database.
  /// If not specified, the class name will be converted to snake_case.
  final String? name;

  /// Indexes to create for this table.
  /// Each index is defined as a list of column names.
  final List<List<String>>? indexes;

  /// The default database name for this table.
  /// When specified, the generated repository will use this as the default database.
  /// You can still override it by passing a different database name to the repository constructor.
  final String? database;

  const DbTable({this.name, this.indexes, this.database});
}
