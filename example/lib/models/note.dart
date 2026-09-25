import 'package:native_sqlite/native_sqlite.dart';

part 'note.table.dart';

/// Demonstrates a UUID primary key generated consistently by Dart and native
/// repositories.
@DbTable(name: 'notes')
class Note {
  @PrimaryKey(useLocalUuid: true)
  final String? id;

  final String body;

  const Note({this.id, required this.body});
}
