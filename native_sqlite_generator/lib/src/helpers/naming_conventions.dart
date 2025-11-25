/// Utility functions for converting between different naming conventions.
///
/// Supports:
/// - snake_case (database column names)
/// - camelCase (Dart field names)
/// - PascalCase (class names)
class NamingConventions {
  /// Converts a string to snake_case.
  ///
  /// Examples:
  /// - "userName" -> "user_name"
  /// - "UserName" -> "user_name"
  /// - "user_name" -> "user_name"
  /// - "UserNameID" -> "user_name_id"
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    // Handle already snake_case
    if (!input.contains(RegExp(r'[A-Z]')) && input.contains('_')) {
      return input.toLowerCase();
    }

    final result = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == char.toUpperCase() && char != '_') {
        // Add underscore before uppercase letter (except at start)
        if (i > 0 && input[i - 1] != '_') {
          // Check if previous char is lowercase or next char is lowercase
          final prevIsLower =
              i > 0 && input[i - 1] == input[i - 1].toLowerCase();
          final nextIsLower = i < input.length - 1 &&
              input[i + 1] == input[i + 1].toLowerCase();

          if (prevIsLower || nextIsLower) {
            result.write('_');
          }
        }
        result.write(char.toLowerCase());
      } else {
        result.write(char.toLowerCase());
      }
    }

    return result.toString();
  }

  /// Converts a string to camelCase.
  ///
  /// Examples:
  /// - "user_name" -> "userName"
  /// - "UserName" -> "userName"
  /// - "userName" -> "userName"
  static String toCamelCase(String input) {
    if (input.isEmpty) return input;

    // Split by underscore or capital letters
    final words = _splitIntoWords(input);
    if (words.isEmpty) return input;

    // First word lowercase, rest capitalized
    final result = StringBuffer(words.first.toLowerCase());

    for (int i = 1; i < words.length; i++) {
      result.write(_capitalize(words[i]));
    }

    return result.toString();
  }

  /// Converts a string to PascalCase.
  ///
  /// Examples:
  /// - "user_name" -> "UserName"
  /// - "userName" -> "UserName"
  /// - "UserName" -> "UserName"
  static String toPascalCase(String input) {
    if (input.isEmpty) return input;

    final words = _splitIntoWords(input);
    if (words.isEmpty) return input;

    // Capitalize all words
    return words.map(_capitalize).join();
  }

  /// Checks if a string is in snake_case.
  static bool isSnakeCase(String input) {
    if (input.isEmpty) return true;
    return input == toSnakeCase(input);
  }

  /// Checks if a string is in camelCase.
  static bool isCamelCase(String input) {
    if (input.isEmpty) return true;
    if (input[0] != input[0].toLowerCase()) return false;
    return !input.contains('_');
  }

  /// Checks if a string is in PascalCase.
  static bool isPascalCase(String input) {
    if (input.isEmpty) return true;
    if (input[0] != input[0].toUpperCase()) return false;
    return !input.contains('_');
  }

  /// Formats a name according to the specified convention.
  ///
  /// [name] - The name to format
  /// [convention] - One of: 'snake', 'camel', 'pascal'
  static String format(String name, String convention) {
    switch (convention.toLowerCase()) {
      case 'snake':
        return toSnakeCase(name);
      case 'camel':
        return toCamelCase(name);
      case 'pascal':
        return toPascalCase(name);
      default:
        return name;
    }
  }

  // Helper: Split string into words
  static List<String> _splitIntoWords(String input) {
    // First, split by underscore
    var words = input.split('_').where((w) => w.isNotEmpty).toList();

    // Then split each word by capital letters
    final result = <String>[];
    for (final word in words) {
      result.addAll(_splitCamelCase(word));
    }

    return result.where((w) => w.isNotEmpty).toList();
  }

  // Helper: Split camelCase/PascalCase into words
  static List<String> _splitCamelCase(String input) {
    if (input.isEmpty) return [];

    final words = <String>[];
    final currentWord = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == char.toUpperCase() && currentWord.isNotEmpty) {
        // Check if this is part of an acronym
        final isAcronym =
            i < input.length - 1 && input[i + 1] == input[i + 1].toUpperCase();

        if (!isAcronym || i == input.length - 1) {
          words.add(currentWord.toString());
          currentWord.clear();
        }
      }

      currentWord.write(char);
    }

    if (currentWord.isNotEmpty) {
      words.add(currentWord.toString());
    }

    return words;
  }

  // Helper: Capitalize first letter
  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}
