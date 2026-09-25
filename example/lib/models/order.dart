import 'package:native_sqlite/native_sqlite.dart';

part 'order.table.dart';

const Object _unset = Object();

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

/// Order model demonstrating:
/// - Multiple foreign key relationships
/// - String with specific values (status)
/// - Complex business logic
@DbTable(
  name: 'orders',
  indexes: [
    ['userId', 'createdAt'], // Composite index for user order history
    ['status'], // Index for filtering by status
  ],
)
class Order {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @ForeignKey(
    table: 'users',
    column: 'id',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  )
  @DbColumn(nullable: false)
  final int userId;

  @ForeignKey(
    table: 'products',
    column: 'id',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  )
  @DbColumn(nullable: false)
  final int productId;

  @DbColumn(nullable: false)
  final int quantity;

  @DbColumn(nullable: false)
  final double totalPrice;

  /// Stable text storage keeps persisted values safe if enum values reorder.
  @EnumField(type: EnumType.name)
  @DbColumn(nullable: false, defaultValue: "'pending'")
  final OrderStatus status;

  @DbColumn(nullable: true)
  final String? notes;

  @DbColumn(nullable: false)
  final DateTime createdAt;

  @DbColumn(nullable: true)
  final DateTime? updatedAt;

  @DbColumn(nullable: true)
  final DateTime? deliveredAt;

  Order({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    this.status = OrderStatus.pending,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.deliveredAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Order copyWith({
    int? id,
    int? userId,
    int? productId,
    int? quantity,
    double? totalPrice,
    OrderStatus? status,
    Object? notes = _unset,
    DateTime? createdAt,
    Object? updatedAt = _unset,
    Object? deliveredAt = _unset,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      deliveredAt: identical(deliveredAt, _unset)
          ? this.deliveredAt
          : deliveredAt as DateTime?,
    );
  }

  @override
  String toString() {
    return 'Order{id: $id, userId: $userId, productId: $productId, '
        'quantity: $quantity, totalPrice: $totalPrice, status: $status, '
        'notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, '
        'deliveredAt: $deliveredAt}';
  }
}
