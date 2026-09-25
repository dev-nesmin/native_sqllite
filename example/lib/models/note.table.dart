// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'note.dart';

/// Generated table schema for [Note].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class NoteSchema {
  static const String tableName = 'notes';

  static const String createTableSql =
      'CREATE TABLE "notes" ("id" TEXT PRIMARY KEY NOT NULL, "body" TEXT NOT NULL)';

  // Column names
  static const String ID = 'id';
  static const String BODY = 'body';
}

Note _NoteFromMap(Map<String, Object?> map) {
  return Note(id: map['id'] as String?, body: map['body'] as String);
}

/// Generated query builder for [Note].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class NoteQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  NoteQueryBuilder(this._database);

  /// Filter where id equals [value].
  NoteQueryBuilder idEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id contains [value].
  NoteQueryBuilder idContains(String value) {
    _whereConditions.add('"id" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where id starts with [value].
  NoteQueryBuilder idStartsWith(String value) {
    _whereConditions.add('"id" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where id ends with [value].
  NoteQueryBuilder idEndsWith(String value) {
    _whereConditions.add('"id" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where id is null.
  NoteQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  NoteQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where body equals [value].
  NoteQueryBuilder bodyEqualTo(String value) {
    _whereConditions.add('"body" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where body contains [value].
  NoteQueryBuilder bodyContains(String value) {
    _whereConditions.add('"body" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where body starts with [value].
  NoteQueryBuilder bodyStartsWith(String value) {
    _whereConditions.add('"body" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where body ends with [value].
  NoteQueryBuilder bodyEndsWith(String value) {
    _whereConditions.add('"body" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Sort by id in ascending order.
  NoteQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  NoteQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  NoteQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  NoteQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by body in ascending order.
  NoteQueryBuilder sortByBodyAsc() {
    _orderBy
      ..clear()
      ..add('"body" ASC');
    return this;
  }

  /// Sort by body in descending order.
  NoteQueryBuilder sortByBodyDesc() {
    _orderBy
      ..clear()
      ..add('"body" DESC');
    return this;
  }

  /// Then sort by body in ascending order.
  NoteQueryBuilder thenByBodyAsc() {
    _orderBy.add('"body" ASC');
    return this;
  }

  /// Then sort by body in descending order.
  NoteQueryBuilder thenByBodyDesc() {
    _orderBy.add('"body" DESC');
    return this;
  }

  /// Limit the number of results.
  NoteQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  NoteQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Note>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_NoteFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Note?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _NoteFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "notes"$whereClause';
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
      'notes',
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
    return 'SELECT * FROM "notes"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Note].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class NoteRepository {
  final NativeSqliteDatabase database;

  const NoteRepository(this.database);

  /// Inserts a new Note into the database.
  /// Returns the ID of the inserted row.
  Future<String> insert(Note entity) async {
    final primaryKeyValue = entity.id ?? NativeSqliteUuid.generate();
    await database.insert('notes', {
      'id': primaryKeyValue,
      'body': entity.body,
    });
    return primaryKeyValue;
  }

  /// Finds a Note by its ID.
  /// Returns null if not found.
  Future<Note?> findById(String? id) async {
    final result = await database.query(
      'SELECT * FROM "notes" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _NoteFromMap(rows.first);
  }

  /// Finds all Notes in the database.
  Future<List<Note>> findAll() async {
    final result = await database.query('SELECT * FROM "notes"');

    return result.toMapList().map(_NoteFromMap).toList();
  }

  /// Updates an existing Note in the database.
  /// Returns the number of rows affected.
  Future<int> update(Note entity) async {
    return database.update(
      'notes',
      {'body': entity.body},
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Note by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(String? id) async {
    return database.delete('notes', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('notes');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "notes"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  NoteQueryBuilder queryBuilder() {
    return NoteQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Note objects.
  Future<List<Note>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_NoteFromMap).toList();
  }
}
