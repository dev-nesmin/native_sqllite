// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'user.dart';

// Table schema for User
abstract class UserSchema {
  static const String tableName = 'users';

  static const String createTableSql = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone_number TEXT,
      address TEXT,
      age INTEGER NOT NULL DEFAULT 1,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER
    )
  ''';

  static const List<String> indexSql = [
    '''CREATE INDEX idx_users_email ON users (email)''',
    '''CREATE INDEX idx_users_created_at ON users (created_at)''',
  ];

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email';
  static const String PHONE_NUMBER = 'phone_number';
  static const String ADDRESS = 'address';
  static const String AGE = 'age';
  static const String IS_ACTIVE = 'is_active';
  static const String CREATED_AT = 'created_at';
  static const String UPDATED_AT = 'updated_at';
}

// Query builder for User
class UserQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  UserQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  UserQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  UserQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  UserQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  UserQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where email equals [value].
  UserQueryBuilder emailEqualTo(String value) {
    _whereConditions.add('email = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where email contains [value].
  UserQueryBuilder emailContains(String value) {
    _whereConditions.add('email LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where email starts with [value].
  UserQueryBuilder emailStartsWith(String value) {
    _whereConditions.add('email LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where email ends with [value].
  UserQueryBuilder emailEndsWith(String value) {
    _whereConditions.add('email LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where phoneNumber equals [value].
  UserQueryBuilder phoneNumberEqualTo(String? value) {
    _whereConditions.add('phone_number = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where phoneNumber contains [value].
  UserQueryBuilder phoneNumberContains(String value) {
    _whereConditions.add('phone_number LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where phoneNumber starts with [value].
  UserQueryBuilder phoneNumberStartsWith(String value) {
    _whereConditions.add('phone_number LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where phoneNumber ends with [value].
  UserQueryBuilder phoneNumberEndsWith(String value) {
    _whereConditions.add('phone_number LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where phoneNumber is null.
  UserQueryBuilder phoneNumberIsNull() {
    _whereConditions.add('phone_number IS NULL');
    return this;
  }

  /// Filter where phoneNumber is not null.
  UserQueryBuilder phoneNumberIsNotNull() {
    _whereConditions.add('phone_number IS NOT NULL');
    return this;
  }

  /// Filter where address equals [value].
  UserQueryBuilder addressEqualTo(String? value) {
    _whereConditions.add('address = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where address contains [value].
  UserQueryBuilder addressContains(String value) {
    _whereConditions.add('address LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where address starts with [value].
  UserQueryBuilder addressStartsWith(String value) {
    _whereConditions.add('address LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where address ends with [value].
  UserQueryBuilder addressEndsWith(String value) {
    _whereConditions.add('address LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where address is null.
  UserQueryBuilder addressIsNull() {
    _whereConditions.add('address IS NULL');
    return this;
  }

  /// Filter where address is not null.
  UserQueryBuilder addressIsNotNull() {
    _whereConditions.add('address IS NOT NULL');
    return this;
  }

  /// Filter where age equals [value].
  UserQueryBuilder ageEqualTo(int value) {
    _whereConditions.add('age = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where age is greater than [value].
  UserQueryBuilder ageGreaterThan(int value) {
    _whereConditions.add('age > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where age is less than [value].
  UserQueryBuilder ageLessThan(int value) {
    _whereConditions.add('age < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where age is between [min] and [max].
  UserQueryBuilder ageBetween(int min, int max) {
    _whereConditions.add('age BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where isActive is true.
  UserQueryBuilder isActiveIsTrue() {
    _whereConditions.add('is_active = ?');
    _whereArgs.add(1);
    return this;
  }

  /// Filter where isActive is false.
  UserQueryBuilder isActiveIsFalse() {
    _whereConditions.add('is_active = ?');
    _whereArgs.add(0);
    return this;
  }

  /// Filter where createdAt equals [value].
  UserQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  UserQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  UserQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  UserQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt equals [value].
  UserQueryBuilder updatedAtEqualTo(DateTime? value) {
    _whereConditions.add('updated_at = ?');
    _whereArgs.add(value?.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is after [value].
  UserQueryBuilder updatedAtAfter(DateTime value) {
    _whereConditions.add('updated_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is before [value].
  UserQueryBuilder updatedAtBefore(DateTime value) {
    _whereConditions.add('updated_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is between [start] and [end].
  UserQueryBuilder updatedAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('updated_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where updatedAt is null.
  UserQueryBuilder updatedAtIsNull() {
    _whereConditions.add('updated_at IS NULL');
    return this;
  }

  /// Filter where updatedAt is not null.
  UserQueryBuilder updatedAtIsNotNull() {
    _whereConditions.add('updated_at IS NOT NULL');
    return this;
  }

  /// Sort by id in ascending order.
  UserQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  UserQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  UserQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  UserQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by email in ascending order.
  UserQueryBuilder sortByEmailAsc() {
    _orderBy = 'email ASC';
    return this;
  }

  /// Sort by email in descending order.
  UserQueryBuilder sortByEmailDesc() {
    _orderBy = 'email DESC';
    return this;
  }

  /// Sort by phoneNumber in ascending order.
  UserQueryBuilder sortByPhoneNumberAsc() {
    _orderBy = 'phone_number ASC';
    return this;
  }

  /// Sort by phoneNumber in descending order.
  UserQueryBuilder sortByPhoneNumberDesc() {
    _orderBy = 'phone_number DESC';
    return this;
  }

  /// Sort by address in ascending order.
  UserQueryBuilder sortByAddressAsc() {
    _orderBy = 'address ASC';
    return this;
  }

  /// Sort by address in descending order.
  UserQueryBuilder sortByAddressDesc() {
    _orderBy = 'address DESC';
    return this;
  }

  /// Sort by age in ascending order.
  UserQueryBuilder sortByAgeAsc() {
    _orderBy = 'age ASC';
    return this;
  }

  /// Sort by age in descending order.
  UserQueryBuilder sortByAgeDesc() {
    _orderBy = 'age DESC';
    return this;
  }

  /// Sort by isActive in ascending order.
  UserQueryBuilder sortByIsActiveAsc() {
    _orderBy = 'is_active ASC';
    return this;
  }

  /// Sort by isActive in descending order.
  UserQueryBuilder sortByIsActiveDesc() {
    _orderBy = 'is_active DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  UserQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  UserQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Sort by updatedAt in ascending order.
  UserQueryBuilder sortByUpdatedAtAsc() {
    _orderBy = 'updated_at ASC';
    return this;
  }

  /// Sort by updatedAt in descending order.
  UserQueryBuilder sortByUpdatedAtDesc() {
    _orderBy = 'updated_at DESC';
    return this;
  }

  /// Limit the number of results.
  UserQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  UserQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<User>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<User?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM users$whereClause';
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
      'users',
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
    return 'SELECT * FROM users$whereClause$orderClause$limitClause$offsetClause';
  }

  User _fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      address: map['address'] as String?,
      age: map['age'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }
}

// Repository for User
class UserRepository {
  final String databaseName;

  const UserRepository([this.databaseName = 'example_app']);

  /// Inserts a new User into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(User entity) async {
    return NativeSqlite.insert(databaseName, 'users', {
      'name': entity.name,
      'email': entity.email,
      'phone_number': entity.phoneNumber,
      'address': entity.address,
      'age': entity.age,
      'is_active': entity.isActive ? 1 : 0,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
    });
  }

  /// Finds a User by its ID.
  /// Returns null if not found.
  Future<User?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM users WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all Users in the database.
  Future<List<User>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM users',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing User in the database.
  /// Returns the number of rows affected.
  Future<int> update(User entity) async {
    return NativeSqlite.update(
      databaseName,
      'users',
      {
        'name': entity.name,
        'email': entity.email,
        'phone_number': entity.phoneNumber,
        'address': entity.address,
        'age': entity.age,
        'is_active': entity.isActive ? 1 : 0,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'updated_at': entity.updatedAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a User by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'users');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM users',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  UserQueryBuilder queryBuilder() {
    return UserQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as User objects.
  Future<List<User>> query(String sql, [List<Object?>? arguments]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a User object.
  User _fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      address: map['address'] as String?,
      age: map['age'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }
}
