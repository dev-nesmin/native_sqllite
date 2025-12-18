// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freezed_advanced.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FreezedAdvancedUser _$FreezedAdvancedUserFromJson(Map<String, dynamic> json) =>
    _FreezedAdvancedUser(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      loginDuration: json['loginDuration'] == null
          ? null
          : Duration(microseconds: (json['loginDuration'] as num).toInt()),
      profileUrl: json['profileUrl'] == null
          ? null
          : Uri.parse(json['profileUrl'] as String),
      score: json['score'] as num?,
      status: $enumDecode(_$UserStatusEnumMap, json['status']),
      priority: $enumDecodeNullable(_$PriorityEnumMap, json['priority']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isVerified: json['isVerified'] as bool,
    );

Map<String, dynamic> _$FreezedAdvancedUserToJson(
  _FreezedAdvancedUser instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'loginDuration': instance.loginDuration?.inMicroseconds,
  'profileUrl': instance.profileUrl?.toString(),
  'score': instance.score,
  'status': _$UserStatusEnumMap[instance.status]!,
  'priority': _$PriorityEnumMap[instance.priority],
  'createdAt': instance.createdAt.toIso8601String(),
  'isVerified': instance.isVerified,
};

const _$UserStatusEnumMap = {
  UserStatus.active: 'active',
  UserStatus.inactive: 'inactive',
  UserStatus.suspended: 'suspended',
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
  Priority.urgent: 'urgent',
};
