// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

// IMPORTANT: This file uses jsonEncode/jsonDecode.
// Add 'import "dart:convert";' to your profile.dart file.

part of 'profile.dart';

// Table schema for Profile
abstract class ProfileSchema {
  static const String tableName = 'profiles';

  static const String createTableSql = '''
    CREATE TABLE profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      phone_number TEXT,
      settings TEXT,
      tags TEXT,
      address TEXT,
      addresses TEXT,
      metadata TEXT NOT NULL
    )
  ''';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email';
  static const String PHONE_NUMBER = 'phone_number';
  static const String SETTINGS = 'settings';
  static const String TAGS = 'tags';
  static const String ADDRESS = 'address';
  static const String ADDRESSES = 'addresses';
  static const String METADATA = 'metadata';
}

// Query builder for Profile
class ProfileQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  ProfileQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  ProfileQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  ProfileQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  ProfileQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  ProfileQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where email equals [value].
  ProfileQueryBuilder emailEqualTo(String value) {
    _whereConditions.add('email = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where email contains [value].
  ProfileQueryBuilder emailContains(String value) {
    _whereConditions.add('email LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where email starts with [value].
  ProfileQueryBuilder emailStartsWith(String value) {
    _whereConditions.add('email LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where email ends with [value].
  ProfileQueryBuilder emailEndsWith(String value) {
    _whereConditions.add('email LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where phoneNumber equals [value].
  ProfileQueryBuilder phoneNumberEqualTo(String? value) {
    _whereConditions.add('phone_number = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where phoneNumber contains [value].
  ProfileQueryBuilder phoneNumberContains(String value) {
    _whereConditions.add('phone_number LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where phoneNumber starts with [value].
  ProfileQueryBuilder phoneNumberStartsWith(String value) {
    _whereConditions.add('phone_number LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where phoneNumber ends with [value].
  ProfileQueryBuilder phoneNumberEndsWith(String value) {
    _whereConditions.add('phone_number LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where phoneNumber is null.
  ProfileQueryBuilder phoneNumberIsNull() {
    _whereConditions.add('phone_number IS NULL');
    return this;
  }

  /// Filter where phoneNumber is not null.
  ProfileQueryBuilder phoneNumberIsNotNull() {
    _whereConditions.add('phone_number IS NOT NULL');
    return this;
  }

  /// Filter where settings is null.
  ProfileQueryBuilder settingsIsNull() {
    _whereConditions.add('settings IS NULL');
    return this;
  }

  /// Filter where settings is not null.
  ProfileQueryBuilder settingsIsNotNull() {
    _whereConditions.add('settings IS NOT NULL');
    return this;
  }

  /// Filter where tags is null.
  ProfileQueryBuilder tagsIsNull() {
    _whereConditions.add('tags IS NULL');
    return this;
  }

  /// Filter where tags is not null.
  ProfileQueryBuilder tagsIsNotNull() {
    _whereConditions.add('tags IS NOT NULL');
    return this;
  }

  /// Filter where address is null.
  ProfileQueryBuilder addressIsNull() {
    _whereConditions.add('address IS NULL');
    return this;
  }

  /// Filter where address is not null.
  ProfileQueryBuilder addressIsNotNull() {
    _whereConditions.add('address IS NOT NULL');
    return this;
  }

  /// Filter where addresses is null.
  ProfileQueryBuilder addressesIsNull() {
    _whereConditions.add('addresses IS NULL');
    return this;
  }

  /// Filter where addresses is not null.
  ProfileQueryBuilder addressesIsNotNull() {
    _whereConditions.add('addresses IS NOT NULL');
    return this;
  }

  /// Sort by id in ascending order.
  ProfileQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  ProfileQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  ProfileQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  ProfileQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by email in ascending order.
  ProfileQueryBuilder sortByEmailAsc() {
    _orderBy = 'email ASC';
    return this;
  }

  /// Sort by email in descending order.
  ProfileQueryBuilder sortByEmailDesc() {
    _orderBy = 'email DESC';
    return this;
  }

  /// Sort by phoneNumber in ascending order.
  ProfileQueryBuilder sortByPhoneNumberAsc() {
    _orderBy = 'phone_number ASC';
    return this;
  }

  /// Sort by phoneNumber in descending order.
  ProfileQueryBuilder sortByPhoneNumberDesc() {
    _orderBy = 'phone_number DESC';
    return this;
  }

  /// Sort by settings in ascending order.
  ProfileQueryBuilder sortBySettingsAsc() {
    _orderBy = 'settings ASC';
    return this;
  }

  /// Sort by settings in descending order.
  ProfileQueryBuilder sortBySettingsDesc() {
    _orderBy = 'settings DESC';
    return this;
  }

  /// Sort by tags in ascending order.
  ProfileQueryBuilder sortByTagsAsc() {
    _orderBy = 'tags ASC';
    return this;
  }

  /// Sort by tags in descending order.
  ProfileQueryBuilder sortByTagsDesc() {
    _orderBy = 'tags DESC';
    return this;
  }

  /// Sort by address in ascending order.
  ProfileQueryBuilder sortByAddressAsc() {
    _orderBy = 'address ASC';
    return this;
  }

  /// Sort by address in descending order.
  ProfileQueryBuilder sortByAddressDesc() {
    _orderBy = 'address DESC';
    return this;
  }

  /// Sort by addresses in ascending order.
  ProfileQueryBuilder sortByAddressesAsc() {
    _orderBy = 'addresses ASC';
    return this;
  }

  /// Sort by addresses in descending order.
  ProfileQueryBuilder sortByAddressesDesc() {
    _orderBy = 'addresses DESC';
    return this;
  }

  /// Sort by metadata in ascending order.
  ProfileQueryBuilder sortByMetadataAsc() {
    _orderBy = 'metadata ASC';
    return this;
  }

  /// Sort by metadata in descending order.
  ProfileQueryBuilder sortByMetadataDesc() {
    _orderBy = 'metadata DESC';
    return this;
  }

  /// Limit the number of results.
  ProfileQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  ProfileQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Profile>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Profile?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM profiles$whereClause';
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    final rows = result.toMapList();
    return rows.isEmpty ? 0 : rows.first['count'] as int;
  }

  /// Delete all matching records.
  Future<int> deleteAll() async {
    final whereClause = _whereConditions.isEmpty
        ? null
        : _whereConditions.join(' AND ');
    return NativeSqlite.delete(
      _databaseName,
      'profiles',
      where: whereClause,
      whereArgs: _whereArgs.isEmpty ? null : _whereArgs,
    );
  }

  String _buildQuery() {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final orderClause = _orderBy == null ? '' : ' ORDER BY $_orderBy';
    final limitClause = _limit == null ? '' : ' LIMIT $_limit';
    final offsetClause = _offset == null ? '' : ' OFFSET $_offset';
    return 'SELECT * FROM profiles$whereClause$orderClause$limitClause$offsetClause';
  }

  Profile _fromMap(Map<String, Object?> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      settings: map['settings'] != null
          ? jsonDecode(map['settings'] as String) as Map<String, dynamic>
          : null,
      tags: map['tags'] != null
          ? (jsonDecode(map['tags'] as String) as List).cast<String>()
          : null,
      address: map['address'] != null
          ? Address.fromJson(
              jsonDecode(map['address'] as String) as Map<String, dynamic>,
            )
          : null,
      addresses: map['addresses'] != null
          ? (jsonDecode(map['addresses'] as String) as List)
                .map((e) => Address.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      metadata: jsonDecode(map['metadata'] as String),
    );
  }
}

// Repository for Profile
class ProfileRepository {
  final String databaseName;

  const ProfileRepository([this.databaseName = 'example_app']);

  /// Inserts a new Profile into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(Profile entity) async {
    return NativeSqlite.insert(databaseName, 'profiles', {
      'name': entity.name,
      'email': entity.email,
      'phone_number': entity.phoneNumber,
      'settings': entity.settings != null ? jsonEncode(entity.settings) : null,
      'tags': entity.tags != null ? jsonEncode(entity.tags) : null,
      'address': entity.address != null
          ? jsonEncode(entity.address!.toJson())
          : null,
      'addresses': entity.addresses != null
          ? jsonEncode(entity.addresses!.map((e) => e.toJson()).toList())
          : null,
      'metadata': jsonEncode(entity.metadata),
    });
  }

  /// Finds a Profile by its ID.
  /// Returns null if not found.
  Future<Profile?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM profiles WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all Profiles in the database.
  Future<List<Profile>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM profiles',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing Profile in the database.
  /// Returns the number of rows affected.
  Future<int> update(Profile entity) async {
    return NativeSqlite.update(
      databaseName,
      'profiles',
      {
        'name': entity.name,
        'email': entity.email,
        'phone_number': entity.phoneNumber,
        'settings': entity.settings != null
            ? jsonEncode(entity.settings)
            : null,
        'tags': entity.tags != null ? jsonEncode(entity.tags) : null,
        'address': entity.address != null
            ? jsonEncode(entity.address!.toJson())
            : null,
        'addresses': entity.addresses != null
            ? jsonEncode(entity.addresses!.map((e) => e.toJson()).toList())
            : null,
        'metadata': jsonEncode(entity.metadata),
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Profile by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'profiles');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM profiles',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  ProfileQueryBuilder queryBuilder() {
    return ProfileQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as Profile objects.
  Future<List<Profile>> query(String sql, [List<Object?>? arguments]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a Profile object.
  Profile _fromMap(Map<String, Object?> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      settings: map['settings'] != null
          ? jsonDecode(map['settings'] as String) as Map<String, dynamic>
          : null,
      tags: map['tags'] != null
          ? (jsonDecode(map['tags'] as String) as List).cast<String>()
          : null,
      address: map['address'] != null
          ? Address.fromJson(
              jsonDecode(map['address'] as String) as Map<String, dynamic>,
            )
          : null,
      addresses: map['addresses'] != null
          ? (jsonDecode(map['addresses'] as String) as List)
                .map((e) => Address.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      metadata: jsonDecode(map['metadata'] as String),
    );
  }
}
