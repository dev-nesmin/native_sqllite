import 'package:native_sqlite_generator/src/helpers/naming_conventions.dart';

/// Utility class for naming conventions.
class NamingUtils {
  /// Converts a string from camelCase or PascalCase to snake_case.
  static String toSnakeCase(String input) {
    return NamingConventions.toSnakeCase(input);
  }

  /// Converts a string to SCREAMING_SNAKE_CASE.
  static String toScreamingSnakeCase(String input) {
    return toSnakeCase(input).toUpperCase();
  }

  /// Converts snake_case to camelCase.
  static String toCamelCase(String input) {
    return NamingConventions.toCamelCase(input);
  }

  /// Converts snake_case to PascalCase.
  static String toPascalCase(String input) {
    return NamingConventions.toPascalCase(input);
  }

  /// Capitalizes the first letter of a string.
  static String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// Decapitalizes the first letter of a string.
  static String decapitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  /// Gets the schema class name for a given class name.
  static String getSchemaClassName(String className) {
    return '${className}Schema';
  }

  /// Gets the repository class name for a given class name.
  static String getRepositoryClassName(String className) {
    return '${className}Repository';
  }

  /// Gets the constant name for a column.
  static String getColumnConstantName(String columnName) {
    return toScreamingSnakeCase(columnName);
  }
}
