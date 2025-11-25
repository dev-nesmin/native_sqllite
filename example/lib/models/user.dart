import 'package:native_sqlite/native_sqlite.dart';

part 'user.table.dart';

// Force rebuild 4
/// User model demonstrating:
/// - Primary key with auto-increment
/// - Unique constraints
/// - Nullable and non-nullable fields
/// - DateTime handling
/// - Indexes for performance
/// - Default values
@DbTable(
  name: 'users',
  indexes: [
    ['email'], // Single column index for email lookups
    ['createdAt'], // Index for sorting by creation date
  ],
)
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(nullable: false)
  final String name;

  @DbColumn(unique: true, nullable: false)
  final String email;

  @DbColumn(nullable: true)
  final String? phoneNumber;

  @DbColumn(nullable: true)
  final String? address;

  @DbColumn(nullable: false, defaultValue: '1')
  final int age;

  @DbColumn(nullable: false, defaultValue: '1')
  final bool isActive;

  @DbColumn(nullable: false)
  final DateTime createdAt;

  @DbColumn(nullable: true)
  final DateTime? updatedAt;

  // This field is ignored from database
  @Ignore()
  String? tempPassword;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.age = 18,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
    this.tempPassword,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    int? age,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tempPassword,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tempPassword: tempPassword ?? this.tempPassword,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, '
        'address: $address, age: $age, isActive: $isActive, '
        'createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
