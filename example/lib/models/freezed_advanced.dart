import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:native_sqlite/native_sqlite.dart';

part 'freezed_advanced.freezed.dart';
part 'freezed_advanced.g.dart';
part 'freezed_advanced.table.dart';

/// User status enum
enum UserStatus { active, inactive, suspended }

/// Priority enum
enum Priority { low, medium, high, urgent }

/// Advanced table demonstrating Phase 2 features:
/// - Duration type support
/// - Uri type support
/// - num type support
/// - Enhanced enum support (ordinal and name)
@freezed
@DbTable(name: 'freezed_advanced_users') // Renamed to avoid conflict
abstract class FreezedAdvancedUser with _$FreezedAdvancedUser {
  const factory FreezedAdvancedUser({
    @PrimaryKey(autoIncrement: true) int? id,
    required String name,
    Duration? loginDuration,
    Uri? profileUrl,
    @DbColumn(ignore: true) num? score,
    required UserStatus status,
    Priority? priority,
    required DateTime createdAt,
    required bool isVerified,
  }) = _FreezedAdvancedUser;

  factory FreezedAdvancedUser.fromJson(Map<String, dynamic> json) =>
      _$FreezedAdvancedUserFromJson(json);
}
