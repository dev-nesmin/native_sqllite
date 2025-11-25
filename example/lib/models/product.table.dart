// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'product.dart';

// Table schema for Product
abstract class ProductSchema {
  static const String tableName = 'products';

  static const String createTableSql = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      is_available INTEGER NOT NULL DEFAULT 1,
      category_id INTEGER NOT NULL,
      image_url TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE
    )
  ''';

  static const List<String> indexSql = [
    '''CREATE INDEX idx_products_category_id_price ON products (category_id, price)''',
    '''CREATE INDEX idx_products_name ON products (name)''',
  ];

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String DESCRIPTION = 'description';
  static const String PRICE = 'price';
  static const String STOCK = 'stock';
  static const String IS_AVAILABLE = 'is_available';
  static const String CATEGORY_ID = 'category_id';
  static const String IMAGE_URL = 'image_url';
  static const String CREATED_AT = 'created_at';
  static const String UPDATED_AT = 'updated_at';
}

// Query builder for Product
class ProductQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  ProductQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  ProductQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  ProductQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  ProductQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  ProductQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where description equals [value].
  ProductQueryBuilder descriptionEqualTo(String? value) {
    _whereConditions.add('description = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where description contains [value].
  ProductQueryBuilder descriptionContains(String value) {
    _whereConditions.add('description LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where description starts with [value].
  ProductQueryBuilder descriptionStartsWith(String value) {
    _whereConditions.add('description LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where description ends with [value].
  ProductQueryBuilder descriptionEndsWith(String value) {
    _whereConditions.add('description LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where description is null.
  ProductQueryBuilder descriptionIsNull() {
    _whereConditions.add('description IS NULL');
    return this;
  }

  /// Filter where description is not null.
  ProductQueryBuilder descriptionIsNotNull() {
    _whereConditions.add('description IS NOT NULL');
    return this;
  }

  /// Filter where price equals [value].
  ProductQueryBuilder priceEqualTo(double value) {
    _whereConditions.add('price = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where price is greater than [value].
  ProductQueryBuilder priceGreaterThan(double value) {
    _whereConditions.add('price > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where price is less than [value].
  ProductQueryBuilder priceLessThan(double value) {
    _whereConditions.add('price < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where price is between [min] and [max].
  ProductQueryBuilder priceBetween(double min, double max) {
    _whereConditions.add('price BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where stock equals [value].
  ProductQueryBuilder stockEqualTo(int value) {
    _whereConditions.add('stock = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where stock is greater than [value].
  ProductQueryBuilder stockGreaterThan(int value) {
    _whereConditions.add('stock > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where stock is less than [value].
  ProductQueryBuilder stockLessThan(int value) {
    _whereConditions.add('stock < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where stock is between [min] and [max].
  ProductQueryBuilder stockBetween(int min, int max) {
    _whereConditions.add('stock BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where isAvailable is true.
  ProductQueryBuilder isAvailableIsTrue() {
    _whereConditions.add('is_available = ?');
    _whereArgs.add(1);
    return this;
  }

  /// Filter where isAvailable is false.
  ProductQueryBuilder isAvailableIsFalse() {
    _whereConditions.add('is_available = ?');
    _whereArgs.add(0);
    return this;
  }

  /// Filter where categoryId equals [value].
  ProductQueryBuilder categoryIdEqualTo(int value) {
    _whereConditions.add('category_id = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where categoryId is greater than [value].
  ProductQueryBuilder categoryIdGreaterThan(int value) {
    _whereConditions.add('category_id > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where categoryId is less than [value].
  ProductQueryBuilder categoryIdLessThan(int value) {
    _whereConditions.add('category_id < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where categoryId is between [min] and [max].
  ProductQueryBuilder categoryIdBetween(int min, int max) {
    _whereConditions.add('category_id BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where imageUrl equals [value].
  ProductQueryBuilder imageUrlEqualTo(String? value) {
    _whereConditions.add('image_url = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where imageUrl contains [value].
  ProductQueryBuilder imageUrlContains(String value) {
    _whereConditions.add('image_url LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where imageUrl starts with [value].
  ProductQueryBuilder imageUrlStartsWith(String value) {
    _whereConditions.add('image_url LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where imageUrl ends with [value].
  ProductQueryBuilder imageUrlEndsWith(String value) {
    _whereConditions.add('image_url LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where imageUrl is null.
  ProductQueryBuilder imageUrlIsNull() {
    _whereConditions.add('image_url IS NULL');
    return this;
  }

  /// Filter where imageUrl is not null.
  ProductQueryBuilder imageUrlIsNotNull() {
    _whereConditions.add('image_url IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  ProductQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  ProductQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  ProductQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  ProductQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt equals [value].
  ProductQueryBuilder updatedAtEqualTo(DateTime? value) {
    _whereConditions.add('updated_at = ?');
    _whereArgs.add(value?.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is after [value].
  ProductQueryBuilder updatedAtAfter(DateTime value) {
    _whereConditions.add('updated_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is before [value].
  ProductQueryBuilder updatedAtBefore(DateTime value) {
    _whereConditions.add('updated_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is between [start] and [end].
  ProductQueryBuilder updatedAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('updated_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is null.
  ProductQueryBuilder updatedAtIsNull() {
    _whereConditions.add('updated_at IS NULL');
    return this;
  }

  /// Filter where updatedAt is not null.
  ProductQueryBuilder updatedAtIsNotNull() {
    _whereConditions.add('updated_at IS NOT NULL');
    return this;
  }

  /// Sort by id in ascending order.
  ProductQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  ProductQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  ProductQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  ProductQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by description in ascending order.
  ProductQueryBuilder sortByDescriptionAsc() {
    _orderBy = 'description ASC';
    return this;
  }

  /// Sort by description in descending order.
  ProductQueryBuilder sortByDescriptionDesc() {
    _orderBy = 'description DESC';
    return this;
  }

  /// Sort by price in ascending order.
  ProductQueryBuilder sortByPriceAsc() {
    _orderBy = 'price ASC';
    return this;
  }

  /// Sort by price in descending order.
  ProductQueryBuilder sortByPriceDesc() {
    _orderBy = 'price DESC';
    return this;
  }

  /// Sort by stock in ascending order.
  ProductQueryBuilder sortByStockAsc() {
    _orderBy = 'stock ASC';
    return this;
  }

  /// Sort by stock in descending order.
  ProductQueryBuilder sortByStockDesc() {
    _orderBy = 'stock DESC';
    return this;
  }

  /// Sort by isAvailable in ascending order.
  ProductQueryBuilder sortByIsAvailableAsc() {
    _orderBy = 'is_available ASC';
    return this;
  }

  /// Sort by isAvailable in descending order.
  ProductQueryBuilder sortByIsAvailableDesc() {
    _orderBy = 'is_available DESC';
    return this;
  }

  /// Sort by categoryId in ascending order.
  ProductQueryBuilder sortByCategoryIdAsc() {
    _orderBy = 'category_id ASC';
    return this;
  }

  /// Sort by categoryId in descending order.
  ProductQueryBuilder sortByCategoryIdDesc() {
    _orderBy = 'category_id DESC';
    return this;
  }

  /// Sort by imageUrl in ascending order.
  ProductQueryBuilder sortByImageUrlAsc() {
    _orderBy = 'image_url ASC';
    return this;
  }

  /// Sort by imageUrl in descending order.
  ProductQueryBuilder sortByImageUrlDesc() {
    _orderBy = 'image_url DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  ProductQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  ProductQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Sort by updatedAt in ascending order.
  ProductQueryBuilder sortByUpdatedAtAsc() {
    _orderBy = 'updated_at ASC';
    return this;
  }

  /// Sort by updatedAt in descending order.
  ProductQueryBuilder sortByUpdatedAtDesc() {
    _orderBy = 'updated_at DESC';
    return this;
  }

  /// Limit the number of results.
  ProductQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  ProductQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Product>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Product?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM products$whereClause';
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
      'products',
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
    return 'SELECT * FROM products$whereClause$orderClause$limitClause$offsetClause';
  }

  Product _fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: map['price'] as double,
      stock: map['stock'] as int,
      isAvailable: (map['is_available'] as int) == 1,
      categoryId: map['category_id'] as int,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }
}

// Repository for Product
class ProductRepository {
  final String databaseName;

  const ProductRepository([this.databaseName = 'example_app']);

  /// Inserts a new Product into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(Product entity) async {
    return NativeSqlite.insert(databaseName, 'products', {
      'name': entity.name,
      'description': entity.description,
      'price': entity.price,
      'stock': entity.stock,
      'is_available': entity.isAvailable ? 1 : 0,
      'category_id': entity.categoryId,
      'image_url': entity.imageUrl,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
    });
  }

  /// Finds a Product by its ID.
  /// Returns null if not found.
  Future<Product?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM products WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all Products in the database.
  Future<List<Product>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM products',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing Product in the database.
  /// Returns the number of rows affected.
  Future<int> update(Product entity) async {
    return NativeSqlite.update(
      databaseName,
      'products',
      {
        'name': entity.name,
        'description': entity.description,
        'price': entity.price,
        'stock': entity.stock,
        'is_available': entity.isAvailable ? 1 : 0,
        'category_id': entity.categoryId,
        'image_url': entity.imageUrl,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Product by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'products');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM products',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  ProductQueryBuilder queryBuilder() {
    return ProductQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as Product objects.
  Future<List<Product>> query(String sql, [List<Object?>? arguments]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a Product object.
  Product _fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: map['price'] as double,
      stock: map['stock'] as int,
      isAvailable: (map['is_available'] as int) == 1,
      categoryId: map['category_id'] as int,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }
}
