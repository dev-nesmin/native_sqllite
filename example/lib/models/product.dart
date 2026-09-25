import 'package:native_sqlite/native_sqlite.dart';

part 'product.table.dart';

const Object _unset = Object();

/// Product model demonstrating:
/// - Foreign key relationship
/// - Multiple indexes (single and composite)
/// - Decimal/double types
/// - Boolean fields
@DbTable(
  name: 'products',
  indexes: [
    ['categoryId', 'price'], // Composite index for category + price queries
    ['name'], // Index for product name searches
  ],
)
class Product {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(nullable: false)
  final String name;

  @DbColumn(nullable: true)
  final String? description;

  @DbColumn(nullable: false)
  final double price;

  @DbColumn(nullable: false, defaultValue: '0')
  final int stock;

  @DbColumn(nullable: false, defaultValue: '1')
  final bool isAvailable;

  @ForeignKey(
    table: 'categories',
    column: 'id',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  )
  @DbColumn(nullable: false)
  final int categoryId;

  @DbColumn(nullable: true)
  final String? imageUrl;

  @DbColumn(nullable: false)
  final DateTime createdAt;

  @DbColumn(nullable: true)
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
    Object? description = _unset,
    double? price,
    int? stock,
    bool? isAvailable,
    int? categoryId,
    Object? imageUrl = _unset,
    DateTime? createdAt,
    Object? updatedAt = _unset,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: identical(imageUrl, _unset)
          ? this.imageUrl
          : imageUrl as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
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
