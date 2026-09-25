/// Annotation to mark a field as JSON serializable.
/// The field will be stored as TEXT in SQLite and automatically
/// serialized/deserialized using dart:convert json encoding.
///
/// Supported types:
/// - `Map<String, dynamic>`
/// - `List<dynamic>`
/// - Any class with toJson() method and .fromJson() constructor
///
/// Example:
/// ```dart
/// @JsonField()
/// final Map<String, dynamic> metadata;
///
/// @JsonField()
/// final Address? address;  // Address must have toJson() and fromJson()
/// ```
class JsonField {
  /// Creates a JSON field annotation.
  const JsonField();
}
