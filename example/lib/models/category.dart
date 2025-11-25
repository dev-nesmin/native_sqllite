import 'package:native_sqlite/native_sqlite.dart';

part 'category.table.dart';

/// Category model demonstrating:
/// - Simple table structure
/// - Unique name constraint
@DbTable(name: 'categories')
class Category {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(unique: true, nullable: false)
  final String name;

  @DbColumn(nullable: true)
  final String? description;

  @DbColumn(nullable: false)
  final DateTime createdAt;

  Category({this.id, required this.name, this.description, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Category copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, description: $description, createdAt: $createdAt}';
  }
}

// Force rebuild 2
