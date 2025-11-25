/// Represents a snapshot of a table schema for migration tracking.
class TableSchemaSnapshot {
  /// The Dart class name
  final String className;

  /// The SQL table name
  final String tableName;

  /// List of column schemas
  final List<ColumnSchemaSnapshot> columns;

  /// List of indexes
  final List<IndexSchemaSnapshot> indexes;

  /// Schema version number
  final int version;

  /// Schema hash for change detection
  final String hash;

  const TableSchemaSnapshot({
    required this.className,
    required this.tableName,
    required this.columns,
    required this.indexes,
    required this.version,
    required this.hash,
  });

  /// Creates a snapshot from TableInfo
  factory TableSchemaSnapshot.fromTableInfo(
    String className,
    String tableName,
    List<ColumnSchemaSnapshot> columns,
    List<IndexSchemaSnapshot> indexes,
    int version,
  ) {
    final hash = _generateHash(tableName, columns, indexes);
    return TableSchemaSnapshot(
      className: className,
      tableName: tableName,
      columns: columns,
      indexes: indexes,
      version: version,
      hash: hash,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'tableName': tableName,
      'columns': columns.map((c) => c.toJson()).toList(),
      'indexes': indexes.map((i) => i.toJson()).toList(),
      'version': version,
      'hash': hash,
    };
  }

  /// Creates from JSON
  factory TableSchemaSnapshot.fromJson(Map<String, dynamic> json) {
    return TableSchemaSnapshot(
      className: json['className'] as String,
      tableName: json['tableName'] as String,
      columns: (json['columns'] as List)
          .map((c) => ColumnSchemaSnapshot.fromJson(c as Map<String, dynamic>))
          .toList(),
      indexes: (json['indexes'] as List)
          .map((i) => IndexSchemaSnapshot.fromJson(i as Map<String, dynamic>))
          .toList(),
      version: json['version'] as int,
      hash: json['hash'] as String,
    );
  }

  /// Generates a hash for change detection
  static String _generateHash(
    String tableName,
    List<ColumnSchemaSnapshot> columns,
    List<IndexSchemaSnapshot> indexes,
  ) {
    final buffer = StringBuffer();
    buffer.write(tableName);
    for (final column in columns) {
      buffer.write('|${column.name}:${column.type}:${column.nullable}:'
          '${column.primaryKey}:${column.autoIncrement}:${column.unique}:'
          '${column.defaultValue}');
    }
    for (final index in indexes) {
      buffer.write('|idx:${index.columns.join(',')}:${index.unique}');
    }
    return buffer.toString().hashCode.toRadixString(16);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableSchemaSnapshot && other.hash == hash;
  }

  @override
  int get hashCode => hash.hashCode;
}

/// Represents a snapshot of a column schema.
class ColumnSchemaSnapshot {
  /// Column name in Dart
  final String dartName;

  /// Column name in SQL
  final String name;

  /// SQL column type
  final String type;

  /// Whether the column is nullable
  final bool nullable;

  /// Whether this is a primary key
  final bool primaryKey;

  /// Whether primary key is auto-increment
  final bool autoIncrement;

  /// Whether the column has a unique constraint
  final bool unique;

  /// Default value expression
  final String? defaultValue;

  /// Foreign key reference (table.column)
  final String? foreignKey;

  /// Whether this is a JSON field
  final bool isJsonField;

  /// Whether this uses a custom converter
  final bool hasConverter;

  /// Dart type name
  final String dartType;

  const ColumnSchemaSnapshot({
    required this.dartName,
    required this.name,
    required this.type,
    required this.nullable,
    required this.primaryKey,
    required this.autoIncrement,
    required this.unique,
    this.defaultValue,
    this.foreignKey,
    required this.isJsonField,
    required this.hasConverter,
    required this.dartType,
  });

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'dartName': dartName,
      'name': name,
      'type': type,
      'nullable': nullable,
      'primaryKey': primaryKey,
      'autoIncrement': autoIncrement,
      'unique': unique,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (foreignKey != null) 'foreignKey': foreignKey,
      'isJsonField': isJsonField,
      'hasConverter': hasConverter,
      'dartType': dartType,
    };
  }

  /// Creates from JSON
  factory ColumnSchemaSnapshot.fromJson(Map<String, dynamic> json) {
    return ColumnSchemaSnapshot(
      dartName: json['dartName'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      nullable: json['nullable'] as bool,
      primaryKey: json['primaryKey'] as bool,
      autoIncrement: json['autoIncrement'] as bool,
      unique: json['unique'] as bool,
      defaultValue: json['defaultValue'] as String?,
      foreignKey: json['foreignKey'] as String?,
      isJsonField: json['isJsonField'] as bool,
      hasConverter: json['hasConverter'] as bool,
      dartType: json['dartType'] as String,
    );
  }
}

/// Represents a snapshot of an index schema.
class IndexSchemaSnapshot {
  /// Columns in the index
  final List<String> columns;

  /// Whether this is a unique index
  final bool unique;

  const IndexSchemaSnapshot({
    required this.columns,
    required this.unique,
  });

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'columns': columns,
      'unique': unique,
    };
  }

  /// Creates from JSON
  factory IndexSchemaSnapshot.fromJson(Map<String, dynamic> json) {
    return IndexSchemaSnapshot(
      columns: (json['columns'] as List).cast<String>(),
      unique: json['unique'] as bool,
    );
  }
}
