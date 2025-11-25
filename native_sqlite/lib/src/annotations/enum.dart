part of native_sqlite;

/// Strategy for storing enum values in the database.
enum EnumType {
  /// Store enum as its integer index (0, 1, 2, ...).
  ordinal,

  /// Store enum as its name string ('active', 'inactive', ...).
  name,

  /// Store enum as a custom value (requires @EnumValue on each enum value).
  value,
}

/// Annotation to specify how an enum field should be stored.
class EnumField {
  /// The strategy to use for storing this enum.
  final EnumType type;

  const EnumField({this.type = EnumType.ordinal});
}

/// Annotation for enum values to specify their database representation.
/// Only used when EnumField.type is EnumType.value.
class EnumValue {
  /// The value to store in the database for this enum value.
  final dynamic value;

  const EnumValue(this.value);
}
