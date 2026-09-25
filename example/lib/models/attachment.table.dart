// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'attachment.dart';

/// Generated table schema for [Attachment].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class AttachmentSchema {
  static const String tableName = 'attachments';

  static const String createTableSql =
      'CREATE TABLE "attachments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "filename" TEXT NOT NULL, "bytes" BLOB NOT NULL)';

  // Column names
  static const String ID = 'id';
  static const String FILENAME = 'filename';
  static const String BYTES = 'bytes';
}

Attachment _AttachmentFromMap(Map<String, Object?> map) {
  return Attachment(
    id: map['id'] as int?,
    filename: map['filename'] as String,
    bytes: map['bytes'] as Uint8List,
  );
}

/// Generated query builder for [Attachment].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class AttachmentQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  AttachmentQueryBuilder(this._database);

  /// Filter where id equals [value].
  AttachmentQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  AttachmentQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  AttachmentQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  AttachmentQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  AttachmentQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  AttachmentQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where filename equals [value].
  AttachmentQueryBuilder filenameEqualTo(String value) {
    _whereConditions.add('"filename" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where filename contains [value].
  AttachmentQueryBuilder filenameContains(String value) {
    _whereConditions.add('"filename" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where filename starts with [value].
  AttachmentQueryBuilder filenameStartsWith(String value) {
    _whereConditions.add('"filename" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where filename ends with [value].
  AttachmentQueryBuilder filenameEndsWith(String value) {
    _whereConditions.add('"filename" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Sort by id in ascending order.
  AttachmentQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  AttachmentQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  AttachmentQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  AttachmentQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by filename in ascending order.
  AttachmentQueryBuilder sortByFilenameAsc() {
    _orderBy
      ..clear()
      ..add('"filename" ASC');
    return this;
  }

  /// Sort by filename in descending order.
  AttachmentQueryBuilder sortByFilenameDesc() {
    _orderBy
      ..clear()
      ..add('"filename" DESC');
    return this;
  }

  /// Then sort by filename in ascending order.
  AttachmentQueryBuilder thenByFilenameAsc() {
    _orderBy.add('"filename" ASC');
    return this;
  }

  /// Then sort by filename in descending order.
  AttachmentQueryBuilder thenByFilenameDesc() {
    _orderBy.add('"filename" DESC');
    return this;
  }

  /// Sort by bytes in ascending order.
  AttachmentQueryBuilder sortByBytesAsc() {
    _orderBy
      ..clear()
      ..add('"bytes" ASC');
    return this;
  }

  /// Sort by bytes in descending order.
  AttachmentQueryBuilder sortByBytesDesc() {
    _orderBy
      ..clear()
      ..add('"bytes" DESC');
    return this;
  }

  /// Then sort by bytes in ascending order.
  AttachmentQueryBuilder thenByBytesAsc() {
    _orderBy.add('"bytes" ASC');
    return this;
  }

  /// Then sort by bytes in descending order.
  AttachmentQueryBuilder thenByBytesDesc() {
    _orderBy.add('"bytes" DESC');
    return this;
  }

  /// Limit the number of results.
  AttachmentQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  AttachmentQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Attachment>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_AttachmentFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Attachment?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _AttachmentFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "attachments"$whereClause';
    final result = await _database.query(sql, _whereArgs);
    final rows = result.toMapList();
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  /// Delete all matching records.
  Future<int> deleteAll() async {
    final whereClause = _whereConditions.isEmpty
        ? null
        : _whereConditions.join(' AND ');
    return _database.delete(
      'attachments',
      where: whereClause,
      whereArgs: _whereArgs.isEmpty ? null : _whereArgs,
    );
  }

  /// The parameterized SQL represented by this builder.
  String toSql() => _buildQuery();

  /// Alias for [toSql], intended for logs and debuggers.
  String get debugSql => toSql();

  /// Bound values in placeholder order.
  List<Object?> get arguments => List<Object?>.unmodifiable(_whereArgs);

  String _buildQuery({int? limitOverride}) {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final orderClause = _orderBy.isEmpty
        ? ''
        : ' ORDER BY ${_orderBy.join(', ')}';
    final effectiveLimit = limitOverride ?? _limit;
    final limitClause = effectiveLimit != null
        ? ' LIMIT $effectiveLimit'
        : (_offset == null ? '' : ' LIMIT -1');
    final offsetClause = _offset == null ? '' : ' OFFSET $_offset';
    return 'SELECT * FROM "attachments"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Attachment].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class AttachmentRepository {
  final NativeSqliteDatabase database;

  const AttachmentRepository(this.database);

  /// Inserts a new Attachment into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(Attachment entity) async {
    final rowId = await database.insert('attachments', {
      'filename': entity.filename,
      'bytes': entity.bytes,
    });
    return rowId;
  }

  /// Finds a Attachment by its ID.
  /// Returns null if not found.
  Future<Attachment?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "attachments" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _AttachmentFromMap(rows.first);
  }

  /// Finds all Attachments in the database.
  Future<List<Attachment>> findAll() async {
    final result = await database.query('SELECT * FROM "attachments"');

    return result.toMapList().map(_AttachmentFromMap).toList();
  }

  /// Updates an existing Attachment in the database.
  /// Returns the number of rows affected.
  Future<int> update(Attachment entity) async {
    return database.update(
      'attachments',
      {'filename': entity.filename, 'bytes': entity.bytes},
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Attachment by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('attachments', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('attachments');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "attachments"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  AttachmentQueryBuilder queryBuilder() {
    return AttachmentQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Attachment objects.
  Future<List<Attachment>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_AttachmentFromMap).toList();
  }
}
