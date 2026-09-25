import 'package:native_sqlite/native_sqlite.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';

/// Transaction and batch examples shared by the UI and host tests.
final class OrderDemoService {
  const OrderDemoService(this.database);

  final NativeSqliteDatabase database;

  /// Creates an order and decrements stock as one atomic operation.
  ///
  /// [forceFailure] exists solely for the rollback demonstration and tests.
  Future<int> placeOrder({
    required int userId,
    required int productId,
    required int quantity,
    required double totalPrice,
    OrderStatus status = OrderStatus.pending,
    String? notes,
    bool forceFailure = false,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }

    return database.transaction((transaction) async {
      final changed = await transaction.execute(
        'UPDATE "${ProductSchema.tableName}" '
        'SET "${ProductSchema.STOCK}" = "${ProductSchema.STOCK}" - ? '
        'WHERE "${ProductSchema.ID}" = ? '
        'AND "${ProductSchema.STOCK}" >= ?',
        [quantity, productId, quantity],
      );
      if (changed != 1) {
        throw StateError('Product is missing or has insufficient stock.');
      }

      final orderId = await transaction.insert(OrderSchema.tableName, {
        OrderSchema.USER_ID: userId,
        OrderSchema.PRODUCT_ID: productId,
        OrderSchema.QUANTITY: quantity,
        OrderSchema.TOTAL_PRICE: totalPrice,
        OrderSchema.STATUS: status.name,
        OrderSchema.NOTES: notes,
        OrderSchema.CREATED_AT: DateTime.now().millisecondsSinceEpoch,
      });

      if (forceFailure) {
        throw StateError('Forced failure after both writes.');
      }
      return orderId;
    });
  }

  Future<int> stockFor(int productId) async {
    final result = await database.query(
      'SELECT "${ProductSchema.STOCK}" '
      'FROM "${ProductSchema.tableName}" '
      'WHERE "${ProductSchema.ID}" = ?',
      [productId],
    );
    final rows = result.toMapList();
    if (rows.isEmpty) throw StateError('Product $productId does not exist.');
    return rows.single[ProductSchema.STOCK] as int;
  }

  /// Inserts [count] users in one native batch using bound arguments.
  Future<int> insertUsersBatch({
    required int count,
    required String uniquePrefix,
  }) async {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'must not be negative');
    }

    final batch = database.batch();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < count; index++) {
      batch.execute(
        'INSERT INTO "${UserSchema.tableName}" ('
        '"${UserSchema.NAME}", "${UserSchema.EMAIL}", '
        '"${UserSchema.AGE}", "${UserSchema.IS_ACTIVE}", '
        '"${UserSchema.CREATED_AT}") VALUES (?, ?, ?, ?, ?)',
        [
          'Batch User $index',
          '$uniquePrefix-$index@example.com',
          18 + (index % 70),
          1,
          createdAt,
        ],
      );
    }
    final results = await batch.commit();
    return results.length;
  }
}
