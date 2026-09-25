import 'package:native_sqlite/native_sqlite.dart';

part 'tag.table.dart';

/// Demonstrates a named, unique class-level index and renamed SQL column.
@Index(name: 'idx_tags_label_unique', columns: ['label_text'], unique: true)
@DbTable(name: 'tags')
class Tag {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(name: 'label_text')
  final String label;

  const Tag({this.id, required this.label});
}
