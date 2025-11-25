// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'category.dart';

// Table schema for Category
abstract class CategorySchema {
  static const String tableName = 'categories';

  static const String createTableSql = '''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      description TEXT,
      created_at INTEGER NOT NULL
    )
  ''';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String DESCRIPTION = 'description';
  static const String CREATED_AT = 'created_at';
}

// Query builder for Category
class CategoryQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  CategoryQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  CategoryQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  CategoryQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  CategoryQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  CategoryQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where description equals [value].
  CategoryQueryBuilder descriptionEqualTo(String? value) {
    _whereConditions.add('description = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where description contains [value].
  CategoryQueryBuilder descriptionContains(String value) {
    _whereConditions.add('description LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where description starts with [value].
  CategoryQueryBuilder descriptionStartsWith(String value) {
    _whereConditions.add('description LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where description ends with [value].
  CategoryQueryBuilder descriptionEndsWith(String value) {
    _whereConditions.add('description LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where description is null.
  CategoryQueryBuilder descriptionIsNull() {
    _whereConditions.add('description IS NULL');
    return this;
  }

  /// Filter where description is not null.
  CategoryQueryBuilder descriptionIsNotNull() {
    _whereConditions.add('description IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  CategoryQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  CategoryQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  CategoryQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  CategoryQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Sort by id in ascending order.
  CategoryQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  CategoryQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  CategoryQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  CategoryQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by description in ascending order.
  CategoryQueryBuilder sortByDescriptionAsc() {
    _orderBy = 'description ASC';
    return this;
  }

  /// Sort by description in descending order.
  CategoryQueryBuilder sortByDescriptionDesc() {
    _orderBy = 'description DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  CategoryQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  CategoryQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Limit the number of results.
  CategoryQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  CategoryQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Category>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Category?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM categories$whereClause';
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
      'categories',
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
    return 'SELECT * FROM categories$whereClause$orderClause$limitClause$offsetClause';
  }

  Category _fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

// Repository for Category
class CategoryRepository {
  final String databaseName;

  const CategoryRepository([this.databaseName = 'example_app']);

  /// Inserts a new Category into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(Category entity) async {
    return NativeSqlite.insert(databaseName, 'categories', {
      'name': entity.name,
      'description': entity.description,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
    });
  }

  /// Finds a Category by its ID.
  /// Returns null if not found.
  Future<Category?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM categories WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all Categorys in the database.
  Future<List<Category>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM categories',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing Category in the database.
  /// Returns the number of rows affected.
  Future<int> update(Category entity) async {
    return NativeSqlite.update(
      databaseName,
      'categories',
      {
        'name': entity.name,
        'description': entity.description,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Category by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'categories');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM categories',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  CategoryQueryBuilder queryBuilder() {
    return CategoryQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as Category objects.
  Future<List<Category>> query(String sql, [List<Object?>? arguments]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a Category object.
  Category _fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
