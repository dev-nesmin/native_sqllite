import 'package:native_sqlite/native_sqlite.dart';

part 'category.table.dart';

const Object _unset = Object();

/// Category model demonstrating:
/// - Simple table structure
/// - Unique name constraint
@DbTable(name: 'categories')
class Category {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(unique: true)
  final String name;

  final String? description;

  final DateTime createdAt;

  Category({this.id, required this.name, this.description, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Category copyWith({
    int? id,
    String? name,
    Object? description = _unset,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, description: $description, createdAt: $createdAt}';
  }
}
