import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'product.g.dart';

/// Product model demonstrating:
/// - Foreign key relationships
/// - Multiple data types (int, double, bool, DateTime)
/// - Composite index for category and price
/// - Nullable fields
@Table(
  name: 'products',
  indexes: [
    ['categoryId', 'price'], // Composite index for filtering by category and price
    ['name'], // Index for searching by name
  ],
)
class Product {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column(nullable: false)
  final String name;

  @Column(nullable: true)
  final String? description;

  @Column(nullable: false)
  final double price;

  @Column(nullable: false, defaultValue: '0')
  final int stock;

  @Column(nullable: false, defaultValue: '1')
  final bool isAvailable;

  @ForeignKey(
    table: 'categories',
    column: 'id',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  )
  @Column(nullable: false)
  final int categoryId;

  @Column(nullable: true)
  final String? imageUrl;

  @Column(nullable: false)
  final DateTime createdAt;

  @Column(nullable: true)
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.isAvailable = true,
    required this.categoryId,
    this.imageUrl,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    bool? isAvailable,
    int? categoryId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, description: $description, '
        'price: $price, stock: $stock, isAvailable: $isAvailable, '
        'categoryId: $categoryId, imageUrl: $imageUrl, '
        'createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
