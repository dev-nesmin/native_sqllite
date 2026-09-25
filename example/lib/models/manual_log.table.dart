// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'manual_log.dart';

/// Generated table schema for [ManualLog].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class ManualLogSchema {
  static const String tableName = 'manual_logs';

  static const String createTableSql =
      'CREATE TABLE "manual_logs" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "message" TEXT NOT NULL)';

  // Column names
  static const String ID = 'id';
  static const String MESSAGE = 'message';
}

ManualLog _ManualLogFromMap(Map<String, Object?> map) {
  return ManualLog(id: map['id'] as int?, message: map['message'] as String);
}

/// Generated query builder for [ManualLog].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class ManualLogQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  ManualLogQueryBuilder(this._database);

  /// Filter where id equals [value].
  ManualLogQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  ManualLogQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  ManualLogQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  ManualLogQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  ManualLogQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  ManualLogQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where message equals [value].
  ManualLogQueryBuilder messageEqualTo(String value) {
    _whereConditions.add('"message" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where message contains [value].
  ManualLogQueryBuilder messageContains(String value) {
    _whereConditions.add('"message" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where message starts with [value].
  ManualLogQueryBuilder messageStartsWith(String value) {
    _whereConditions.add('"message" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where message ends with [value].
  ManualLogQueryBuilder messageEndsWith(String value) {
    _whereConditions.add('"message" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Sort by id in ascending order.
  ManualLogQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  ManualLogQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  ManualLogQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  ManualLogQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by message in ascending order.
  ManualLogQueryBuilder sortByMessageAsc() {
    _orderBy
      ..clear()
      ..add('"message" ASC');
    return this;
  }

  /// Sort by message in descending order.
  ManualLogQueryBuilder sortByMessageDesc() {
    _orderBy
      ..clear()
      ..add('"message" DESC');
    return this;
  }

  /// Then sort by message in ascending order.
  ManualLogQueryBuilder thenByMessageAsc() {
    _orderBy.add('"message" ASC');
    return this;
  }

  /// Then sort by message in descending order.
  ManualLogQueryBuilder thenByMessageDesc() {
    _orderBy.add('"message" DESC');
    return this;
  }

  /// Limit the number of results.
  ManualLogQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  ManualLogQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<ManualLog>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_ManualLogFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<ManualLog?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _ManualLogFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "manual_logs"$whereClause';
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
      'manual_logs',
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
    return 'SELECT * FROM "manual_logs"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [ManualLog].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class ManualLogRepository {
  final NativeSqliteDatabase database;

  const ManualLogRepository(this.database);

  /// Inserts a new ManualLog into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(ManualLog entity) async {
    final rowId = await database.insert('manual_logs', {
      'message': entity.message,
    });
    return rowId;
  }

  /// Finds a ManualLog by its ID.
  /// Returns null if not found.
  Future<ManualLog?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "manual_logs" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _ManualLogFromMap(rows.first);
  }

  /// Finds all ManualLogs in the database.
  Future<List<ManualLog>> findAll() async {
    final result = await database.query('SELECT * FROM "manual_logs"');

    return result.toMapList().map(_ManualLogFromMap).toList();
  }

  /// Updates an existing ManualLog in the database.
  /// Returns the number of rows affected.
  Future<int> update(ManualLog entity) async {
    return database.update(
      'manual_logs',
      {'message': entity.message},
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a ManualLog by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('manual_logs', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('manual_logs');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "manual_logs"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  ManualLogQueryBuilder queryBuilder() {
    return ManualLogQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as ManualLog objects.
  Future<List<ManualLog>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_ManualLogFromMap).toList();
  }
}
