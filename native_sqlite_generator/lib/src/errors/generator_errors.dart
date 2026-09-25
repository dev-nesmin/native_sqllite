import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Base class for generator diagnostics with an actionable error code.
class TableGeneratorError extends InvalidGenerationSourceError {
  TableGeneratorError(
    String message, {
    required String code,
    required String suggestion,
    required Element element,
  }) : super('[$code] $message\n\nSuggestion: $suggestion', element: element);
}

/// A managed table must have exactly one primary key.
class MissingPrimaryKeyError extends TableGeneratorError {
  MissingPrimaryKeyError(Element element, String tableName)
    : super(
        'Table "$tableName" must have a primary key field.',
        code: 'MISSING_PRIMARY_KEY',
        suggestion:
            'Annotate one field with @PrimaryKey(), using '
            '@PrimaryKey(autoIncrement: true) for an integer row ID.',
        element: element,
      );
}

/// Composite primary keys are rejected until their API is implemented.
class MultiplePrimaryKeysError extends TableGeneratorError {
  MultiplePrimaryKeysError(Element element, List<String> fieldNames)
    : super(
        'Multiple primary keys detected: ${fieldNames.join(', ')}. '
        'Composite primary keys are not supported.',
        code: 'MULTIPLE_PRIMARY_KEYS',
        suggestion: 'Keep exactly one field annotated with @PrimaryKey().',
        element: element,
      );
}
