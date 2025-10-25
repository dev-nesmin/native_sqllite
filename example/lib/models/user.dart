import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'user.table.g.dart';

/// Example User model with code generation
@Table(name: 'users')
@Index(columns: ['email'], unique: true)
@Index(columns: ['createdAt'])
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(name: 'email_address', unique: true)
  final String email;

  @Column(nullable: true)
  final int? age;

  @Column()
  final bool isActive;

  @Column()
  final DateTime createdAt;

  @Column(nullable: true)
  final DateTime? lastLogin;

  const User({
    this.id,
    required this.name,
    required this.email,
    this.age,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    int? age,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, age: $age, '
        'isActive: $isActive, createdAt: $createdAt, lastLogin: $lastLogin)';
  }
}
