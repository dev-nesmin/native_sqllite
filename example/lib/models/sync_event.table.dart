// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'sync_event.dart';

/// Generated table schema for [SyncEvent].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class SyncEventSchema {
  static const String tableName = 'sync_events';

  static const String createTableSql =
      'CREATE TABLE "sync_events" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "source" TEXT NOT NULL, "message" TEXT NOT NULL, "created_at" INTEGER NOT NULL)';

  static const List<String> indexSql = [
    'CREATE INDEX "idx_sync_events_created_at" ON "sync_events" ("created_at")',
  ];

  // Column names
  static const String ID = 'id';
  static const String SOURCE = 'source';
  static const String MESSAGE = 'message';
  static const String CREATED_AT = 'created_at';
}

SyncEvent _SyncEventFromMap(Map<String, Object?> map) {
  return SyncEvent(
    id: map['id'] as int?,
    source: map['source'] as String,
    message: map['message'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// Generated query builder for [SyncEvent].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class SyncEventQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  SyncEventQueryBuilder(this._database);

  /// Filter where id equals [value].
  SyncEventQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  SyncEventQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  SyncEventQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  SyncEventQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  SyncEventQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  SyncEventQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where source equals [value].
  SyncEventQueryBuilder sourceEqualTo(String value) {
    _whereConditions.add('"source" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where source contains [value].
  SyncEventQueryBuilder sourceContains(String value) {
    _whereConditions.add('"source" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where source starts with [value].
  SyncEventQueryBuilder sourceStartsWith(String value) {
    _whereConditions.add('"source" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where source ends with [value].
  SyncEventQueryBuilder sourceEndsWith(String value) {
    _whereConditions.add('"source" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where message equals [value].
  SyncEventQueryBuilder messageEqualTo(String value) {
    _whereConditions.add('"message" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where message contains [value].
  SyncEventQueryBuilder messageContains(String value) {
    _whereConditions.add('"message" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where message starts with [value].
  SyncEventQueryBuilder messageStartsWith(String value) {
    _whereConditions.add('"message" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where message ends with [value].
  SyncEventQueryBuilder messageEndsWith(String value) {
    _whereConditions.add('"message" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where createdAt equals [value].
  SyncEventQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('"created_at" = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  SyncEventQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('"created_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  SyncEventQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('"created_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  SyncEventQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"created_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Sort by id in ascending order.
  SyncEventQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  SyncEventQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  SyncEventQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  SyncEventQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by source in ascending order.
  SyncEventQueryBuilder sortBySourceAsc() {
    _orderBy
      ..clear()
      ..add('"source" ASC');
    return this;
  }

  /// Sort by source in descending order.
  SyncEventQueryBuilder sortBySourceDesc() {
    _orderBy
      ..clear()
      ..add('"source" DESC');
    return this;
  }

  /// Then sort by source in ascending order.
  SyncEventQueryBuilder thenBySourceAsc() {
    _orderBy.add('"source" ASC');
    return this;
  }

  /// Then sort by source in descending order.
  SyncEventQueryBuilder thenBySourceDesc() {
    _orderBy.add('"source" DESC');
    return this;
  }

  /// Sort by message in ascending order.
  SyncEventQueryBuilder sortByMessageAsc() {
    _orderBy
      ..clear()
      ..add('"message" ASC');
    return this;
  }

  /// Sort by message in descending order.
  SyncEventQueryBuilder sortByMessageDesc() {
    _orderBy
      ..clear()
      ..add('"message" DESC');
    return this;
  }

  /// Then sort by message in ascending order.
  SyncEventQueryBuilder thenByMessageAsc() {
    _orderBy.add('"message" ASC');
    return this;
  }

  /// Then sort by message in descending order.
  SyncEventQueryBuilder thenByMessageDesc() {
    _orderBy.add('"message" DESC');
    return this;
  }

  /// Sort by createdAt in ascending order.
  SyncEventQueryBuilder sortByCreatedAtAsc() {
    _orderBy
      ..clear()
      ..add('"created_at" ASC');
    return this;
  }

  /// Sort by createdAt in descending order.
  SyncEventQueryBuilder sortByCreatedAtDesc() {
    _orderBy
      ..clear()
      ..add('"created_at" DESC');
    return this;
  }

  /// Then sort by createdAt in ascending order.
  SyncEventQueryBuilder thenByCreatedAtAsc() {
    _orderBy.add('"created_at" ASC');
    return this;
  }

  /// Then sort by createdAt in descending order.
  SyncEventQueryBuilder thenByCreatedAtDesc() {
    _orderBy.add('"created_at" DESC');
    return this;
  }

  /// Limit the number of results.
  SyncEventQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  SyncEventQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<SyncEvent>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_SyncEventFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<SyncEvent?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _SyncEventFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "sync_events"$whereClause';
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
      'sync_events',
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
    return 'SELECT * FROM "sync_events"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [SyncEvent].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class SyncEventRepository {
  final NativeSqliteDatabase database;

  const SyncEventRepository(this.database);

  /// Inserts a new SyncEvent into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(SyncEvent entity) async {
    final rowId = await database.insert('sync_events', {
      'source': entity.source,
      'message': entity.message,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
    });
    return rowId;
  }

  /// Finds a SyncEvent by its ID.
  /// Returns null if not found.
  Future<SyncEvent?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "sync_events" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _SyncEventFromMap(rows.first);
  }

  /// Finds all SyncEvents in the database.
  Future<List<SyncEvent>> findAll() async {
    final result = await database.query('SELECT * FROM "sync_events"');

    return result.toMapList().map(_SyncEventFromMap).toList();
  }

  /// Updates an existing SyncEvent in the database.
  /// Returns the number of rows affected.
  Future<int> update(SyncEvent entity) async {
    return database.update(
      'sync_events',
      {
        'source': entity.source,
        'message': entity.message,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
      },
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a SyncEvent by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('sync_events', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('sync_events');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "sync_events"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  SyncEventQueryBuilder queryBuilder() {
    return SyncEventQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as SyncEvent objects.
  Future<List<SyncEvent>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_SyncEventFromMap).toList();
  }
}
