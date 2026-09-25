// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'order.dart';

/// Generated table schema for [Order].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class OrderSchema {
  static const String tableName = 'orders';

  static const String createTableSql =
      'CREATE TABLE "orders" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "user_id" INTEGER NOT NULL, "product_id" INTEGER NOT NULL, "quantity" INTEGER NOT NULL, "total_price" REAL NOT NULL, "status" TEXT NOT NULL DEFAULT \'pending\', "notes" TEXT, "created_at" INTEGER NOT NULL, "updated_at" INTEGER, "delivered_at" INTEGER, FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE)';

  static const List<String> indexSql = [
    'CREATE INDEX "idx_orders_user_id_created_at" ON "orders" ("user_id", "created_at")',
    'CREATE INDEX "idx_orders_status" ON "orders" ("status")',
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

Order _OrderFromMap(Map<String, Object?> map) {
  return Order(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    productId: map['product_id'] as int,
    quantity: map['quantity'] as int,
    totalPrice: map['total_price'] as double,
    status: OrderStatus.values.firstWhere((e) => e.name == map['status']),
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

/// Generated query builder for [Order].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class OrderQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  OrderQueryBuilder(this._database);

  /// Filter where id equals [value].
  OrderQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  OrderQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  OrderQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  OrderQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  OrderQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  OrderQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where userId equals [value].
  OrderQueryBuilder userIdEqualTo(int value) {
    _whereConditions.add('"user_id" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where userId is greater than [value].
  OrderQueryBuilder userIdGreaterThan(int value) {
    _whereConditions.add('"user_id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where userId is less than [value].
  OrderQueryBuilder userIdLessThan(int value) {
    _whereConditions.add('"user_id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where userId is between [min] and [max].
  OrderQueryBuilder userIdBetween(int min, int max) {
    _whereConditions.add('"user_id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where productId equals [value].
  OrderQueryBuilder productIdEqualTo(int value) {
    _whereConditions.add('"product_id" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where productId is greater than [value].
  OrderQueryBuilder productIdGreaterThan(int value) {
    _whereConditions.add('"product_id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where productId is less than [value].
  OrderQueryBuilder productIdLessThan(int value) {
    _whereConditions.add('"product_id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where productId is between [min] and [max].
  OrderQueryBuilder productIdBetween(int min, int max) {
    _whereConditions.add('"product_id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where quantity equals [value].
  OrderQueryBuilder quantityEqualTo(int value) {
    _whereConditions.add('"quantity" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where quantity is greater than [value].
  OrderQueryBuilder quantityGreaterThan(int value) {
    _whereConditions.add('"quantity" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where quantity is less than [value].
  OrderQueryBuilder quantityLessThan(int value) {
    _whereConditions.add('"quantity" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where quantity is between [min] and [max].
  OrderQueryBuilder quantityBetween(int min, int max) {
    _whereConditions.add('"quantity" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where totalPrice equals [value].
  OrderQueryBuilder totalPriceEqualTo(double value) {
    _whereConditions.add('"total_price" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where totalPrice is greater than [value].
  OrderQueryBuilder totalPriceGreaterThan(double value) {
    _whereConditions.add('"total_price" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where totalPrice is less than [value].
  OrderQueryBuilder totalPriceLessThan(double value) {
    _whereConditions.add('"total_price" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where totalPrice is between [min] and [max].
  OrderQueryBuilder totalPriceBetween(double min, double max) {
    _whereConditions.add('"total_price" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where status equals [value].
  OrderQueryBuilder statusEqualTo(OrderStatus value) {
    _whereConditions.add('"status" = ?');
    _whereArgs.add(value.name);
    return this;
  }

  /// Filter where notes equals [value].
  OrderQueryBuilder notesEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"notes" IS NULL');
    } else {
      _whereConditions.add('"notes" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where notes contains [value].
  OrderQueryBuilder notesContains(String value) {
    _whereConditions.add('"notes" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where notes starts with [value].
  OrderQueryBuilder notesStartsWith(String value) {
    _whereConditions.add('"notes" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where notes ends with [value].
  OrderQueryBuilder notesEndsWith(String value) {
    _whereConditions.add('"notes" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where notes is null.
  OrderQueryBuilder notesIsNull() {
    _whereConditions.add('"notes" IS NULL');
    return this;
  }

  /// Filter where notes is not null.
  OrderQueryBuilder notesIsNotNull() {
    _whereConditions.add('"notes" IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  OrderQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('"created_at" = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  OrderQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('"created_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  OrderQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('"created_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  OrderQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"created_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt equals [value].
  OrderQueryBuilder updatedAtEqualTo(DateTime? value) {
    if (value == null) {
      _whereConditions.add('"updated_at" IS NULL');
    } else {
      _whereConditions.add('"updated_at" = ?');
      _whereArgs.add(value.millisecondsSinceEpoch);
    }
    return this;
  }

  /// Filter where updatedAt is after [value].
  OrderQueryBuilder updatedAtAfter(DateTime value) {
    _whereConditions.add('"updated_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is before [value].
  OrderQueryBuilder updatedAtBefore(DateTime value) {
    _whereConditions.add('"updated_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is between [start] and [end].
  OrderQueryBuilder updatedAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"updated_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is null.
  OrderQueryBuilder updatedAtIsNull() {
    _whereConditions.add('"updated_at" IS NULL');
    return this;
  }

  /// Filter where updatedAt is not null.
  OrderQueryBuilder updatedAtIsNotNull() {
    _whereConditions.add('"updated_at" IS NOT NULL');
    return this;
  }

  /// Filter where deliveredAt equals [value].
  OrderQueryBuilder deliveredAtEqualTo(DateTime? value) {
    if (value == null) {
      _whereConditions.add('"delivered_at" IS NULL');
    } else {
      _whereConditions.add('"delivered_at" = ?');
      _whereArgs.add(value.millisecondsSinceEpoch);
    }
    return this;
  }

  /// Filter where deliveredAt is after [value].
  OrderQueryBuilder deliveredAtAfter(DateTime value) {
    _whereConditions.add('"delivered_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is before [value].
  OrderQueryBuilder deliveredAtBefore(DateTime value) {
    _whereConditions.add('"delivered_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is between [start] and [end].
  OrderQueryBuilder deliveredAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"delivered_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where deliveredAt is null.
  OrderQueryBuilder deliveredAtIsNull() {
    _whereConditions.add('"delivered_at" IS NULL');
    return this;
  }

  /// Filter where deliveredAt is not null.
  OrderQueryBuilder deliveredAtIsNotNull() {
    _whereConditions.add('"delivered_at" IS NOT NULL');
    return this;
  }

  /// Sort by id in ascending order.
  OrderQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  OrderQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  OrderQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  OrderQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by userId in ascending order.
  OrderQueryBuilder sortByUserIdAsc() {
    _orderBy
      ..clear()
      ..add('"user_id" ASC');
    return this;
  }

  /// Sort by userId in descending order.
  OrderQueryBuilder sortByUserIdDesc() {
    _orderBy
      ..clear()
      ..add('"user_id" DESC');
    return this;
  }

  /// Then sort by userId in ascending order.
  OrderQueryBuilder thenByUserIdAsc() {
    _orderBy.add('"user_id" ASC');
    return this;
  }

  /// Then sort by userId in descending order.
  OrderQueryBuilder thenByUserIdDesc() {
    _orderBy.add('"user_id" DESC');
    return this;
  }

  /// Sort by productId in ascending order.
  OrderQueryBuilder sortByProductIdAsc() {
    _orderBy
      ..clear()
      ..add('"product_id" ASC');
    return this;
  }

  /// Sort by productId in descending order.
  OrderQueryBuilder sortByProductIdDesc() {
    _orderBy
      ..clear()
      ..add('"product_id" DESC');
    return this;
  }

  /// Then sort by productId in ascending order.
  OrderQueryBuilder thenByProductIdAsc() {
    _orderBy.add('"product_id" ASC');
    return this;
  }

  /// Then sort by productId in descending order.
  OrderQueryBuilder thenByProductIdDesc() {
    _orderBy.add('"product_id" DESC');
    return this;
  }

  /// Sort by quantity in ascending order.
  OrderQueryBuilder sortByQuantityAsc() {
    _orderBy
      ..clear()
      ..add('"quantity" ASC');
    return this;
  }

  /// Sort by quantity in descending order.
  OrderQueryBuilder sortByQuantityDesc() {
    _orderBy
      ..clear()
      ..add('"quantity" DESC');
    return this;
  }

  /// Then sort by quantity in ascending order.
  OrderQueryBuilder thenByQuantityAsc() {
    _orderBy.add('"quantity" ASC');
    return this;
  }

  /// Then sort by quantity in descending order.
  OrderQueryBuilder thenByQuantityDesc() {
    _orderBy.add('"quantity" DESC');
    return this;
  }

  /// Sort by totalPrice in ascending order.
  OrderQueryBuilder sortByTotalPriceAsc() {
    _orderBy
      ..clear()
      ..add('"total_price" ASC');
    return this;
  }

  /// Sort by totalPrice in descending order.
  OrderQueryBuilder sortByTotalPriceDesc() {
    _orderBy
      ..clear()
      ..add('"total_price" DESC');
    return this;
  }

  /// Then sort by totalPrice in ascending order.
  OrderQueryBuilder thenByTotalPriceAsc() {
    _orderBy.add('"total_price" ASC');
    return this;
  }

  /// Then sort by totalPrice in descending order.
  OrderQueryBuilder thenByTotalPriceDesc() {
    _orderBy.add('"total_price" DESC');
    return this;
  }

  /// Sort by status in ascending order.
  OrderQueryBuilder sortByStatusAsc() {
    _orderBy
      ..clear()
      ..add('"status" ASC');
    return this;
  }

  /// Sort by status in descending order.
  OrderQueryBuilder sortByStatusDesc() {
    _orderBy
      ..clear()
      ..add('"status" DESC');
    return this;
  }

  /// Then sort by status in ascending order.
  OrderQueryBuilder thenByStatusAsc() {
    _orderBy.add('"status" ASC');
    return this;
  }

  /// Then sort by status in descending order.
  OrderQueryBuilder thenByStatusDesc() {
    _orderBy.add('"status" DESC');
    return this;
  }

  /// Sort by notes in ascending order.
  OrderQueryBuilder sortByNotesAsc() {
    _orderBy
      ..clear()
      ..add('"notes" ASC');
    return this;
  }

  /// Sort by notes in descending order.
  OrderQueryBuilder sortByNotesDesc() {
    _orderBy
      ..clear()
      ..add('"notes" DESC');
    return this;
  }

  /// Then sort by notes in ascending order.
  OrderQueryBuilder thenByNotesAsc() {
    _orderBy.add('"notes" ASC');
    return this;
  }

  /// Then sort by notes in descending order.
  OrderQueryBuilder thenByNotesDesc() {
    _orderBy.add('"notes" DESC');
    return this;
  }

  /// Sort by createdAt in ascending order.
  OrderQueryBuilder sortByCreatedAtAsc() {
    _orderBy
      ..clear()
      ..add('"created_at" ASC');
    return this;
  }

  /// Sort by createdAt in descending order.
  OrderQueryBuilder sortByCreatedAtDesc() {
    _orderBy
      ..clear()
      ..add('"created_at" DESC');
    return this;
  }

  /// Then sort by createdAt in ascending order.
  OrderQueryBuilder thenByCreatedAtAsc() {
    _orderBy.add('"created_at" ASC');
    return this;
  }

  /// Then sort by createdAt in descending order.
  OrderQueryBuilder thenByCreatedAtDesc() {
    _orderBy.add('"created_at" DESC');
    return this;
  }

  /// Sort by updatedAt in ascending order.
  OrderQueryBuilder sortByUpdatedAtAsc() {
    _orderBy
      ..clear()
      ..add('"updated_at" ASC');
    return this;
  }

  /// Sort by updatedAt in descending order.
  OrderQueryBuilder sortByUpdatedAtDesc() {
    _orderBy
      ..clear()
      ..add('"updated_at" DESC');
    return this;
  }

  /// Then sort by updatedAt in ascending order.
  OrderQueryBuilder thenByUpdatedAtAsc() {
    _orderBy.add('"updated_at" ASC');
    return this;
  }

  /// Then sort by updatedAt in descending order.
  OrderQueryBuilder thenByUpdatedAtDesc() {
    _orderBy.add('"updated_at" DESC');
    return this;
  }

  /// Sort by deliveredAt in ascending order.
  OrderQueryBuilder sortByDeliveredAtAsc() {
    _orderBy
      ..clear()
      ..add('"delivered_at" ASC');
    return this;
  }

  /// Sort by deliveredAt in descending order.
  OrderQueryBuilder sortByDeliveredAtDesc() {
    _orderBy
      ..clear()
      ..add('"delivered_at" DESC');
    return this;
  }

  /// Then sort by deliveredAt in ascending order.
  OrderQueryBuilder thenByDeliveredAtAsc() {
    _orderBy.add('"delivered_at" ASC');
    return this;
  }

  /// Then sort by deliveredAt in descending order.
  OrderQueryBuilder thenByDeliveredAtDesc() {
    _orderBy.add('"delivered_at" DESC');
    return this;
  }

  /// Limit the number of results.
  OrderQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  OrderQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Order>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_OrderFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Order?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _OrderFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "orders"$whereClause';
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
      'orders',
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
    return 'SELECT * FROM "orders"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Order].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class OrderRepository {
  final NativeSqliteDatabase database;

  const OrderRepository(this.database);

  /// Inserts a new Order into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(Order entity) async {
    final rowId = await database.insert('orders', {
      'user_id': entity.userId,
      'product_id': entity.productId,
      'quantity': entity.quantity,
      'total_price': entity.totalPrice,
      'status': entity.status.name,
      'notes': entity.notes,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
      'delivered_at': entity.deliveredAt?.millisecondsSinceEpoch,
    });
    return rowId;
  }

  /// Finds a Order by its ID.
  /// Returns null if not found.
  Future<Order?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "orders" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _OrderFromMap(rows.first);
  }

  /// Finds all Orders in the database.
  Future<List<Order>> findAll() async {
    final result = await database.query('SELECT * FROM "orders"');

    return result.toMapList().map(_OrderFromMap).toList();
  }

  /// Updates an existing Order in the database.
  /// Returns the number of rows affected.
  Future<int> update(Order entity) async {
    return database.update(
      'orders',
      {
        'user_id': entity.userId,
        'product_id': entity.productId,
        'quantity': entity.quantity,
        'total_price': entity.totalPrice,
        'status': entity.status.name,
        'notes': entity.notes,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
        'delivered_at': entity.deliveredAt?.millisecondsSinceEpoch,
      },
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Order by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('orders', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('orders');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "orders"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  OrderQueryBuilder queryBuilder() {
    return OrderQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Order objects.
  Future<List<Order>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_OrderFromMap).toList();
  }
}
