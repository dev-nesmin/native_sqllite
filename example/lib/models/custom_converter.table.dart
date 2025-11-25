// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'custom_converter.dart';

// Table schema for StyledItem
abstract class StyledItemSchema {
  static const String tableName = 'styled_items';

  static const String createTableSql = '''
    CREATE TABLE styled_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      background_color INTEGER NOT NULL,
      text_color INTEGER,
      tags TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String BACKGROUND_COLOR = 'background_color';
  static const String TEXT_COLOR = 'text_color';
  static const String TAGS = 'tags';
  static const String CREATED_AT = 'created_at';
}

// Query builder for StyledItem
class StyledItemQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  StyledItemQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  StyledItemQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  StyledItemQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  StyledItemQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  StyledItemQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where textColor is null.
  StyledItemQueryBuilder textColorIsNull() {
    _whereConditions.add('text_color IS NULL');
    return this;
  }

  /// Filter where textColor is not null.
  StyledItemQueryBuilder textColorIsNotNull() {
    _whereConditions.add('text_color IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  StyledItemQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  StyledItemQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  StyledItemQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  StyledItemQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Sort by id in ascending order.
  StyledItemQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  StyledItemQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  StyledItemQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  StyledItemQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by backgroundColor in ascending order.
  StyledItemQueryBuilder sortByBackgroundColorAsc() {
    _orderBy = 'background_color ASC';
    return this;
  }

  /// Sort by backgroundColor in descending order.
  StyledItemQueryBuilder sortByBackgroundColorDesc() {
    _orderBy = 'background_color DESC';
    return this;
  }

  /// Sort by textColor in ascending order.
  StyledItemQueryBuilder sortByTextColorAsc() {
    _orderBy = 'text_color ASC';
    return this;
  }

  /// Sort by textColor in descending order.
  StyledItemQueryBuilder sortByTextColorDesc() {
    _orderBy = 'text_color DESC';
    return this;
  }

  /// Sort by tags in ascending order.
  StyledItemQueryBuilder sortByTagsAsc() {
    _orderBy = 'tags ASC';
    return this;
  }

  /// Sort by tags in descending order.
  StyledItemQueryBuilder sortByTagsDesc() {
    _orderBy = 'tags DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  StyledItemQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  StyledItemQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Limit the number of results.
  StyledItemQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  StyledItemQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<StyledItem>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<StyledItem?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM styled_items$whereClause';
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    final rows = result.toMapList();
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  /// Delete all matching records.
  Future<int> deleteAll() async {
    final whereClause = _whereConditions.isEmpty
        ? null
        : _whereConditions.join(' AND ');
    return NativeSqlite.delete(
      _databaseName,
      'styled_items',
      where: whereClause,
      whereArgs: _whereArgs.isEmpty ? null : _whereArgs,
    );
  }

  String _buildQuery() {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final orderClause = _orderBy == null ? '' : ' ORDER BY $_orderBy';
    final limitClause = _limit == null ? '' : ' LIMIT $_limit';
    final offsetClause = _offset == null ? '' : ' OFFSET $_offset';
    return 'SELECT * FROM styled_items$whereClause$orderClause$limitClause$offsetClause';
  }

  StyledItem _fromMap(Map<String, Object?> map) {
    return StyledItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      backgroundColor: const ColorConverter().fromSql(
        map['background_color'] as int,
      ),
      textColor: map['text_color'] != null
          ? const ColorConverter().fromSql(map['text_color'] as int)
          : null,
      tags: const StringListConverter().fromSql(map['tags'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

// Repository for StyledItem
class StyledItemRepository {
  final String databaseName;

  const StyledItemRepository([this.databaseName = 'example_app']);

  /// Inserts a new StyledItem into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(StyledItem entity) async {
    return NativeSqlite.insert(databaseName, 'styled_items', {
      'name': entity.name,
      'background_color': const ColorConverter().toSql(entity.backgroundColor),
      'text_color': entity.textColor != null
          ? const ColorConverter().toSql(entity.textColor!)
          : null,
      'tags': const StringListConverter().toSql(entity.tags),
      'created_at': entity.createdAt.millisecondsSinceEpoch,
    });
  }

  /// Finds a StyledItem by its ID.
  /// Returns null if not found.
  Future<StyledItem?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM styled_items WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all StyledItems in the database.
  Future<List<StyledItem>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM styled_items',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing StyledItem in the database.
  /// Returns the number of rows affected.
  Future<int> update(StyledItem entity) async {
    return NativeSqlite.update(
      databaseName,
      'styled_items',
      {
        'name': entity.name,
        'background_color': const ColorConverter().toSql(
          entity.backgroundColor,
        ),
        'text_color': entity.textColor != null
            ? const ColorConverter().toSql(entity.textColor!)
            : null,
        'tags': const StringListConverter().toSql(entity.tags),
        'created_at': entity.createdAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a StyledItem by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'styled_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'styled_items');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM styled_items',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  StyledItemQueryBuilder queryBuilder() {
    return StyledItemQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as StyledItem objects.
  Future<List<StyledItem>> query(String sql, [List<Object?>? arguments]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a StyledItem object.
  StyledItem _fromMap(Map<String, Object?> map) {
    return StyledItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      backgroundColor: const ColorConverter().fromSql(
        map['background_color'] as int,
      ),
      textColor: map['text_color'] != null
          ? const ColorConverter().fromSql(map['text_color'] as int)
          : null,
      tags: const StringListConverter().fromSql(map['tags'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
