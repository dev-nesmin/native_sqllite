/// Annotation to mark a class as a database table.
///
/// The class name will be used as the table name by default,
/// but you can override it with the [name] parameter.
///
/// Example:
/// ```dart
/// @DbTable(name: 'users', database: 'app')
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
  /// Each index is defined as a list of Dart field names or SQL column names.
  /// Use a class-level `@Index` annotation for named or unique indexes.
  final List<List<String>>? indexes;

  /// The default database name for this table.
  /// Use a logical name without a file extension.
  /// This legacy selector is recorded in generated table metadata and native
  /// helpers. Dart repositories always receive an open database handle.
  final String? database;

  /// Whether to automatically manage schema creation and migrations for this table.
  ///
  /// When `true` (default), the table will be included in the auto-generated
  /// `DatabaseManager`, eliminating the need for manual table setup.
  ///
  /// Set to `false` if you want to manually manage this table's schema.
  final bool auto;

  /// Creates a table annotation.
  const DbTable({this.name, this.indexes, this.database, this.auto = true});
}
