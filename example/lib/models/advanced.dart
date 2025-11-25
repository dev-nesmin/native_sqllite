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
  final String name;

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

// Force rebuild 2
