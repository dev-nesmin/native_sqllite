import 'package:native_sqlite/native_sqlite.dart';

part 'user.table.dart';

const Object _unset = Object();

/// User model demonstrating:
/// - Primary key with auto-increment
/// - Unique constraints
/// - Nullable and non-nullable fields
/// - DateTime handling
/// - Indexes for performance
/// - Default values
@Index(columns: ['phone_number'], name: 'idx_users_phone', unique: true)
@DbTable(
  name: 'users',
  indexes: [
    ['email'], // Single column index for email lookups
    ['created_at'], // SQL column name for sorting by creation date
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

  @DbColumn(nullable: false, defaultValue: '18')
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
    Object? phoneNumber = _unset,
    Object? address = _unset,
    int? age,
    bool? isActive,
    DateTime? createdAt,
    Object? updatedAt = _unset,
    Object? tempPassword = _unset,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: identical(phoneNumber, _unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      address: identical(address, _unset) ? this.address : address as String?,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      tempPassword: identical(tempPassword, _unset)
          ? this.tempPassword
          : tempPassword as String?,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, '
        'address: $address, age: $age, isActive: $isActive, '
        'createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
