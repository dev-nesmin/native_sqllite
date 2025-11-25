// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'order.dart';

// Table schema for Order
abstract class OrderSchema {
  static const String tableName = 'orders';

  static const String createTableSql = '''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      total_price REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      delivered_at INTEGER,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE
    )
  ''';

  static const List<String> indexSql = [
    '''CREATE INDEX idx_orders_user_id_created_at ON orders (user_id, created_at)''',
    '''CREATE INDEX idx_orders_status ON orders (status)''',
  ];

  // Column names
  static const String ID = 'id';
  static const String USER_ID = 'user_id';
  static const String PRODUCT_ID = 'product_id';
  static const String QUANTITY = 'quantity';
  static const String TOTAL_PRICE = 'total_price';
  static const String STATUS = 'status';
  static const String NOTES = 'notes';
  static const String CREATED_AT = 'created_at';
  static const String UPDATED_AT = 'updated_at';
  static const String DELIVERED_AT = 'delivered_at';
}

// Query builder for Order
class OrderQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  OrderQueryBuilder(this._databaseName);

  /// Filter where userId equals [value].
  OrderQueryBuilder userIdEqualTo(int value) {
    _whereConditions.add('user_id = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where userId is greater than [value].
  OrderQueryBuilder userIdGreaterThan(int value) {
    _whereConditions.add('user_id > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where userId is less than [value].
  OrderQueryBuilder userIdLessThan(int value) {
    _whereConditions.add('user_id < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where userId is between [min] and [max].
  OrderQueryBuilder userIdBetween(int min, int max) {
    _whereConditions.add('user_id BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where productId equals [value].
  OrderQueryBuilder productIdEqualTo(int value) {
    _whereConditions.add('product_id = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where productId is greater than [value].
  OrderQueryBuilder productIdGreaterThan(int value) {
    _whereConditions.add('product_id > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where productId is less than [value].
  OrderQueryBuilder productIdLessThan(int value) {
    _whereConditions.add('product_id < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where productId is between [min] and [max].
  OrderQueryBuilder productIdBetween(int min, int max) {
    _whereConditions.add('product_id BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where quantity equals [value].
  OrderQueryBuilder quantityEqualTo(int value) {
    _whereConditions.add('quantity = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where quantity is greater than [value].
  OrderQueryBuilder quantityGreaterThan(int value) {
    _whereConditions.add('quantity > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where quantity is less than [value].
  OrderQueryBuilder quantityLessThan(int value) {
    _whereConditions.add('quantity < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where quantity is between [min] and [max].
  OrderQueryBuilder quantityBetween(int min, int max) {
    _whereConditions.add('quantity BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where totalPrice equals [value].
  OrderQueryBuilder totalPriceEqualTo(double value) {
    _whereConditions.add('total_price = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where totalPrice is greater than [value].
  OrderQueryBuilder totalPriceGreaterThan(double value) {
    _whereConditions.add('total_price > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where totalPrice is less than [value].
  OrderQueryBuilder totalPriceLessThan(double value) {
    _whereConditions.add('total_price < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where totalPrice is between [min] and [max].
  OrderQueryBuilder totalPriceBetween(double min, double max) {
    _whereConditions.add('total_price BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where status equals [value].
  OrderQueryBuilder statusEqualTo(String value) {
    _whereConditions.add('status = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where status contains [value].
  OrderQueryBuilder statusContains(String value) {
    _whereConditions.add('status LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where status starts with [value].
  OrderQueryBuilder statusStartsWith(String value) {
    _whereConditions.add('status LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where status ends with [value].
  OrderQueryBuilder statusEndsWith(String value) {
    _whereConditions.add('status LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where notes equals [value].
  OrderQueryBuilder notesEqualTo(String? value) {
    _whereConditions.add('notes = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where notes contains [value].
  OrderQueryBuilder notesContains(String value) {
    _whereConditions.add('notes LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where notes starts with [value].
  OrderQueryBuilder notesStartsWith(String value) {
    _whereConditions.add('notes LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where notes ends with [value].
  OrderQueryBuilder notesEndsWith(String value) {
    _whereConditions.add('notes LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where notes is null.
  OrderQueryBuilder notesIsNull() {
    _whereConditions.add('notes IS NULL');
    return this;
  }

  /// Filter where notes is not null.
  OrderQueryBuilder notesIsNotNull() {
    _whereConditions.add('notes IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  OrderQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  OrderQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  OrderQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  OrderQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt equals [value].
  OrderQueryBuilder updatedAtEqualTo(DateTime? value) {
    _whereConditions.add('updated_at = ?');
    _whereArgs.add(value?.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is after [value].
  OrderQueryBuilder updatedAtAfter(DateTime value) {
    _whereConditions.add('updated_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is before [value].
  OrderQueryBuilder updatedAtBefore(DateTime value) {
    _whereConditions.add('updated_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is between [start] and [end].
  OrderQueryBuilder updatedAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('updated_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is null.
  OrderQueryBuilder updatedAtIsNull() {
    _whereConditions.add('updated_at IS NULL');
    return this;
  }

  /// Filter where updatedAt is not null.
  OrderQueryBuilder updatedAtIsNotNull() {
    _whereConditions.add('updated_at IS NOT NULL');
    return this;
  }

  /// Filter where deliveredAt equals [value].
  OrderQueryBuilder deliveredAtEqualTo(DateTime? value) {
    _whereConditions.add('delivered_at = ?');
    _whereArgs.add(value?.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is after [value].
  OrderQueryBuilder deliveredAtAfter(DateTime value) {
    _whereConditions.add('delivered_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is before [value].
  OrderQueryBuilder deliveredAtBefore(DateTime value) {
    _whereConditions.add('delivered_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is between [start] and [end].
  OrderQueryBuilder deliveredAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('delivered_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is null.
  OrderQueryBuilder deliveredAtIsNull() {
    _whereConditions.add('delivered_at IS NULL');
    return this;
  }

  /// Filter where deliveredAt is not null.
  OrderQueryBuilder deliveredAtIsNotNull() {
    _whereConditions.add('delivered_at IS NOT NULL');
    return this;
  }

  /// Sort by id in ascending order.
  OrderQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  OrderQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by userId in ascending order.
  OrderQueryBuilder sortByUserIdAsc() {
    _orderBy = 'user_id ASC';
    return this;
  }

  /// Sort by userId in descending order.
  OrderQueryBuilder sortByUserIdDesc() {
    _orderBy = 'user_id DESC';
    return this;
  }

  /// Sort by productId in ascending order.
  OrderQueryBuilder sortByProductIdAsc() {
    _orderBy = 'product_id ASC';
    return this;
  }

  /// Sort by productId in descending order.
  OrderQueryBuilder sortByProductIdDesc() {
    _orderBy = 'product_id DESC';
    return this;
  }

  /// Sort by quantity in ascending order.
  OrderQueryBuilder sortByQuantityAsc() {
    _orderBy = 'quantity ASC';
    return this;
  }

  /// Sort by quantity in descending order.
  OrderQueryBuilder sortByQuantityDesc() {
    _orderBy = 'quantity DESC';
    return this;
  }

  /// Sort by totalPrice in ascending order.
  OrderQueryBuilder sortByTotalPriceAsc() {
    _orderBy = 'total_price ASC';
    return this;
  }

  /// Sort by totalPrice in descending order.
  OrderQueryBuilder sortByTotalPriceDesc() {
    _orderBy = 'total_price DESC';
    return this;
  }

  /// Sort by status in ascending order.
  OrderQueryBuilder sortByStatusAsc() {
    _orderBy = 'status ASC';
    return this;
  }

  /// Sort by status in descending order.
  OrderQueryBuilder sortByStatusDesc() {
    _orderBy = 'status DESC';
    return this;
  }

  /// Sort by notes in ascending order.
  OrderQueryBuilder sortByNotesAsc() {
    _orderBy = 'notes ASC';
    return this;
  }

  /// Sort by notes in descending order.
  OrderQueryBuilder sortByNotesDesc() {
    _orderBy = 'notes DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  OrderQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  OrderQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Sort by updatedAt in ascending order.
  OrderQueryBuilder sortByUpdatedAtAsc() {
    _orderBy = 'updated_at ASC';
    return this;
  }

  /// Sort by updatedAt in descending order.
  OrderQueryBuilder sortByUpdatedAtDesc() {
    _orderBy = 'updated_at DESC';
    return this;
  }

  /// Sort by deliveredAt in ascending order.
  OrderQueryBuilder sortByDeliveredAtAsc() {
    _orderBy = 'delivered_at ASC';
    return this;
  }

  /// Sort by deliveredAt in descending order.
  OrderQueryBuilder sortByDeliveredAtDesc() {
    _orderBy = 'delivered_at DESC';
    return this;
  }

  /// Limit the number of results.
  OrderQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  OrderQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Order>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Order?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM orders$whereClause';
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
      'orders',
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
    return 'SELECT * FROM orders$whereClause$orderClause$limitClause$offsetClause';
  }

  Order _fromMap(Map<String, Object?> map) {
    return Order(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      totalPrice: map['total_price'] as double,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['delivered_at'] as int)
          : null,
    );
  }
}

// Repository for Order
class OrderRepository {
  final String databaseName;

  const OrderRepository([this.databaseName = 'example_app']);

  /// Inserts a new Order into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(Order entity) async {
    return NativeSqlite.insert(databaseName, 'orders', {
      'user_id': entity.userId,
      'product_id': entity.productId,
      'quantity': entity.quantity,
      'total_price': entity.totalPrice,
      'status': entity.status,
      'notes': entity.notes,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
      'delivered_at': entity.deliveredAt?.millisecondsSinceEpoch,
    });
  }

  /// Finds a Order by its ID.
  /// Returns null if not found.
  Future<Order?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM orders WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all Orders in the database.
  Future<List<Order>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM orders',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing Order in the database.
  /// Returns the number of rows affected.
  Future<int> update(Order entity) async {
    return NativeSqlite.update(
      databaseName,
      'orders',
      {
        'user_id': entity.userId,
        'product_id': entity.productId,
        'quantity': entity.quantity,
        'total_price': entity.totalPrice,
        'status': entity.status,
        'notes': entity.notes,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
        'delivered_at': entity.deliveredAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Order by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'orders');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM orders',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  OrderQueryBuilder queryBuilder() {
    return OrderQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as Order objects.
  Future<List<Order>> query(String sql, [List<Object?>? arguments]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a Order object.
  Order _fromMap(Map<String, Object?> map) {
    return Order(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      totalPrice: map['total_price'] as double,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['delivered_at'] as int)
          : null,
    );
  }
}
