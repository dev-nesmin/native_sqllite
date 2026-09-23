import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// How a column's value is represented in generated native (Kotlin/Swift)
/// code. Each kind reads and writes exactly the storage format used by the
/// Dart side (see `TypeUtils.generateSerializeExpression`), so native code
/// and Dart can share one database.
enum NativeKind {
  /// Dart `int` → SQLite INTEGER.
  integer,

  /// Dart `double` / `num` → SQLite REAL.
  real,

  /// Dart `String` → SQLite TEXT.
  text,

  /// Dart `Uint8List` / `List<int>` → SQLite BLOB.
  blob,

  /// Dart `bool` → SQLite INTEGER (1 / 0).
  boolean,

  /// Dart `DateTime` → SQLite INTEGER (milliseconds since epoch).
  dateTime,

  /// Dart `Duration` → SQLite INTEGER (milliseconds).
  duration,

  /// Dart `Uri` → SQLite TEXT (`Uri.toString()`).
  uri,

  /// Dart enum → SQLite INTEGER (index) or TEXT (name), see
  /// [ColumnSchemaSnapshot.enumType].
  enumeration,
}

/// A column resolved for native code generation.
class NativeColumn {
  NativeColumn._(this.column, this.kind, this.rawStorage);

  factory NativeColumn.of(ColumnSchemaSnapshot column) {
    final raw = _rawStorageKind(column);
    if (raw != null) return NativeColumn._(column, raw, true);
    return NativeColumn._(column, _kindOf(column), false);
  }

  final ColumnSchemaSnapshot column;
  final NativeKind kind;

  /// True when the Dart value is produced by logic native code can't
  /// reproduce (a `@UseConverter`, `@JsonField` or an unknown custom type).
  /// Native code then exposes the value exactly as stored in SQLite.
  final bool rawStorage;

  bool get nullable => column.nullable;

  /// Enum type name (Dart type without nullability), for [NativeKind.enumeration].
  String get enumName => column.dartType.replaceAll('?', '');

  bool get storesEnumByName => column.enumType == 'name';

  /// Human-readable note for generated docs when [rawStorage] is set.
  String? get rawStorageNote {
    if (!rawStorage) return null;
    if (column.isJsonField) return 'JSON text of Dart `${column.dartType}`';
    if (column.hasConverter) {
      return 'value stored by the Dart TypeConverter for `${column.dartType}`';
    }
    return 'stored representation of Dart `${column.dartType}`';
  }

  static NativeKind? _rawStorageKind(ColumnSchemaSnapshot column) {
    if (column.isEnum) return null;
    final custom =
        column.hasConverter ||
        column.isJsonField ||
        !_knownDartTypes.contains(_baseType(column));
    return custom ? _kindOfSqlType(column.type) : null;
  }

  static NativeKind _kindOf(ColumnSchemaSnapshot column) {
    if (column.isEnum) return NativeKind.enumeration;
    switch (_baseType(column)) {
      case 'int':
        return NativeKind.integer;
      case 'double':
      case 'num':
        return NativeKind.real;
      case 'String':
        return NativeKind.text;
      case 'bool':
        return NativeKind.boolean;
      case 'DateTime':
        return NativeKind.dateTime;
      case 'Duration':
        return NativeKind.duration;
      case 'Uri':
        return NativeKind.uri;
      case 'Uint8List':
      case 'List<int>':
        return NativeKind.blob;
    }
    return _kindOfSqlType(column.type);
  }

  static NativeKind _kindOfSqlType(String sqlType) {
    switch (sqlType.toUpperCase()) {
      case 'INTEGER':
        return NativeKind.integer;
      case 'REAL':
      case 'NUMERIC':
        return NativeKind.real;
      case 'BLOB':
        return NativeKind.blob;
      default:
        return NativeKind.text;
    }
  }

  static String _baseType(ColumnSchemaSnapshot column) =>
      column.dartType.replaceAll('?', '');

  static const _knownDartTypes = {
    'int',
    'double',
    'num',
    'String',
    'bool',
    'DateTime',
    'Duration',
    'Uri',
    'Uint8List',
    'List<int>',
  };
}

/// A Dart enum referenced by one or more columns.
class NativeEnum {
  NativeEnum(this.name, this.values);

  final String name;
  final List<String> values;

  /// Collects the enums used by [schemas]. Throws if two models declare
  /// enums with the same name but different constants, since a single native
  /// type can't represent both.
  static List<NativeEnum> collect(List<TableSchemaSnapshot> schemas) {
    final enums = <String, NativeEnum>{};
    for (final schema in schemas) {
      for (final column in schema.columns) {
        final values = column.enumValues;
        if (values == null) continue;
        final name = column.dartType.replaceAll('?', '');
        final existing = enums[name];
        if (existing == null) {
          enums[name] = NativeEnum(name, values);
        } else if (existing.values.join(',') != values.join(',')) {
          throw StateError(
            'Enum "$name" is declared with different values '
            '(${existing.values.join(', ')} vs ${values.join(', ')}). '
            'Native code generation needs one definition per enum name.',
          );
        }
      }
    }
    return enums.values.toList();
  }
}
