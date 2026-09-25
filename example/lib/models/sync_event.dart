import 'package:native_sqlite/native_sqlite.dart';

part 'sync_event.table.dart';

/// A row written by Dart or a platform-native background task.
@DbTable(
  name: 'sync_events',
  indexes: [
    ['createdAt'],
  ],
)
class SyncEvent {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  final String source;

  final String message;

  final DateTime createdAt;

  SyncEvent({
    this.id,
    required this.source,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
