import 'package:native_sqlite/native_sqlite.dart';

part 'comment.table.dart';

/// Demonstrates a nullable self-reference with `ON DELETE SET NULL`.
@DbTable(name: 'comments')
class Comment {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @ForeignKey(table: 'comments', column: 'id', onDelete: 'SET NULL')
  final int? parentId;

  final String body;

  const Comment({this.id, this.parentId, required this.body});
}
