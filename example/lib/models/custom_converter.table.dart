// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'custom_converter.dart';

/// Generated table schema for [StyledItem].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class StyledItemSchema {
  static const String tableName = 'styled_items';

  static const String createTableSql =
      'CREATE TABLE "styled_items" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "background_color" INTEGER NOT NULL, "text_color" INTEGER, "tags" TEXT NOT NULL, "created_at" INTEGER NOT NULL)';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String BACKGROUND_COLOR = 'background_color';
  static const String TEXT_COLOR = 'text_color';
  static const String TAGS = 'tags';
  static const String CREATED_AT = 'created_at';
}

StyledItem _StyledItemFromMap(Map<String, Object?> map) {
  return StyledItem(
    id: map['id'] as int?,
    name: map['name'] as String,
    backgroundColor: const ColorConverter().fromSql(
      map['background_color'] as int,
    ),
    textColor: map['text_color'] != null
        ? const ColorConverter().fromSql(map['text_color'] as int)
        : null,
    tags: (NativeSqliteCodec.jsonDecode(map['tags'] as String) as List)
        .cast<String>(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// Generated query builder for [StyledItem].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class StyledItemQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  StyledItemQueryBuilder(this._database);

  /// Filter where id equals [value].
  StyledItemQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  StyledItemQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  StyledItemQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  StyledItemQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  StyledItemQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  StyledItemQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where name equals [value].
  StyledItemQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('"name" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  StyledItemQueryBuilder nameContains(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name starts with [value].
  StyledItemQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name ends with [value].
  StyledItemQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where textColor is null.
  StyledItemQueryBuilder textColorIsNull() {
    _whereConditions.add('"text_color" IS NULL');
    return this;
  }

  /// Filter where textColor is not null.
  StyledItemQueryBuilder textColorIsNotNull() {
    _whereConditions.add('"text_color" IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  StyledItemQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('"created_at" = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  StyledItemQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('"created_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  StyledItemQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('"created_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  StyledItemQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"created_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Sort by id in ascending order.
  StyledItemQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  StyledItemQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  StyledItemQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  StyledItemQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by name in ascending order.
  StyledItemQueryBuilder sortByNameAsc() {
    _orderBy
      ..clear()
      ..add('"name" ASC');
    return this;
  }

  /// Sort by name in descending order.
  StyledItemQueryBuilder sortByNameDesc() {
    _orderBy
      ..clear()
      ..add('"name" DESC');
    return this;
  }

  /// Then sort by name in ascending order.
  StyledItemQueryBuilder thenByNameAsc() {
    _orderBy.add('"name" ASC');
    return this;
  }

  /// Then sort by name in descending order.
  StyledItemQueryBuilder thenByNameDesc() {
    _orderBy.add('"name" DESC');
    return this;
  }

  /// Sort by backgroundColor in ascending order.
  StyledItemQueryBuilder sortByBackgroundColorAsc() {
    _orderBy
      ..clear()
      ..add('"background_color" ASC');
    return this;
  }

  /// Sort by backgroundColor in descending order.
  StyledItemQueryBuilder sortByBackgroundColorDesc() {
    _orderBy
      ..clear()
      ..add('"background_color" DESC');
    return this;
  }

  /// Then sort by backgroundColor in ascending order.
  StyledItemQueryBuilder thenByBackgroundColorAsc() {
    _orderBy.add('"background_color" ASC');
    return this;
  }

  /// Then sort by backgroundColor in descending order.
  StyledItemQueryBuilder thenByBackgroundColorDesc() {
    _orderBy.add('"background_color" DESC');
    return this;
  }

  /// Sort by textColor in ascending order.
  StyledItemQueryBuilder sortByTextColorAsc() {
    _orderBy
      ..clear()
      ..add('"text_color" ASC');
    return this;
  }

  /// Sort by textColor in descending order.
  StyledItemQueryBuilder sortByTextColorDesc() {
    _orderBy
      ..clear()
      ..add('"text_color" DESC');
    return this;
  }

  /// Then sort by textColor in ascending order.
  StyledItemQueryBuilder thenByTextColorAsc() {
    _orderBy.add('"text_color" ASC');
    return this;
  }

  /// Then sort by textColor in descending order.
  StyledItemQueryBuilder thenByTextColorDesc() {
    _orderBy.add('"text_color" DESC');
    return this;
  }

  /// Sort by tags in ascending order.
  StyledItemQueryBuilder sortByTagsAsc() {
    _orderBy
      ..clear()
      ..add('"tags" ASC');
    return this;
  }

  /// Sort by tags in descending order.
  StyledItemQueryBuilder sortByTagsDesc() {
    _orderBy
      ..clear()
      ..add('"tags" DESC');
    return this;
  }

  /// Then sort by tags in ascending order.
  StyledItemQueryBuilder thenByTagsAsc() {
    _orderBy.add('"tags" ASC');
    return this;
  }

  /// Then sort by tags in descending order.
  StyledItemQueryBuilder thenByTagsDesc() {
    _orderBy.add('"tags" DESC');
    return this;
  }

  /// Sort by createdAt in ascending order.
  StyledItemQueryBuilder sortByCreatedAtAsc() {
    _orderBy
      ..clear()
      ..add('"created_at" ASC');
    return this;
  }

  /// Sort by createdAt in descending order.
  StyledItemQueryBuilder sortByCreatedAtDesc() {
    _orderBy
      ..clear()
      ..add('"created_at" DESC');
    return this;
  }

  /// Then sort by createdAt in ascending order.
  StyledItemQueryBuilder thenByCreatedAtAsc() {
    _orderBy.add('"created_at" ASC');
    return this;
  }

  /// Then sort by createdAt in descending order.
  StyledItemQueryBuilder thenByCreatedAtDesc() {
    _orderBy.add('"created_at" DESC');
    return this;
  }

  /// Limit the number of results.
  StyledItemQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  StyledItemQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<StyledItem>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_StyledItemFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<StyledItem?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _StyledItemFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "styled_items"$whereClause';
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
      'styled_items',
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
    return 'SELECT * FROM "styled_items"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [StyledItem].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class StyledItemRepository {
  final NativeSqliteDatabase database;

  const StyledItemRepository(this.database);

  /// Inserts a new StyledItem into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(StyledItem entity) async {
    final rowId = await database.insert('styled_items', {
      'name': entity.name,
      'background_color': const ColorConverter().toSql(entity.backgroundColor),
      'text_color': entity.textColor != null
          ? const ColorConverter().toSql(entity.textColor!)
          : null,
      'tags': NativeSqliteCodec.jsonEncode(entity.tags),
      'created_at': entity.createdAt.millisecondsSinceEpoch,
    });
    return rowId;
  }

  /// Finds a StyledItem by its ID.
  /// Returns null if not found.
  Future<StyledItem?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "styled_items" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _StyledItemFromMap(rows.first);
  }

  /// Finds all StyledItems in the database.
  Future<List<StyledItem>> findAll() async {
    final result = await database.query('SELECT * FROM "styled_items"');

    return result.toMapList().map(_StyledItemFromMap).toList();
  }

  /// Updates an existing StyledItem in the database.
  /// Returns the number of rows affected.
  Future<int> update(StyledItem entity) async {
    return database.update(
      'styled_items',
      {
        'name': entity.name,
        'background_color': const ColorConverter().toSql(
          entity.backgroundColor,
        ),
        'text_color': entity.textColor != null
            ? const ColorConverter().toSql(entity.textColor!)
            : null,
        'tags': NativeSqliteCodec.jsonEncode(entity.tags),
        'created_at': entity.createdAt.millisecondsSinceEpoch,
      },
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a StyledItem by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('styled_items', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('styled_items');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "styled_items"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  StyledItemQueryBuilder queryBuilder() {
    return StyledItemQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as StyledItem objects.
  Future<List<StyledItem>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_StyledItemFromMap).toList();
  }
}
