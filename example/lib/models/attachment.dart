import 'dart:typed_data';

import 'package:native_sqlite/native_sqlite.dart';

part 'attachment.table.dart';

/// Demonstrates a SQLite BLOB mapped to [Uint8List].
@DbTable(name: 'attachments')
class Attachment {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  final String filename;

  final Uint8List bytes;

  const Attachment({this.id, required this.filename, required this.bytes});
}
