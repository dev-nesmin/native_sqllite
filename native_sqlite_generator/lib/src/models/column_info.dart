import 'package:analyzer/dart/element/type.dart';
import 'package:native_sqlite_generator/src/helpers/type_utils.dart';

/// Information about a column/field in a table.
class ColumnInfo {
  ColumnInfo({
    required this.dartName,
    required this.sqlName,
    required this.dartType,
    required this.sqlType,
    required this.isPrimaryKey,
    required this.isAutoIncrement,
    required this.isNullable,
    required this.isUnique,
    this.defaultValue,
    this.foreignKeyTable,
    this.foreignKeyColumn,
    this.foreignKeyOnDelete,
    this.foreignKeyOnUpdate,
    this.enumType = 'ordinal',
    this.converterExpression,
    this.isJsonField = false,
  });

  /// The Dart field name.
  final String dartName;

  /// The SQL column name.
  final String sqlName;

  /// The Dart type.
  final DartType dartType;

  /// The SQL type.
  final SqlType sqlType;

  /// Whether this is a primary key column.
  final bool isPrimaryKey;

  /// Whether this is an auto-increment column.
  final bool isAutoIncrement;

  /// Whether this column can be null.
  final bool isNullable;

  /// Whether this column has a unique constraint.
  final bool isUnique;

  /// The default value for this column.
  final String? defaultValue;

  /// The foreign key table name (if this is a foreign key).
  final String? foreignKeyTable;

  /// The foreign key column name (if this is a foreign key).
  final String? foreignKeyColumn;

  /// The foreign key ON DELETE action.
  final String? foreignKeyOnDelete;

  /// The foreign key ON UPDATE action.
  final String? foreignKeyOnUpdate;

  /// The enum storage type ('ordinal', 'name', or 'value').
  final String enumType;

  /// The type converter expression (e.g., 'const ColorConverter()').
  /// If present, this will be used for serialization/deserialization.
  final String? converterExpression;

  /// Whether this field should be serialized as JSON.
  final bool isJsonField;

  /// Whether this column has a foreign key constraint.
  bool get hasForeignKey => foreignKeyTable != null;

  /// Whether this column uses a custom type converter.
  bool get hasConverter => converterExpression != null;

  /// Gets the serialization expression for this column.
  String serializeExpression(String accessor) {
    if (hasConverter) {
      // Use custom converter
      final nullCheck = isNullable ? '$accessor != null ? ' : '';
      final nullSuffix = isNullable ? ' : null' : '';
      // Use ! for nullable values since we already checked != null
      final bang = isNullable ? '!' : '';
      return '$nullCheck$converterExpression.toSql($accessor$bang)$nullSuffix';
    }

    if (isJsonField) {
      // Use JSON encoding
      final nullCheck = isNullable ? '$accessor != null ? ' : '';
      final nullSuffix = isNullable ? ' : null' : '';
      final baseType = TypeUtils.getBaseTypeName(dartType);

      // Handle dynamic type
      if (baseType == 'dynamic') {
        return '${nullCheck}jsonEncode($accessor)$nullSuffix';
      }

      // Check if it's a Map or primitive List (use jsonEncode directly)
      if (baseType.startsWith('Map<') ||
          baseType == 'List<String>' ||
          baseType == 'List<int>' ||
          baseType == 'List<double>' ||
          baseType == 'List<bool>' ||
          baseType == 'List<dynamic>') {
        return '${nullCheck}jsonEncode($accessor)$nullSuffix';
      } else if (baseType.startsWith('List<')) {
        // List of custom objects - need to map to toJson()
        // Use ! for nullable lists since we already checked != null
        final bang = isNullable ? '!' : '';
        return '${nullCheck}jsonEncode($accessor$bang.map((e) => e.toJson()).toList())$nullSuffix';
      } else {
        // Custom object with toJson() method
        // Use ! for nullable objects since we already checked != null
        final bang = isNullable ? '!' : '';
        return '${nullCheck}jsonEncode($accessor$bang.toJson())$nullSuffix';
      }
    }

    return TypeUtils.generateSerializeExpression(
      dartType,
      accessor,
      enumType: enumType,
    );
  }

  /// Gets the deserialization expression for this column.
  String deserializeExpression(String accessor) {
    if (hasConverter) {
      // Use custom converter
      // Need to cast the map value to the SQL storage type
      final sqlDartType = _getSqlDartType();
      final nullCheck = isNullable ? '$accessor != null ? ' : '';
      final nullSuffix = isNullable ? ' : null' : '';
      final cast = ' as $sqlDartType';
      return '$nullCheck$converterExpression.fromSql($accessor$cast)$nullSuffix';
    }

    if (isJsonField) {
      // Use JSON decoding
      final nullCheck = isNullable ? '$accessor != null ? ' : '';
      final nullSuffix = isNullable ? ' : null' : '';
      final baseType = TypeUtils.getBaseTypeName(dartType);

      // Handle dynamic type
      if (baseType == 'dynamic') {
        return '${nullCheck}jsonDecode($accessor as String)$nullSuffix';
      }

      // Check if it's a Map or primitive List
      if (baseType.startsWith('Map<')) {
        return '${nullCheck}jsonDecode($accessor as String) as $baseType$nullSuffix';
      } else if (baseType == 'List<String>') {
        return '${nullCheck}(jsonDecode($accessor as String) as List).cast<String>()$nullSuffix';
      } else if (baseType == 'List<int>') {
        return '${nullCheck}(jsonDecode($accessor as String) as List).cast<int>()$nullSuffix';
      } else if (baseType == 'List<double>') {
        return '${nullCheck}(jsonDecode($accessor as String) as List).cast<double>()$nullSuffix';
      } else if (baseType == 'List<bool>') {
        return '${nullCheck}(jsonDecode($accessor as String) as List).cast<bool>()$nullSuffix';
      } else if (baseType == 'List<dynamic>') {
        return '${nullCheck}jsonDecode($accessor as String) as List<dynamic>$nullSuffix';
      } else if (baseType.startsWith('List<')) {
        // List of custom objects - need to extract inner type and map fromJson
        // Extract the inner type from List<Type>
        final innerType = baseType.substring(
          5,
          baseType.length - 1,
        ); // Remove 'List<' and '>'
        return '${nullCheck}(jsonDecode($accessor as String) as List).map((e) => $innerType.fromJson(e as Map<String, dynamic>)).toList()$nullSuffix';
      } else {
        // Custom object with fromJson() factory constructor
        return '${nullCheck}$baseType.fromJson(jsonDecode($accessor as String) as Map<String, dynamic>)$nullSuffix';
      }
    }

    return TypeUtils.generateDeserializeExpression(
      dartType,
      accessor,
      enumType: enumType,
    );
  }

  /// Gets the display type name.
  String get typeDisplayName => dartType.getDisplayString();

  /// Gets the Dart type that corresponds to the SQL storage type.
  /// Used for casting when deserializing with converters.
  String _getSqlDartType() {
    switch (sqlType) {
      case SqlType.integer:
        return 'int';
      case SqlType.real:
        return 'double';
      case SqlType.text:
        return 'String';
      case SqlType.blob:
        return 'Uint8List';
      case SqlType.numeric:
        return 'num';
    }
  }

  @override
  String toString() {
    return 'ColumnInfo($dartName: $sqlName $sqlType, PK: $isPrimaryKey)';
  }
}
