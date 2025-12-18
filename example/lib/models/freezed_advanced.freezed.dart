// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'freezed_advanced.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FreezedAdvancedUser {

@PrimaryKey(autoIncrement: true) int? get id; String get name; Duration? get loginDuration; Uri? get profileUrl;@DbColumn(ignore: true) num? get score; UserStatus get status; Priority? get priority; DateTime get createdAt; bool get isVerified;
/// Create a copy of FreezedAdvancedUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreezedAdvancedUserCopyWith<FreezedAdvancedUser> get copyWith => _$FreezedAdvancedUserCopyWithImpl<FreezedAdvancedUser>(this as FreezedAdvancedUser, _$identity);

  /// Serializes this FreezedAdvancedUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreezedAdvancedUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.loginDuration, loginDuration) || other.loginDuration == loginDuration)&&(identical(other.profileUrl, profileUrl) || other.profileUrl == profileUrl)&&(identical(other.score, score) || other.score == score)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,loginDuration,profileUrl,score,status,priority,createdAt,isVerified);

@override
String toString() {
  return 'FreezedAdvancedUser(id: $id, name: $name, loginDuration: $loginDuration, profileUrl: $profileUrl, score: $score, status: $status, priority: $priority, createdAt: $createdAt, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $FreezedAdvancedUserCopyWith<$Res>  {
  factory $FreezedAdvancedUserCopyWith(FreezedAdvancedUser value, $Res Function(FreezedAdvancedUser) _then) = _$FreezedAdvancedUserCopyWithImpl;
@useResult
$Res call({
@PrimaryKey(autoIncrement: true) int? id, String name, Duration? loginDuration, Uri? profileUrl,@DbColumn(ignore: true) num? score, UserStatus status, Priority? priority, DateTime createdAt, bool isVerified
});




}
/// @nodoc
class _$FreezedAdvancedUserCopyWithImpl<$Res>
    implements $FreezedAdvancedUserCopyWith<$Res> {
  _$FreezedAdvancedUserCopyWithImpl(this._self, this._then);

  final FreezedAdvancedUser _self;
  final $Res Function(FreezedAdvancedUser) _then;

/// Create a copy of FreezedAdvancedUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? loginDuration = freezed,Object? profileUrl = freezed,Object? score = freezed,Object? status = null,Object? priority = freezed,Object? createdAt = null,Object? isVerified = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,loginDuration: freezed == loginDuration ? _self.loginDuration : loginDuration // ignore: cast_nullable_to_non_nullable
as Duration?,profileUrl: freezed == profileUrl ? _self.profileUrl : profileUrl // ignore: cast_nullable_to_non_nullable
as Uri?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FreezedAdvancedUser].
extension FreezedAdvancedUserPatterns on FreezedAdvancedUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreezedAdvancedUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreezedAdvancedUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreezedAdvancedUser value)  $default,){
final _that = this;
switch (_that) {
case _FreezedAdvancedUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreezedAdvancedUser value)?  $default,){
final _that = this;
switch (_that) {
case _FreezedAdvancedUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@PrimaryKey(autoIncrement: true)  int? id,  String name,  Duration? loginDuration,  Uri? profileUrl, @DbColumn(ignore: true)  num? score,  UserStatus status,  Priority? priority,  DateTime createdAt,  bool isVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreezedAdvancedUser() when $default != null:
return $default(_that.id,_that.name,_that.loginDuration,_that.profileUrl,_that.score,_that.status,_that.priority,_that.createdAt,_that.isVerified);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@PrimaryKey(autoIncrement: true)  int? id,  String name,  Duration? loginDuration,  Uri? profileUrl, @DbColumn(ignore: true)  num? score,  UserStatus status,  Priority? priority,  DateTime createdAt,  bool isVerified)  $default,) {final _that = this;
switch (_that) {
case _FreezedAdvancedUser():
return $default(_that.id,_that.name,_that.loginDuration,_that.profileUrl,_that.score,_that.status,_that.priority,_that.createdAt,_that.isVerified);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@PrimaryKey(autoIncrement: true)  int? id,  String name,  Duration? loginDuration,  Uri? profileUrl, @DbColumn(ignore: true)  num? score,  UserStatus status,  Priority? priority,  DateTime createdAt,  bool isVerified)?  $default,) {final _that = this;
switch (_that) {
case _FreezedAdvancedUser() when $default != null:
return $default(_that.id,_that.name,_that.loginDuration,_that.profileUrl,_that.score,_that.status,_that.priority,_that.createdAt,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FreezedAdvancedUser implements FreezedAdvancedUser {
  const _FreezedAdvancedUser({@PrimaryKey(autoIncrement: true) this.id, required this.name, this.loginDuration, this.profileUrl, @DbColumn(ignore: true) this.score, required this.status, this.priority, required this.createdAt, required this.isVerified});
  factory _FreezedAdvancedUser.fromJson(Map<String, dynamic> json) => _$FreezedAdvancedUserFromJson(json);

@override@PrimaryKey(autoIncrement: true) final  int? id;
@override final  String name;
@override final  Duration? loginDuration;
@override final  Uri? profileUrl;
@override@DbColumn(ignore: true) final  num? score;
@override final  UserStatus status;
@override final  Priority? priority;
@override final  DateTime createdAt;
@override final  bool isVerified;

/// Create a copy of FreezedAdvancedUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreezedAdvancedUserCopyWith<_FreezedAdvancedUser> get copyWith => __$FreezedAdvancedUserCopyWithImpl<_FreezedAdvancedUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FreezedAdvancedUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreezedAdvancedUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.loginDuration, loginDuration) || other.loginDuration == loginDuration)&&(identical(other.profileUrl, profileUrl) || other.profileUrl == profileUrl)&&(identical(other.score, score) || other.score == score)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,loginDuration,profileUrl,score,status,priority,createdAt,isVerified);

@override
String toString() {
  return 'FreezedAdvancedUser(id: $id, name: $name, loginDuration: $loginDuration, profileUrl: $profileUrl, score: $score, status: $status, priority: $priority, createdAt: $createdAt, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$FreezedAdvancedUserCopyWith<$Res> implements $FreezedAdvancedUserCopyWith<$Res> {
  factory _$FreezedAdvancedUserCopyWith(_FreezedAdvancedUser value, $Res Function(_FreezedAdvancedUser) _then) = __$FreezedAdvancedUserCopyWithImpl;
@override @useResult
$Res call({
@PrimaryKey(autoIncrement: true) int? id, String name, Duration? loginDuration, Uri? profileUrl,@DbColumn(ignore: true) num? score, UserStatus status, Priority? priority, DateTime createdAt, bool isVerified
});




}
/// @nodoc
class __$FreezedAdvancedUserCopyWithImpl<$Res>
    implements _$FreezedAdvancedUserCopyWith<$Res> {
  __$FreezedAdvancedUserCopyWithImpl(this._self, this._then);

  final _FreezedAdvancedUser _self;
  final $Res Function(_FreezedAdvancedUser) _then;

/// Create a copy of FreezedAdvancedUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? loginDuration = freezed,Object? profileUrl = freezed,Object? score = freezed,Object? status = null,Object? priority = freezed,Object? createdAt = null,Object? isVerified = null,}) {
  return _then(_FreezedAdvancedUser(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,loginDuration: freezed == loginDuration ? _self.loginDuration : loginDuration // ignore: cast_nullable_to_non_nullable
as Duration?,profileUrl: freezed == profileUrl ? _self.profileUrl : profileUrl // ignore: cast_nullable_to_non_nullable
as Uri?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
