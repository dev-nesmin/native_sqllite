part of native_sqlite;

/// Annotation to mark a field as the primary key.
class PrimaryKey {
  /// Whether the primary key should auto-increment.
  final bool autoIncrement;

  const PrimaryKey({this.autoIncrement = false});
}
