import 'package:native_sqlite/native_sqlite.dart';

part 'manual_log.table.dart';

/// A table whose lifecycle is intentionally managed by application SQL.
@DbTable(name: 'manual_logs', auto: false)
class ManualLog {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  final String message;

  const ManualLog({this.id, required this.message});
}
