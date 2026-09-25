/// Annotation to mark a field as the primary key.
class PrimaryKey {
  /// Whether the primary key should auto-increment.
  final bool autoIncrement;

  /// Whether to use a locally generated UUID for this primary key on insert.
  /// This is only supported for nullable `String?` fields, allowing generated
  /// helpers to distinguish a caller-provided UUID from one they must create.
  final bool useLocalUuid;

  /// Creates a primary-key annotation.
  const PrimaryKey({this.autoIncrement = false, this.useLocalUuid = false});
}
