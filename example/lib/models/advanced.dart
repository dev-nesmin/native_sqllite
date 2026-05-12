import 'package:native_sqlite/native_sqlite.dart';

part 'advanced.table.dart';

/// User status enum
enum UserStatus { active, inactive, suspended }

/// Priority enum
enum Priority { low, medium, high, urgent }

/// Advanced table demonstrating Phase 2 features:
/// - Duration type support
/// - Uri type support
/// - num type support
/// - Enhanced enum support (ordinal and name)
@DbTable(name: 'advanced_users')
class AdvancedUser {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String name; // Changed back from fullname for testing

  @DbColumn()
  final String? phoneNumber; // NEW COLUMN for migration testing

  // REMOVED email field - testing table recreation migration

  @DbColumn()
  final String? address; // Yet another test column

  @DbColumn()
  final String? country; // NEW: Testing versioned schema generation

  @DbColumn()
  final String? zipCode; // NEW: Testing v3 generation

  @DbColumn()
  final int? age; // Age for migration testing
  @DbColumn()
  final String? city; // City for testing static migrations
  // Duration type - stored as milliseconds INTEGER
  @DbColumn()
  final Duration? loginDuration;

  // Uri type - stored as TEXT
  @DbColumn()
  final Uri? profileUrl;

  // num type - stored as REAL
  @DbColumn()
  final num? score;

  // Enum stored as ordinal (default) - stored as INTEGER
  @EnumField(type: EnumType.ordinal)
  @DbColumn()
  final UserStatus status;

  // Enum stored as name - stored as TEXT
  @EnumField(type: EnumType.name)
  @DbColumn()
  final Priority? priority;

  // Regular fields for comparison
  @DbColumn()
  final DateTime createdAt;

  @DbColumn()
  final bool isVerified;

  const AdvancedUser({
    this.id,
    required this.name,
    this.phoneNumber,
    this.address,
    this.age,
    this.city,
    this.country,
    this.zipCode,
    this.loginDuration,
    this.profileUrl,
    this.score,
    required this.status,
    this.priority,
    required this.createdAt,
    required this.isVerified,
  });

  AdvancedUser copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? address,
    int? age,
    String? city,
    String? country,
    String? zipCode,
    Duration? loginDuration,
    Uri? profileUrl,
    num? score,
    UserStatus? status,
    Priority? priority,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return AdvancedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      age: age ?? this.age,
      city: city ?? this.city,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      loginDuration: loginDuration ?? this.loginDuration,
      profileUrl: profileUrl ?? this.profileUrl,
      score: score ?? this.score,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
