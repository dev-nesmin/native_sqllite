part of native_sqlite;

/// Base class for type converters.
/// Implement this to create custom type converters for complex types.
///
/// Example:
/// ```dart
/// class ColorConverter extends TypeConverter<Color, int> {
///   const ColorConverter();
///
///   @override
///   int toSql(Color value) => value.value;
///
///   @override
///   Color fromSql(int sqlValue) => Color(sqlValue);
/// }
/// ```
abstract class TypeConverter<DartType, SqlType> {
  const TypeConverter();

  /// Converts a Dart value to its SQL representation.
  SqlType toSql(DartType value);

  /// Converts an SQL value back to its Dart representation.
  DartType fromSql(SqlType sqlValue);
}

/// Annotation to specify a custom type converter for a field.
///
/// Example:
/// ```dart
/// @Column()
/// @UseConverter(ColorConverter())
/// final Color backgroundColor;
/// ```
class UseConverter {
  /// The type converter instance to use.
  final TypeConverter converter;

  const UseConverter(this.converter);
}
