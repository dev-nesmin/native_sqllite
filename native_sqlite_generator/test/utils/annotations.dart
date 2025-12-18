final mockAnnotationsPackage = {
  'native_sqlite_annotations|lib/native_sqlite_annotations.dart': '''
library native_sqlite_annotations;

export 'src/table.dart';
export 'src/column.dart';
export 'src/primary_key.dart';
export 'src/foreign_key.dart';
export 'src/index.dart';
export 'src/ignore.dart';
export 'src/json_field.dart';
export 'src/enum.dart';
export 'src/type_converter.dart';
''',
  'native_sqlite_annotations|lib/src/table.dart': '''
class DbTable {
  final String? name;
  final List<List<String>>? indexes;
  final String? database;
  const DbTable({this.name, this.indexes, this.database});
}
''',
  'native_sqlite_annotations|lib/src/column.dart': '''
class DbColumn {
  final String? name;
  final String? type;
  final String? defaultValue;
  final bool? unique;
  final bool? nullable;
  const DbColumn({this.name, this.type, this.defaultValue, this.unique, this.nullable});
}
''',
  'native_sqlite_annotations|lib/src/primary_key.dart': '''
class PrimaryKey {
  final bool autoIncrement;
  final bool useLocalUuid;
  const PrimaryKey({this.autoIncrement = false, this.useLocalUuid = false});
}
''',
  'native_sqlite_annotations|lib/src/foreign_key.dart': '''
class ForeignKey {
  final String table;
  final String column;
  final String? onDelete;
  final String? onUpdate;
  const ForeignKey(this.table, this.column, {this.onDelete, this.onUpdate});
}
''',
  'native_sqlite_annotations|lib/src/index.dart': '''
class Index {
  final List<String> columns;
  final bool unique;
  final String? name;
  const Index(this.columns, {this.unique = false, this.name});
}
''',
  'native_sqlite_annotations|lib/src/ignore.dart': '''
class Ignore {
  const Ignore();
}
''',
  'native_sqlite_annotations|lib/src/json_field.dart': '''
class JsonField {
  const JsonField();
}
''',
  'native_sqlite_annotations|lib/src/enum.dart': '''
class EnumField {
  const EnumField();
}
''',
  'native_sqlite_annotations|lib/src/type_converter.dart': '''
class UseConverter {
  final Type parser;
  const UseConverter(this.parser);
}
abstract class TypeConverter<T, S> {
  const TypeConverter();
  T decode(S databaseValue);
  S encode(T value);
}
''',
};
