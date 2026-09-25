import 'package:native_sqlite_generator/src/models/column_info.dart';

/// A database column mapped to a parameter of the model's unnamed
/// constructor.
class ConstructorParameterInfo {
  const ConstructorParameterInfo({required this.column, required this.isNamed});

  final ColumnInfo column;
  final bool isNamed;
}
