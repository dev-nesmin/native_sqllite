// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'tag.dart';

/// Generated table schema for [Tag].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class TagSchema {
  static const String tableName = 'tags';

  static const String createTableSql =
      'CREATE TABLE "tags" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "label_text" TEXT NOT NULL)';

  static const List<String> indexSql = [
    'CREATE UNIQUE INDEX "idx_tags_label_unique" ON "tags" ("label_text")',
  ];

  // Column names
  static const String ID = 'id';
  static const String LABEL = 'label_text';
}

Tag _TagFromMap(Map<String, Object?> map) {
  return Tag(id: map['id'] as int?, label: map['label_text'] as String);
}

/// Generated query builder for [Tag].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class TagQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  TagQueryBuilder(this._database);

  /// Filter where id equals [value].
  TagQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  TagQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  TagQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  TagQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  TagQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  TagQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where label equals [value].
  TagQueryBuilder labelEqualTo(String value) {
    _whereConditions.add('"label_text" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where label contains [value].
  TagQueryBuilder labelContains(String value) {
    _whereConditions.add('"label_text" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where label starts with [value].
  TagQueryBuilder labelStartsWith(String value) {
    _whereConditions.add('"label_text" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where label ends with [value].
  TagQueryBuilder labelEndsWith(String value) {
    _whereConditions.add('"label_text" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Sort by id in ascending order.
  TagQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  TagQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  TagQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  TagQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by label in ascending order.
  TagQueryBuilder sortByLabelAsc() {
    _orderBy
      ..clear()
      ..add('"label_text" ASC');
    return this;
  }

  /// Sort by label in descending order.
  TagQueryBuilder sortByLabelDesc() {
    _orderBy
      ..clear()
      ..add('"label_text" DESC');
    return this;
  }

  /// Then sort by label in ascending order.
  TagQueryBuilder thenByLabelAsc() {
    _orderBy.add('"label_text" ASC');
    return this;
  }

  /// Then sort by label in descending order.
  TagQueryBuilder thenByLabelDesc() {
    _orderBy.add('"label_text" DESC');
    return this;
  }

  /// Limit the number of results.
  TagQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  TagQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Tag>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_TagFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Tag?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _TagFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "tags"$whereClause';
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
      'tags',
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
    return 'SELECT * FROM "tags"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Tag].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class TagRepository {
  final NativeSqliteDatabase database;

  const TagRepository(this.database);

  /// Inserts a new Tag into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(Tag entity) async {
    final rowId = await database.insert('tags', {'label_text': entity.label});
    return rowId;
  }

  /// Finds a Tag by its ID.
  /// Returns null if not found.
  Future<Tag?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "tags" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _TagFromMap(rows.first);
  }

  /// Finds all Tags in the database.
  Future<List<Tag>> findAll() async {
    final result = await database.query('SELECT * FROM "tags"');

    return result.toMapList().map(_TagFromMap).toList();
  }

  /// Updates an existing Tag in the database.
  /// Returns the number of rows affected.
  Future<int> update(Tag entity) async {
    return database.update(
      'tags',
      {'label_text': entity.label},
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Tag by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('tags', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('tags');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query('SELECT COUNT(*) as count FROM "tags"');

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  TagQueryBuilder queryBuilder() {
    return TagQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Tag objects.
  Future<List<Tag>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_TagFromMap).toList();
  }
}
