import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// SQL data types.
enum SqlType {
  integer('INTEGER'),
  real('REAL'),
  text('TEXT'),
  blob('BLOB'),
  numeric('NUMERIC');

  const SqlType(this.sqlName);

  final String sqlName;

  /// Infers SQL type from Dart type.
  static SqlType fromDartType(DartType type, {String enumType = 'ordinal'}) {
    final baseType = _getBaseType(type);

    if (baseType == 'int' || baseType == 'Int' || baseType == 'bool') {
      return SqlType.integer;
    } else if (baseType == 'double' || baseType == 'Double') {
      return SqlType.real;
    } else if (baseType == 'num') {
      return SqlType.real; // Store num as REAL for flexibility
    } else if (baseType == 'String') {
      return SqlType.text;
    } else if (baseType == 'Uint8List' || baseType == 'List<int>') {
      return SqlType.blob;
    } else if (baseType == 'DateTime') {
      return SqlType.integer; // Store as milliseconds since epoch
    } else if (baseType == 'Duration') {
      return SqlType.integer; // Store as milliseconds
    } else if (baseType == 'Uri') {
      return SqlType.text; // Store as string representation
    } else if (TypeUtils.isEnum(type)) {
      // Enum storage depends on strategy
      return enumType == 'name' ? SqlType.text : SqlType.integer;
    } else {
      return SqlType.text; // Default to TEXT for custom types
    }
  }

  static String _getBaseType(DartType type) {
    return type.getDisplayString().replaceAll('?', '');
  }
}

/// Utilities for working with Dart types.
class TypeUtils {
  /// Checks if a type is nullable.
  static bool isNullable(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  /// Gets the base type name without nullability suffix.
  static String getBaseTypeName(DartType type) {
    return type.getDisplayString().replaceAll('?', '');
  }

  /// Gets the display string for a type.
  static String getDisplayString(DartType type) {
    return type.getDisplayString();
  }

  /// Checks if a type is DateTime.
  static bool isDateTime(DartType type) {
    return getBaseTypeName(type) == 'DateTime';
  }

  /// Checks if a type is bool.
  static bool isBool(DartType type) {
    return getBaseTypeName(type) == 'bool';
  }

  /// Checks if a type is int.
  static bool isInt(DartType type) {
    final base = getBaseTypeName(type);
    return base == 'int' || base == 'Int';
  }

  /// Checks if a type is double.
  static bool isDouble(DartType type) {
    final base = getBaseTypeName(type);
    return base == 'double' || base == 'Double';
  }

  /// Checks if a type is String.
  static bool isString(DartType type) {
    return getBaseTypeName(type) == 'String';
  }

  /// Checks if a type is Duration.
  static bool isDuration(DartType type) {
    return getBaseTypeName(type) == 'Duration';
  }

  /// Checks if a type is Uri.
  static bool isUri(DartType type) {
    return getBaseTypeName(type) == 'Uri';
  }

  /// Checks if a type is num.
  static bool isNum(DartType type) {
    return getBaseTypeName(type) == 'num';
  }

  /// Checks if a type is an enum.
  static bool isEnum(DartType type) {
    final element = type.element;
    return element is EnumElement;
  }

  /// Generates serialization expression for a given type.
  static String generateSerializeExpression(
    DartType type,
    String accessor, {
    String enumType = 'ordinal', // 'ordinal', 'name', or 'value'
  }) {
    final isNullable = TypeUtils.isNullable(type);

    if (isDateTime(type)) {
      if (isNullable) {
        return '$accessor?.millisecondsSinceEpoch';
      }
      return '$accessor.millisecondsSinceEpoch';
    } else if (isDuration(type)) {
      if (isNullable) {
        return '$accessor?.inMilliseconds';
      }
      return '$accessor.inMilliseconds';
    } else if (isUri(type)) {
      if (isNullable) {
        return '$accessor?.toString()';
      }
      return '$accessor.toString()';
    } else if (isEnum(type)) {
      // Handle enum serialization based on storage strategy
      if (enumType == 'name') {
        if (isNullable) {
          return '$accessor?.name';
        }
        return '$accessor.name';
      } else {
        // Default to ordinal (index)
        if (isNullable) {
          return '$accessor?.index';
        }
        return '$accessor.index';
      }
    } else if (isBool(type)) {
      if (isNullable) {
        return '$accessor == true ? 1 : ($accessor == false ? 0 : null)';
      }
      return '$accessor ? 1 : 0';
    }

    return accessor;
  }

  /// Generates deserialization expression for a given type.
  static String generateDeserializeExpression(
    DartType type,
    String accessor, {
    String enumType = 'ordinal', // 'ordinal', 'name', or 'value'
  }) {
    final isNullable = TypeUtils.isNullable(type);
    final baseType = getBaseTypeName(type);

    if (isDateTime(type)) {
      if (isNullable) {
        return '$accessor != null ? DateTime.fromMillisecondsSinceEpoch($accessor as int) : null';
      }
      return 'DateTime.fromMillisecondsSinceEpoch($accessor as int)';
    } else if (isDuration(type)) {
      if (isNullable) {
        return '$accessor != null ? Duration(milliseconds: $accessor as int) : null';
      }
      return 'Duration(milliseconds: $accessor as int)';
    } else if (isUri(type)) {
      if (isNullable) {
        return '$accessor != null ? Uri.parse($accessor as String) : null';
      }
      return 'Uri.parse($accessor as String)';
    } else if (isEnum(type)) {
      // Handle enum deserialization based on storage strategy
      if (enumType == 'name') {
        if (isNullable) {
          return '$accessor != null ? $baseType.values.firstWhere((e) => e.name == $accessor) : null';
        }
        return '$baseType.values.firstWhere((e) => e.name == $accessor)';
      } else {
        // Default to ordinal (index)
        if (isNullable) {
          return '$accessor != null ? $baseType.values[$accessor as int] : null';
        }
        return '$baseType.values[$accessor as int]';
      }
    } else if (isBool(type)) {
      if (isNullable) {
        return '$accessor != null ? ($accessor as int) == 1 : null';
      }
      return '($accessor as int) == 1';
    } else if (isInt(type)) {
      if (isNullable) {
        return '$accessor as int?';
      }
      return '$accessor as int';
    } else if (isDouble(type)) {
      if (isNullable) {
        return '$accessor as double?';
      }
      return '$accessor as double';
    } else if (isNum(type)) {
      if (isNullable) {
        return '$accessor as num?';
      }
      return '$accessor as num';
    } else if (isString(type)) {
      if (isNullable) {
        return '$accessor as String?';
      }
      return '$accessor as String';
    }

    // For other types, just cast
    if (isNullable) {
      return '$accessor as $baseType?';
    }
    return '$accessor as $baseType';
  }
}
