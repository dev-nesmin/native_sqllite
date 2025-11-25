import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Utility class for handling generator errors.
class GeneratorError {
  /// Throws an [InvalidGenerationSourceError] with the given message and element.
  static Never throwError(String message, [Element? element]) {
    throw InvalidGenerationSourceError(message, element: element);
  }

  /// Validates a condition and throws an error if it's false.
  static void validate(
    bool condition,
    String message, [
    Element? element,
  ]) {
    if (!condition) {
      throwError(message, element);
    }
  }

  /// Checks if an element is not null, throws an error if it is.
  static T requireNonNull<T>(
    T? value,
    String message, [
    Element? element,
  ]) {
    if (value == null) {
      throwError(message, element);
    }
    return value;
  }
}
