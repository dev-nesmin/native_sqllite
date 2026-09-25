// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'comment.dart';

/// Generated table schema for [Comment].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class CommentSchema {
  static const String tableName = 'comments';

  static const String createTableSql =
      'CREATE TABLE "comments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "parent_id" INTEGER, "body" TEXT NOT NULL, FOREIGN KEY ("parent_id") REFERENCES "comments"("id") ON DELETE SET NULL)';

  // Column names
  static const String ID = 'id';
  static const String PARENT_ID = 'parent_id';
  static const String BODY = 'body';
}

Comment _CommentFromMap(Map<String, Object?> map) {
  return Comment(
    id: map['id'] as int?,
    parentId: map['parent_id'] as int?,
    body: map['body'] as String,
  );
}

/// Generated query builder for [Comment].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class CommentQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  CommentQueryBuilder(this._database);

  /// Filter where id equals [value].
  CommentQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  CommentQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  CommentQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  CommentQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  CommentQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  CommentQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where parentId equals [value].
  CommentQueryBuilder parentIdEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"parent_id" IS NULL');
    } else {
      _whereConditions.add('"parent_id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where parentId is greater than [value].
  CommentQueryBuilder parentIdGreaterThan(int value) {
    _whereConditions.add('"parent_id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where parentId is less than [value].
  CommentQueryBuilder parentIdLessThan(int value) {
    _whereConditions.add('"parent_id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where parentId is between [min] and [max].
  CommentQueryBuilder parentIdBetween(int min, int max) {
    _whereConditions.add('"parent_id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where parentId is null.
  CommentQueryBuilder parentIdIsNull() {
    _whereConditions.add('"parent_id" IS NULL');
    return this;
  }

  /// Filter where parentId is not null.
  CommentQueryBuilder parentIdIsNotNull() {
    _whereConditions.add('"parent_id" IS NOT NULL');
    return this;
  }

  /// Filter where body equals [value].
  CommentQueryBuilder bodyEqualTo(String value) {
    _whereConditions.add('"body" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where body contains [value].
  CommentQueryBuilder bodyContains(String value) {
    _whereConditions.add('"body" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where body starts with [value].
  CommentQueryBuilder bodyStartsWith(String value) {
    _whereConditions.add('"body" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where body ends with [value].
  CommentQueryBuilder bodyEndsWith(String value) {
    _whereConditions.add('"body" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Sort by id in ascending order.
  CommentQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  CommentQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  CommentQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  CommentQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by parentId in ascending order.
  CommentQueryBuilder sortByParentIdAsc() {
    _orderBy
      ..clear()
      ..add('"parent_id" ASC');
    return this;
  }

  /// Sort by parentId in descending order.
  CommentQueryBuilder sortByParentIdDesc() {
    _orderBy
      ..clear()
      ..add('"parent_id" DESC');
    return this;
  }

  /// Then sort by parentId in ascending order.
  CommentQueryBuilder thenByParentIdAsc() {
    _orderBy.add('"parent_id" ASC');
    return this;
  }

  /// Then sort by parentId in descending order.
  CommentQueryBuilder thenByParentIdDesc() {
    _orderBy.add('"parent_id" DESC');
    return this;
  }

  /// Sort by body in ascending order.
  CommentQueryBuilder sortByBodyAsc() {
    _orderBy
      ..clear()
      ..add('"body" ASC');
    return this;
  }

  /// Sort by body in descending order.
  CommentQueryBuilder sortByBodyDesc() {
    _orderBy
      ..clear()
      ..add('"body" DESC');
    return this;
  }

  /// Then sort by body in ascending order.
  CommentQueryBuilder thenByBodyAsc() {
    _orderBy.add('"body" ASC');
    return this;
  }

  /// Then sort by body in descending order.
  CommentQueryBuilder thenByBodyDesc() {
    _orderBy.add('"body" DESC');
    return this;
  }

  /// Limit the number of results.
  CommentQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  CommentQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Comment>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_CommentFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Comment?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _CommentFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "comments"$whereClause';
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
      'comments',
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
    return 'SELECT * FROM "comments"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Comment].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class CommentRepository {
  final NativeSqliteDatabase database;

  const CommentRepository(this.database);

  /// Inserts a new Comment into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(Comment entity) async {
    final rowId = await database.insert('comments', {
      'parent_id': entity.parentId,
      'body': entity.body,
    });
    return rowId;
  }

  /// Finds a Comment by its ID.
  /// Returns null if not found.
  Future<Comment?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "comments" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _CommentFromMap(rows.first);
  }

  /// Finds all Comments in the database.
  Future<List<Comment>> findAll() async {
    final result = await database.query('SELECT * FROM "comments"');

    return result.toMapList().map(_CommentFromMap).toList();
  }

  /// Updates an existing Comment in the database.
  /// Returns the number of rows affected.
  Future<int> update(Comment entity) async {
    return database.update(
      'comments',
      {'parent_id': entity.parentId, 'body': entity.body},
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Comment by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('comments', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('comments');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "comments"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  CommentQueryBuilder queryBuilder() {
    return CommentQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Comment objects.
  Future<List<Comment>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_CommentFromMap).toList();
  }
}
