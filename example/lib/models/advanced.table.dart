// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'advanced.dart';

/// Generated table schema for [AdvancedUser].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class AdvancedUserSchema {
  static const String tableName = 'advanced_users';

  static const String createTableSql =
      'CREATE TABLE "advanced_users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "phone_number" TEXT, "address" TEXT, "country" TEXT, "zip_code" TEXT, "age" INTEGER, "city" TEXT, "login_duration" INTEGER, "profile_url" TEXT, "score" REAL, "status" INTEGER NOT NULL, "priority" TEXT, "created_at" INTEGER NOT NULL, "is_verified" INTEGER NOT NULL)';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String PHONE_NUMBER = 'phone_number';
  static const String ADDRESS = 'address';
  static const String COUNTRY = 'country';
  static const String ZIP_CODE = 'zip_code';
  static const String AGE = 'age';
  static const String CITY = 'city';
  static const String LOGIN_DURATION = 'login_duration';
  static const String PROFILE_URL = 'profile_url';
  static const String SCORE = 'score';
  static const String STATUS = 'status';
  static const String PRIORITY = 'priority';
  static const String CREATED_AT = 'created_at';
  static const String IS_VERIFIED = 'is_verified';
}

AdvancedUser _AdvancedUserFromMap(Map<String, Object?> map) {
  return AdvancedUser(
    id: map['id'] as int?,
    name: map['name'] as String,
    phoneNumber: map['phone_number'] as String?,
    address: map['address'] as String?,
    age: map['age'] as int?,
    city: map['city'] as String?,
    country: map['country'] as String?,
    zipCode: map['zip_code'] as String?,
    loginDuration: map['login_duration'] != null
        ? Duration(milliseconds: map['login_duration'] as int)
        : null,
    profileUrl: map['profile_url'] != null
        ? Uri.parse(map['profile_url'] as String)
        : null,
    score: map['score'] as num?,
    status: UserStatus.values[map['status'] as int],
    priority: map['priority'] != null
        ? Priority.values.firstWhere((e) => e.name == map['priority'])
        : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    isVerified: (map['is_verified'] as int) == 1,
  );
}

