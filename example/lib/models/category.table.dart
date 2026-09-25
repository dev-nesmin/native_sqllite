// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'category.dart';

/// Generated table schema for [Category].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class CategorySchema {
  static const String tableName = 'categories';

  static const String createTableSql =
      'CREATE TABLE "categories" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL UNIQUE, "description" TEXT, "created_at" INTEGER NOT NULL)';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String DESCRIPTION = 'description';
  static const String CREATED_AT = 'created_at';
}

Category _CategoryFromMap(Map<String, Object?> map) {
  return Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    description: map['description'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// Generated query builder for [Category].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class CategoryQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  CategoryQueryBuilder(this._database);

  /// Filter where id equals [value].
  CategoryQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  CategoryQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  CategoryQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  CategoryQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  CategoryQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  CategoryQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where name equals [value].
  CategoryQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('"name" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  CategoryQueryBuilder nameContains(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name starts with [value].
  CategoryQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name ends with [value].
  CategoryQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where description equals [value].
  CategoryQueryBuilder descriptionEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"description" IS NULL');
    } else {
      _whereConditions.add('"description" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where description contains [value].
  CategoryQueryBuilder descriptionContains(String value) {
    _whereConditions.add('"description" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where description starts with [value].
  CategoryQueryBuilder descriptionStartsWith(String value) {
    _whereConditions.add('"description" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where description ends with [value].
  CategoryQueryBuilder descriptionEndsWith(String value) {
    _whereConditions.add('"description" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where description is null.
  CategoryQueryBuilder descriptionIsNull() {
    _whereConditions.add('"description" IS NULL');
    return this;
  }

  /// Filter where description is not null.
  CategoryQueryBuilder descriptionIsNotNull() {
    _whereConditions.add('"description" IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  CategoryQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('"created_at" = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  CategoryQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('"created_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  CategoryQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('"created_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  CategoryQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"created_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Sort by id in ascending order.
  CategoryQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  CategoryQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  CategoryQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  CategoryQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by name in ascending order.
  CategoryQueryBuilder sortByNameAsc() {
    _orderBy
      ..clear()
      ..add('"name" ASC');
    return this;
  }

  /// Sort by name in descending order.
  CategoryQueryBuilder sortByNameDesc() {
    _orderBy
      ..clear()
      ..add('"name" DESC');
    return this;
  }

  /// Then sort by name in ascending order.
  CategoryQueryBuilder thenByNameAsc() {
    _orderBy.add('"name" ASC');
    return this;
  }

  /// Then sort by name in descending order.
  CategoryQueryBuilder thenByNameDesc() {
    _orderBy.add('"name" DESC');
    return this;
  }

  /// Sort by description in ascending order.
  CategoryQueryBuilder sortByDescriptionAsc() {
    _orderBy
      ..clear()
      ..add('"description" ASC');
    return this;
  }

  /// Sort by description in descending order.
  CategoryQueryBuilder sortByDescriptionDesc() {
    _orderBy
      ..clear()
      ..add('"description" DESC');
    return this;
  }

  /// Then sort by description in ascending order.
  CategoryQueryBuilder thenByDescriptionAsc() {
    _orderBy.add('"description" ASC');
    return this;
  }

  /// Then sort by description in descending order.
  CategoryQueryBuilder thenByDescriptionDesc() {
    _orderBy.add('"description" DESC');
    return this;
  }

  /// Sort by createdAt in ascending order.
  CategoryQueryBuilder sortByCreatedAtAsc() {
    _orderBy
      ..clear()
      ..add('"created_at" ASC');
    return this;
  }

  /// Sort by createdAt in descending order.
  CategoryQueryBuilder sortByCreatedAtDesc() {
    _orderBy
      ..clear()
      ..add('"created_at" DESC');
    return this;
  }

  /// Then sort by createdAt in ascending order.
  CategoryQueryBuilder thenByCreatedAtAsc() {
    _orderBy.add('"created_at" ASC');
    return this;
  }

  /// Then sort by createdAt in descending order.
  CategoryQueryBuilder thenByCreatedAtDesc() {
    _orderBy.add('"created_at" DESC');
    return this;
  }

  /// Limit the number of results.
  CategoryQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  CategoryQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Category>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_CategoryFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Category?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _CategoryFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "categories"$whereClause';
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
      'categories',
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
    return 'SELECT * FROM "categories"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Category].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class CategoryRepository {
  final NativeSqliteDatabase database;

  const CategoryRepository(this.database);

  /// Inserts a new Category into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(Category entity) async {
    final rowId = await database.insert('categories', {
      'name': entity.name,
      'description': entity.description,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
    });
    return rowId;
  }

  /// Finds a Category by its ID.
  /// Returns null if not found.
  Future<Category?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "categories" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _CategoryFromMap(rows.first);
  }

  /// Finds all Categorys in the database.
  Future<List<Category>> findAll() async {
    final result = await database.query('SELECT * FROM "categories"');

    return result.toMapList().map(_CategoryFromMap).toList();
  }

  /// Updates an existing Category in the database.
  /// Returns the number of rows affected.
  Future<int> update(Category entity) async {
    return database.update(
      'categories',
      {
        'name': entity.name,
        'description': entity.description,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
      },
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Category by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('categories', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('categories');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "categories"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  CategoryQueryBuilder queryBuilder() {
    return CategoryQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Category objects.
  Future<List<Category>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_CategoryFromMap).toList();
  }
}
