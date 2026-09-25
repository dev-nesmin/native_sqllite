/// Base class for type converters.
/// Implement this to create custom type converters for complex types.
///
/// Example:
/// ```dart
/// class ColorConverter extends TypeConverter<Color, int> {
///   const ColorConverter();
///
///   @override
///   int toSql(Color value) => value.toARGB32();
///
///   @override
///   Color fromSql(int sqlValue) => Color(sqlValue);
/// }
/// ```
abstract class TypeConverter<DartType, SqlType> {
  /// Creates a stateless converter.
  const TypeConverter();

  /// Converts a Dart value to its SQL representation.
  SqlType toSql(DartType value);

  /// Converts an SQL value back to its Dart representation.
  DartType fromSql(SqlType sqlValue);
}

/// Annotation to specify a custom type converter for a field.
///
/// The generated SQLite column type is inferred from [TypeConverter]'s
/// `SqlType` argument. Converter constants may use generics, named
/// constructors, and constructor arguments.
///
/// Example:
/// ```dart
/// @UseConverter(ColorConverter())
/// final Color backgroundColor;
/// ```
class UseConverter {
  /// The type converter instance to use.
  final TypeConverter<dynamic, dynamic> converter;

  /// Creates a converter annotation using [converter].
  const UseConverter(this.converter);
}