/// Generated query builder for [AdvancedUser].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class AdvancedUserQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  AdvancedUserQueryBuilder(this._database);

  /// Filter where id equals [value].
  AdvancedUserQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  AdvancedUserQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  AdvancedUserQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  AdvancedUserQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  AdvancedUserQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  AdvancedUserQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where name equals [value].
  AdvancedUserQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('"name" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  AdvancedUserQueryBuilder nameContains(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name starts with [value].
  AdvancedUserQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name ends with [value].
  AdvancedUserQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where phoneNumber equals [value].
  AdvancedUserQueryBuilder phoneNumberEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"phone_number" IS NULL');
    } else {
      _whereConditions.add('"phone_number" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where phoneNumber contains [value].
  AdvancedUserQueryBuilder phoneNumberContains(String value) {
    _whereConditions.add('"phone_number" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where phoneNumber starts with [value].
  AdvancedUserQueryBuilder phoneNumberStartsWith(String value) {
    _whereConditions.add('"phone_number" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where phoneNumber ends with [value].
  AdvancedUserQueryBuilder phoneNumberEndsWith(String value) {
    _whereConditions.add('"phone_number" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where phoneNumber is null.
  AdvancedUserQueryBuilder phoneNumberIsNull() {
    _whereConditions.add('"phone_number" IS NULL');
    return this;
  }

  /// Filter where phoneNumber is not null.
  AdvancedUserQueryBuilder phoneNumberIsNotNull() {
    _whereConditions.add('"phone_number" IS NOT NULL');
    return this;
  }

  /// Filter where address equals [value].
  AdvancedUserQueryBuilder addressEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"address" IS NULL');
    } else {
      _whereConditions.add('"address" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where address contains [value].
  AdvancedUserQueryBuilder addressContains(String value) {
    _whereConditions.add('"address" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where address starts with [value].
  AdvancedUserQueryBuilder addressStartsWith(String value) {
    _whereConditions.add('"address" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where address ends with [value].
  AdvancedUserQueryBuilder addressEndsWith(String value) {
    _whereConditions.add('"address" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where address is null.
  AdvancedUserQueryBuilder addressIsNull() {
    _whereConditions.add('"address" IS NULL');
    return this;
  }

  /// Filter where address is not null.
  AdvancedUserQueryBuilder addressIsNotNull() {
    _whereConditions.add('"address" IS NOT NULL');
    return this;
  }

  /// Filter where country equals [value].
  AdvancedUserQueryBuilder countryEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"country" IS NULL');
    } else {
      _whereConditions.add('"country" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where country contains [value].
  AdvancedUserQueryBuilder countryContains(String value) {
    _whereConditions.add('"country" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where country starts with [value].
  AdvancedUserQueryBuilder countryStartsWith(String value) {
    _whereConditions.add('"country" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where country ends with [value].
  AdvancedUserQueryBuilder countryEndsWith(String value) {
    _whereConditions.add('"country" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where country is null.
  AdvancedUserQueryBuilder countryIsNull() {
    _whereConditions.add('"country" IS NULL');
    return this;
  }

  /// Filter where country is not null.
  AdvancedUserQueryBuilder countryIsNotNull() {
    _whereConditions.add('"country" IS NOT NULL');
    return this;
  }

  /// Filter where zipCode equals [value].
  AdvancedUserQueryBuilder zipCodeEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"zip_code" IS NULL');
    } else {
      _whereConditions.add('"zip_code" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where zipCode contains [value].
  AdvancedUserQueryBuilder zipCodeContains(String value) {
    _whereConditions.add('"zip_code" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where zipCode starts with [value].
  AdvancedUserQueryBuilder zipCodeStartsWith(String value) {
    _whereConditions.add('"zip_code" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where zipCode ends with [value].
  AdvancedUserQueryBuilder zipCodeEndsWith(String value) {
    _whereConditions.add('"zip_code" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where zipCode is null.
  AdvancedUserQueryBuilder zipCodeIsNull() {
    _whereConditions.add('"zip_code" IS NULL');
    return this;
  }

  /// Filter where zipCode is not null.
  AdvancedUserQueryBuilder zipCodeIsNotNull() {
    _whereConditions.add('"zip_code" IS NOT NULL');
    return this;
  }

  /// Filter where age equals [value].
  AdvancedUserQueryBuilder ageEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"age" IS NULL');
    } else {
      _whereConditions.add('"age" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where age is greater than [value].
  AdvancedUserQueryBuilder ageGreaterThan(int value) {
    _whereConditions.add('"age" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where age is less than [value].
  AdvancedUserQueryBuilder ageLessThan(int value) {
    _whereConditions.add('"age" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where age is between [min] and [max].
  AdvancedUserQueryBuilder ageBetween(int min, int max) {
    _whereConditions.add('"age" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where age is null.
  AdvancedUserQueryBuilder ageIsNull() {
    _whereConditions.add('"age" IS NULL');
    return this;
  }

  /// Filter where age is not null.
  AdvancedUserQueryBuilder ageIsNotNull() {
    _whereConditions.add('"age" IS NOT NULL');
    return this;
  }

  /// Filter where city equals [value].
  AdvancedUserQueryBuilder cityEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"city" IS NULL');
    } else {
      _whereConditions.add('"city" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where city contains [value].
  AdvancedUserQueryBuilder cityContains(String value) {
    _whereConditions.add('"city" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where city starts with [value].
  AdvancedUserQueryBuilder cityStartsWith(String value) {
    _whereConditions.add('"city" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where city ends with [value].
  AdvancedUserQueryBuilder cityEndsWith(String value) {
    _whereConditions.add('"city" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where city is null.
  AdvancedUserQueryBuilder cityIsNull() {
    _whereConditions.add('"city" IS NULL');
    return this;
  }

  /// Filter where city is not null.
  AdvancedUserQueryBuilder cityIsNotNull() {
    _whereConditions.add('"city" IS NOT NULL');
    return this;
  }

  /// Filter where loginDuration equals [value].
  AdvancedUserQueryBuilder loginDurationEqualTo(Duration? value) {
    if (value == null) {
      _whereConditions.add('"login_duration" IS NULL');
    } else {
      _whereConditions.add('"login_duration" = ?');
      _whereArgs.add(value.inMilliseconds);
    }
    return this;
  }

  /// Filter where loginDuration is greater than [value].
  AdvancedUserQueryBuilder loginDurationGreaterThan(Duration value) {
    _whereConditions.add('"login_duration" > ?');
    _whereArgs.add(value.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is less than [value].
  AdvancedUserQueryBuilder loginDurationLessThan(Duration value) {
    _whereConditions.add('"login_duration" < ?');
    _whereArgs.add(value.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is null.
  AdvancedUserQueryBuilder loginDurationIsNull() {
    _whereConditions.add('"login_duration" IS NULL');
    return this;
  }

  /// Filter where loginDuration is not null.
  AdvancedUserQueryBuilder loginDurationIsNotNull() {
    _whereConditions.add('"login_duration" IS NOT NULL');
    return this;
  }

  /// Filter where profileUrl is null.
  AdvancedUserQueryBuilder profileUrlIsNull() {
    _whereConditions.add('"profile_url" IS NULL');
    return this;
  }

  /// Filter where profileUrl is not null.
  AdvancedUserQueryBuilder profileUrlIsNotNull() {
    _whereConditions.add('"profile_url" IS NOT NULL');
    return this;
  }

  /// Filter where score equals [value].
  AdvancedUserQueryBuilder scoreEqualTo(num? value) {
    if (value == null) {
      _whereConditions.add('"score" IS NULL');
    } else {
      _whereConditions.add('"score" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where score is greater than [value].
  AdvancedUserQueryBuilder scoreGreaterThan(num value) {
    _whereConditions.add('"score" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where score is less than [value].
  AdvancedUserQueryBuilder scoreLessThan(num value) {
    _whereConditions.add('"score" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where score is between [min] and [max].
  AdvancedUserQueryBuilder scoreBetween(num min, num max) {
    _whereConditions.add('"score" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where score is null.
  AdvancedUserQueryBuilder scoreIsNull() {
    _whereConditions.add('"score" IS NULL');
    return this;
  }

  /// Filter where score is not null.
  AdvancedUserQueryBuilder scoreIsNotNull() {
    _whereConditions.add('"score" IS NOT NULL');
    return this;
  }

  /// Filter where status equals [value].
  AdvancedUserQueryBuilder statusEqualTo(UserStatus value) {
    _whereConditions.add('"status" = ?');
    _whereArgs.add(value.index);
    return this;
  }

  /// Filter where priority equals [value].
  AdvancedUserQueryBuilder priorityEqualTo(Priority? value) {
    if (value == null) {
      _whereConditions.add('"priority" IS NULL');
    } else {
      _whereConditions.add('"priority" = ?');
      _whereArgs.add(value.name);
    }
    return this;
  }

  /// Filter where priority is null.
  AdvancedUserQueryBuilder priorityIsNull() {
    _whereConditions.add('"priority" IS NULL');
    return this;
  }

  /// Filter where priority is not null.
  AdvancedUserQueryBuilder priorityIsNotNull() {
    _whereConditions.add('"priority" IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  AdvancedUserQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('"created_at" = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  AdvancedUserQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('"created_at" > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  AdvancedUserQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('"created_at" < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  AdvancedUserQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('"created_at" BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where isVerified is true.
  AdvancedUserQueryBuilder isVerifiedIsTrue() {
    _whereConditions.add('"is_verified" = ?');
    _whereArgs.add(1);
    return this;
  }

  /// Filter where isVerified is false.
  AdvancedUserQueryBuilder isVerifiedIsFalse() {
    _whereConditions.add('"is_verified" = ?');
    _whereArgs.add(0);
    return this;
  }

  /// Sort by id in ascending order.
  AdvancedUserQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  AdvancedUserQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  AdvancedUserQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  AdvancedUserQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by name in ascending order.
  AdvancedUserQueryBuilder sortByNameAsc() {
    _orderBy
      ..clear()
      ..add('"name" ASC');
    return this;
  }

  /// Sort by name in descending order.
  AdvancedUserQueryBuilder sortByNameDesc() {
    _orderBy
      ..clear()
      ..add('"name" DESC');
    return this;
  }

  /// Then sort by name in ascending order.
  AdvancedUserQueryBuilder thenByNameAsc() {
    _orderBy.add('"name" ASC');
    return this;
  }

  /// Then sort by name in descending order.
  AdvancedUserQueryBuilder thenByNameDesc() {
    _orderBy.add('"name" DESC');
    return this;
  }

  /// Sort by phoneNumber in ascending order.
  AdvancedUserQueryBuilder sortByPhoneNumberAsc() {
    _orderBy
      ..clear()
      ..add('"phone_number" ASC');
    return this;
  }

  /// Sort by phoneNumber in descending order.
  AdvancedUserQueryBuilder sortByPhoneNumberDesc() {
    _orderBy
      ..clear()
      ..add('"phone_number" DESC');
    return this;
  }

  /// Then sort by phoneNumber in ascending order.
  AdvancedUserQueryBuilder thenByPhoneNumberAsc() {
    _orderBy.add('"phone_number" ASC');
    return this;
  }

  /// Then sort by phoneNumber in descending order.
  AdvancedUserQueryBuilder thenByPhoneNumberDesc() {
    _orderBy.add('"phone_number" DESC');
    return this;
  }

  /// Sort by address in ascending order.
  AdvancedUserQueryBuilder sortByAddressAsc() {
    _orderBy
      ..clear()
      ..add('"address" ASC');
    return this;
  }

  /// Sort by address in descending order.
  AdvancedUserQueryBuilder sortByAddressDesc() {
    _orderBy
      ..clear()
      ..add('"address" DESC');
    return this;
  }

  /// Then sort by address in ascending order.
  AdvancedUserQueryBuilder thenByAddressAsc() {
    _orderBy.add('"address" ASC');
    return this;
  }

  /// Then sort by address in descending order.
  AdvancedUserQueryBuilder thenByAddressDesc() {
    _orderBy.add('"address" DESC');
    return this;
  }

  /// Sort by country in ascending order.
  AdvancedUserQueryBuilder sortByCountryAsc() {
    _orderBy
      ..clear()
      ..add('"country" ASC');
    return this;
  }

  /// Sort by country in descending order.
  AdvancedUserQueryBuilder sortByCountryDesc() {
    _orderBy
      ..clear()
      ..add('"country" DESC');
    return this;
  }

  /// Then sort by country in ascending order.
  AdvancedUserQueryBuilder thenByCountryAsc() {
    _orderBy.add('"country" ASC');
    return this;
  }

  /// Then sort by country in descending order.
  AdvancedUserQueryBuilder thenByCountryDesc() {
    _orderBy.add('"country" DESC');
    return this;
  }

  /// Sort by zipCode in ascending order.
  AdvancedUserQueryBuilder sortByZipCodeAsc() {
    _orderBy
      ..clear()
      ..add('"zip_code" ASC');
    return this;
  }

  /// Sort by zipCode in descending order.
  AdvancedUserQueryBuilder sortByZipCodeDesc() {
    _orderBy
      ..clear()
      ..add('"zip_code" DESC');
    return this;
  }

  /// Then sort by zipCode in ascending order.
  AdvancedUserQueryBuilder thenByZipCodeAsc() {
    _orderBy.add('"zip_code" ASC');
    return this;
  }

  /// Then sort by zipCode in descending order.
  AdvancedUserQueryBuilder thenByZipCodeDesc() {
    _orderBy.add('"zip_code" DESC');
    return this;
  }

  /// Sort by age in ascending order.
  AdvancedUserQueryBuilder sortByAgeAsc() {
    _orderBy
      ..clear()
      ..add('"age" ASC');
    return this;
  }

  /// Sort by age in descending order.
  AdvancedUserQueryBuilder sortByAgeDesc() {
    _orderBy
      ..clear()
      ..add('"age" DESC');
    return this;
  }

  /// Then sort by age in ascending order.
  AdvancedUserQueryBuilder thenByAgeAsc() {
    _orderBy.add('"age" ASC');
    return this;
  }

  /// Then sort by age in descending order.
  AdvancedUserQueryBuilder thenByAgeDesc() {
    _orderBy.add('"age" DESC');
    return this;
  }

  /// Sort by city in ascending order.
  AdvancedUserQueryBuilder sortByCityAsc() {
    _orderBy
      ..clear()
      ..add('"city" ASC');
    return this;
  }

  /// Sort by city in descending order.
  AdvancedUserQueryBuilder sortByCityDesc() {
    _orderBy
      ..clear()
      ..add('"city" DESC');
    return this;
  }

  /// Then sort by city in ascending order.
  AdvancedUserQueryBuilder thenByCityAsc() {
    _orderBy.add('"city" ASC');
    return this;
  }

  /// Then sort by city in descending order.
  AdvancedUserQueryBuilder thenByCityDesc() {
    _orderBy.add('"city" DESC');
    return this;
  }

  /// Sort by loginDuration in ascending order.
  AdvancedUserQueryBuilder sortByLoginDurationAsc() {
    _orderBy
      ..clear()
      ..add('"login_duration" ASC');
    return this;
  }

  /// Sort by loginDuration in descending order.
  AdvancedUserQueryBuilder sortByLoginDurationDesc() {
    _orderBy
      ..clear()
      ..add('"login_duration" DESC');
    return this;
  }

  /// Then sort by loginDuration in ascending order.
  AdvancedUserQueryBuilder thenByLoginDurationAsc() {
    _orderBy.add('"login_duration" ASC');
    return this;
  }

  /// Then sort by loginDuration in descending order.
  AdvancedUserQueryBuilder thenByLoginDurationDesc() {
    _orderBy.add('"login_duration" DESC');
    return this;
  }

  /// Sort by profileUrl in ascending order.
  AdvancedUserQueryBuilder sortByProfileUrlAsc() {
    _orderBy
      ..clear()
      ..add('"profile_url" ASC');
    return this;
  }

  /// Sort by profileUrl in descending order.
  AdvancedUserQueryBuilder sortByProfileUrlDesc() {
    _orderBy
      ..clear()
      ..add('"profile_url" DESC');
    return this;
  }

  /// Then sort by profileUrl in ascending order.
  AdvancedUserQueryBuilder thenByProfileUrlAsc() {
    _orderBy.add('"profile_url" ASC');
    return this;
  }

  /// Then sort by profileUrl in descending order.
  AdvancedUserQueryBuilder thenByProfileUrlDesc() {
    _orderBy.add('"profile_url" DESC');
    return this;
  }

  /// Sort by score in ascending order.
  AdvancedUserQueryBuilder sortByScoreAsc() {
    _orderBy
      ..clear()
      ..add('"score" ASC');
    return this;
  }

  /// Sort by score in descending order.
  AdvancedUserQueryBuilder sortByScoreDesc() {
    _orderBy
      ..clear()
      ..add('"score" DESC');
    return this;
  }

  /// Then sort by score in ascending order.
  AdvancedUserQueryBuilder thenByScoreAsc() {
    _orderBy.add('"score" ASC');
    return this;
  }

  /// Then sort by score in descending order.
  AdvancedUserQueryBuilder thenByScoreDesc() {
    _orderBy.add('"score" DESC');
    return this;
  }

  /// Sort by status in ascending order.
  AdvancedUserQueryBuilder sortByStatusAsc() {
    _orderBy
      ..clear()
      ..add('"status" ASC');
    return this;
  }

  /// Sort by status in descending order.
  AdvancedUserQueryBuilder sortByStatusDesc() {
    _orderBy
      ..clear()
      ..add('"status" DESC');
    return this;
  }

  /// Then sort by status in ascending order.
  AdvancedUserQueryBuilder thenByStatusAsc() {
    _orderBy.add('"status" ASC');
    return this;
  }

  /// Then sort by status in descending order.
  AdvancedUserQueryBuilder thenByStatusDesc() {
    _orderBy.add('"status" DESC');
    return this;
  }

  /// Sort by priority in ascending order.
  AdvancedUserQueryBuilder sortByPriorityAsc() {
    _orderBy
      ..clear()
      ..add('"priority" ASC');
    return this;
  }

  /// Sort by priority in descending order.
  AdvancedUserQueryBuilder sortByPriorityDesc() {
    _orderBy
      ..clear()
      ..add('"priority" DESC');
    return this;
  }

  /// Then sort by priority in ascending order.
  AdvancedUserQueryBuilder thenByPriorityAsc() {
    _orderBy.add('"priority" ASC');
    return this;
  }

  /// Then sort by priority in descending order.
  AdvancedUserQueryBuilder thenByPriorityDesc() {
    _orderBy.add('"priority" DESC');
    return this;
  }

  /// Sort by createdAt in ascending order.
  AdvancedUserQueryBuilder sortByCreatedAtAsc() {
    _orderBy
      ..clear()
      ..add('"created_at" ASC');
    return this;
  }

  /// Sort by createdAt in descending order.
  AdvancedUserQueryBuilder sortByCreatedAtDesc() {
    _orderBy
      ..clear()
      ..add('"created_at" DESC');
    return this;
  }

  /// Then sort by createdAt in ascending order.
  AdvancedUserQueryBuilder thenByCreatedAtAsc() {
    _orderBy.add('"created_at" ASC');
    return this;
  }

  /// Then sort by createdAt in descending order.
  AdvancedUserQueryBuilder thenByCreatedAtDesc() {
    _orderBy.add('"created_at" DESC');
    return this;
  }

  /// Sort by isVerified in ascending order.
  AdvancedUserQueryBuilder sortByIsVerifiedAsc() {
    _orderBy
      ..clear()
      ..add('"is_verified" ASC');
    return this;
  }

  /// Sort by isVerified in descending order.
  AdvancedUserQueryBuilder sortByIsVerifiedDesc() {
    _orderBy
      ..clear()
      ..add('"is_verified" DESC');
    return this;
  }

  /// Then sort by isVerified in ascending order.
  AdvancedUserQueryBuilder thenByIsVerifiedAsc() {
    _orderBy.add('"is_verified" ASC');
    return this;
  }

  /// Then sort by isVerified in descending order.
  AdvancedUserQueryBuilder thenByIsVerifiedDesc() {
    _orderBy.add('"is_verified" DESC');
    return this;
  }

  /// Limit the number of results.
  AdvancedUserQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  AdvancedUserQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<AdvancedUser>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_AdvancedUserFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<AdvancedUser?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _AdvancedUserFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "advanced_users"$whereClause';
    final result = await _database.query(sql, _whereArgs);
    final rows = result.toMapList();
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  /// Delete all matching records.
  Future<int> deleteAll() async {
    final whereClause = _whereConditions.isEmpty
        ? null
        : _whereConditions.join(' AND ');
    return _database.delete(
      'advanced_users',
      where: whereClause,
      whereArgs: _whereArgs.isEmpty ? null : _whereArgs,
    );
  }

  /// The parameterized SQL represented by this builder.
  String toSql() => _buildQuery();

  /// Alias for [toSql], intended for logs and debuggers.
  String get debugSql => toSql();

  /// Bound values in placeholder order.
  List<Object?> get arguments => List<Object?>.unmodifiable(_whereArgs);

  String _buildQuery({int? limitOverride}) {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final orderClause = _orderBy.isEmpty
        ? ''
        : ' ORDER BY ${_orderBy.join(', ')}';
    final effectiveLimit = limitOverride ?? _limit;
    final limitClause = effectiveLimit != null
        ? ' LIMIT $effectiveLimit'
        : (_offset == null ? '' : ' LIMIT -1');
    final offsetClause = _offset == null ? '' : ' OFFSET $_offset';
    return 'SELECT * FROM "advanced_users"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [AdvancedUser].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class AdvancedUserRepository {
  final NativeSqliteDatabase database;

  const AdvancedUserRepository(this.database);

  /// Inserts a new AdvancedUser into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(AdvancedUser entity) async {
    final rowId = await database.insert('advanced_users', {
      'name': entity.name,
      'phone_number': entity.phoneNumber,
      'address': entity.address,
      'country': entity.country,
      'zip_code': entity.zipCode,
      'age': entity.age,
      'city': entity.city,
      'login_duration': entity.loginDuration?.inMilliseconds,
      'profile_url': entity.profileUrl?.toString(),
      'score': entity.score,
      'status': entity.status.index,
      'priority': entity.priority?.name,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'is_verified': entity.isVerified ? 1 : 0,
    });
    return rowId;
  }

  /// Finds a AdvancedUser by its ID.
  /// Returns null if not found.
  Future<AdvancedUser?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "advanced_users" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _AdvancedUserFromMap(rows.first);
  }

  /// Finds all AdvancedUsers in the database.
  Future<List<AdvancedUser>> findAll() async {
    final result = await database.query('SELECT * FROM "advanced_users"');

    return result.toMapList().map(_AdvancedUserFromMap).toList();
  }

  /// Updates an existing AdvancedUser in the database.
  /// Returns the number of rows affected.
  Future<int> update(AdvancedUser entity) async {
    return database.update(
      'advanced_users',
      {
        'name': entity.name,
        'phone_number': entity.phoneNumber,
        'address': entity.address,
        'country': entity.country,
        'zip_code': entity.zipCode,
        'age': entity.age,
        'city': entity.city,
        'login_duration': entity.loginDuration?.inMilliseconds,
        'profile_url': entity.profileUrl?.toString(),
        'score': entity.score,
        'status': entity.status.index,
        'priority': entity.priority?.name,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'is_verified': entity.isVerified ? 1 : 0,
      },
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a AdvancedUser by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete(
      'advanced_users',
      where: '"id" = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('advanced_users');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "advanced_users"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  AdvancedUserQueryBuilder queryBuilder() {
    return AdvancedUserQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as AdvancedUser objects.
  Future<List<AdvancedUser>> query(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_AdvancedUserFromMap).toList();
  }
}
