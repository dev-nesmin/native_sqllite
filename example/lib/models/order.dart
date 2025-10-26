import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'order.g.dart';

/// Order model demonstrating:
/// - Multiple foreign key relationships
/// - String with specific values (status)
/// - Complex business logic
@Table(
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
  @Column(nullable: false)
  final int userId;

  @ForeignKey(
    table: 'products',
    column: 'id',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  )
  @Column(nullable: false)
  final int productId;

  @Column(nullable: false)
  final int quantity;

  @Column(nullable: false)
  final double totalPrice;

  /// Status can be: pending, processing, shipped, delivered, cancelled
  @Column(nullable: false, defaultValue: "'pending'")
  final String status;

  @Column(nullable: true)
  final String? notes;

  @Column(nullable: false)
  final DateTime createdAt;

  @Column(nullable: true)
  final DateTime? updatedAt;

  @Column(nullable: true)
  final DateTime? deliveredAt;

  Order({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    this.status = 'pending',
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
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
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
