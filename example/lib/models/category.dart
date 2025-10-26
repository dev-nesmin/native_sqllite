import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'category.g.dart';

/// Category model demonstrating:
/// - Simple table structure
/// - Unique name constraint
@Table(name: 'categories')
class Category {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column(unique: true, nullable: false)
  final String name;

  @Column(nullable: true)
  final String? description;

  @Column(nullable: false)
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
