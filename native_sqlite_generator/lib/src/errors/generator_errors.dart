import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Base class for native_sqlite_generator errors with rich context.
///
/// Provides error codes, suggestions, and documentation links.
class TableGeneratorError extends InvalidGenerationSourceError {
  final String code;
  final String? suggestion;
  final String? documentation;

  TableGeneratorError(
    String message, {
    required this.code,
    this.suggestion,
    this.documentation,
    Element? element,
  }) : super(
         _formatMessage(message, code, suggestion, documentation),
         element: element,
       );

  static String _formatMessage(
    String message,
    String code,
    String? suggestion,
    String? documentation,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('[$code] $message');

    if (suggestion != null) {
      buffer.writeln();
      buffer.writeln('💡 Suggestion: $suggestion');
    }

    if (documentation != null) {
      buffer.writeln();
      buffer.writeln('📖 Documentation: $documentation');
    }

    return buffer.toString();
  }
}

/// Error thrown when a table is missing a primary key.
class MissingPrimaryKeyError extends TableGeneratorError {
  MissingPrimaryKeyError(Element element, String tableName)
    : super(
        'Table "$tableName" must have at least one primary key field',
        code: 'MISSING_PRIMARY_KEY',
        suggestion:
            'Add @PrimaryKey() annotation to an id field, or mark a field with @PrimaryKey(autoIncrement: true)',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#primary-keys',
        element: element,
      );
}

/// Error thrown when duplicate column names are detected.
class DuplicateColumnError extends TableGeneratorError {
  DuplicateColumnError(String columnName, Element element)
    : super(
        'Duplicate column name: "$columnName"',
        code: 'DUPLICATE_COLUMN',
        suggestion:
            'Use @DbColumn(name: "unique_column_name") to specify a different column name',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#column-annotation',
        element: element,
      );
}

/// Error thrown when an unsupported type is used for a column.
class InvalidTypeError extends TableGeneratorError {
  InvalidTypeError(String type, Element element)
    : super(
        'Type "$type" is not supported for database columns',
        code: 'INVALID_TYPE',
        suggestion:
            'Use supported types: int, double, String, bool, DateTime, Uint8List, or enum types. For custom types, consider using a TypeConverter.',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#supported-types',
        element: element,
      );
}

/// Error thrown when a table name is invalid.
class InvalidTableNameError extends TableGeneratorError {
  InvalidTableNameError(String tableName, Element element, String reason)
    : super(
        'Invalid table name "$tableName": $reason',
        code: 'INVALID_TABLE_NAME',
        suggestion:
            'Table names should be valid SQL identifiers. Avoid special characters and SQL keywords.',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#naming-conventions',
        element: element,
      );
}

/// Error thrown when a foreign key configuration is invalid.
class InvalidForeignKeyError extends TableGeneratorError {
  InvalidForeignKeyError(String fieldName, Element element, String reason)
    : super(
        'Invalid foreign key configuration for field "$fieldName": $reason',
        code: 'INVALID_FOREIGN_KEY',
        suggestion:
            'Ensure the referenced table and column exist, and the types match',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#foreign-keys',
        element: element,
      );
}

/// Error thrown when an index configuration is invalid.
class InvalidIndexError extends TableGeneratorError {
  InvalidIndexError(String indexName, Element element, String reason)
    : super(
        'Invalid index configuration "$indexName": $reason',
        code: 'INVALID_INDEX',
        suggestion:
            'Check that the index columns exist and are of supported types',
        documentation: 'https://github.com/dev-nesmin/native_sqlite#indexes',
        element: element,
      );
}

/// Error thrown when multiple primary keys are incorrectly configured.
class MultiplePrimaryKeysError extends TableGeneratorError {
  MultiplePrimaryKeysError(Element element, List<String> fieldNames)
    : super(
        'Multiple primary keys detected: ${fieldNames.join(", ")}. '
        'For composite keys, use @PrimaryKey() on multiple fields. '
        'Only one field can have autoIncrement enabled.',
        code: 'MULTIPLE_PRIMARY_KEYS',
        suggestion:
            'Remove autoIncrement from all but one field, or use composite primary keys',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#composite-keys',
        element: element,
      );
}

/// Error thrown when a field has conflicting annotations.
class ConflictingAnnotationsError extends TableGeneratorError {
  ConflictingAnnotationsError(
    String fieldName,
    Element element,
    List<String> conflictingAnnotations,
  ) : super(
        'Field "$fieldName" has conflicting annotations: ${conflictingAnnotations.join(", ")}',
        code: 'CONFLICTING_ANNOTATIONS',
        suggestion: 'Remove one of the conflicting annotations',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#annotations',
        element: element,
      );
}

/// Error thrown when annotation parameters are invalid.
class InvalidAnnotationParameterError extends TableGeneratorError {
  InvalidAnnotationParameterError(
    String annotationName,
    String parameterName,
    String reason,
    Element element,
  ) : super(
        'Invalid parameter "$parameterName" in @$annotationName: $reason',
        code: 'INVALID_ANNOTATION_PARAMETER',
        suggestion: 'Check the parameter value and type',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#annotations',
        element: element,
      );
}

/// Error thrown when a table class is not properly structured.
class InvalidTableStructureError extends TableGeneratorError {
  InvalidTableStructureError(String tableName, Element element, String reason)
    : super(
        'Invalid table structure for "$tableName": $reason',
        code: 'INVALID_TABLE_STRUCTURE',
        suggestion:
            'Tables must be classes with final fields and a constructor',
        documentation:
            'https://github.com/dev-nesmin/native_sqlite#table-structure',
        element: element,
      );
}
