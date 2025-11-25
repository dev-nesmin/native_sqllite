part of native_sqlite;

/// Annotation to mark a field as JSON serializable.
/// The field will be stored as TEXT in SQLite and automatically
/// serialized/deserialized using dart:convert json encoding.
///
/// Supported types:
/// - Map<String, dynamic>
/// - List<dynamic>
/// - Any class with toJson() method and .fromJson() constructor
///
/// Example:
/// ```dart
/// @JsonField()
/// @Column(type: 'TEXT')
/// final Map<String, dynamic> metadata;
///
/// @JsonField()
/// @Column(type: 'TEXT')
/// final Address? address;  // Address must have toJson() and fromJson()
/// ```
class JsonField {
  const JsonField();
}
