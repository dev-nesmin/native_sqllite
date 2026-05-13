// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2026-05-13T22:37:41.298272

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'freezed_advanced.dart';

// Table schema for FreezedAdvancedUser
abstract class FreezedAdvancedUserSchema {
  static const String tableName = 'freezed_advanced_users';

  static const String createTableSql = '''
    CREATE TABLE freezed_advanced_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      login_duration INTEGER,
      profile_url TEXT,
      status INTEGER NOT NULL,
      priority INTEGER,
      created_at INTEGER NOT NULL,
      is_verified INTEGER NOT NULL
    )
  ''';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String LOGIN_DURATION = 'login_duration';
  static const String PROFILE_URL = 'profile_url';
  static const String STATUS = 'status';
  static const String PRIORITY = 'priority';
  static const String CREATED_AT = 'created_at';
  static const String IS_VERIFIED = 'is_verified';
}

// Query builder for FreezedAdvancedUser
class FreezedAdvancedUserQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  FreezedAdvancedUserQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  FreezedAdvancedUserQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  FreezedAdvancedUserQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  FreezedAdvancedUserQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  FreezedAdvancedUserQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where loginDuration equals [value].
  FreezedAdvancedUserQueryBuilder loginDurationEqualTo(Duration? value) {
    _whereConditions.add('login_duration = ?');
    _whereArgs.add(value?.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is greater than [value].
  FreezedAdvancedUserQueryBuilder loginDurationGreaterThan(Duration value) {
    _whereConditions.add('login_duration > ?');
    _whereArgs.add(value.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is less than [value].
  FreezedAdvancedUserQueryBuilder loginDurationLessThan(Duration value) {
    _whereConditions.add('login_duration < ?');
    _whereArgs.add(value.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is null.
  FreezedAdvancedUserQueryBuilder loginDurationIsNull() {
    _whereConditions.add('login_duration IS NULL');
    return this;
  }

  /// Filter where loginDuration is not null.
  FreezedAdvancedUserQueryBuilder loginDurationIsNotNull() {
    _whereConditions.add('login_duration IS NOT NULL');
    return this;
  }

  /// Filter where profileUrl is null.
  FreezedAdvancedUserQueryBuilder profileUrlIsNull() {
    _whereConditions.add('profile_url IS NULL');
    return this;
  }

  /// Filter where profileUrl is not null.
  FreezedAdvancedUserQueryBuilder profileUrlIsNotNull() {
    _whereConditions.add('profile_url IS NOT NULL');
    return this;
  }

  /// Filter where status equals [value].
  FreezedAdvancedUserQueryBuilder statusEqualTo(UserStatus value) {
    _whereConditions.add('status = ?');
    _whereArgs.add(value.index);
    return this;
  }

  /// Filter where priority equals [value].
  FreezedAdvancedUserQueryBuilder priorityEqualTo(Priority? value) {
    _whereConditions.add('priority = ?');
    _whereArgs.add(value?.index);
    return this;
  }

  /// Filter where priority is null.
  FreezedAdvancedUserQueryBuilder priorityIsNull() {
    _whereConditions.add('priority IS NULL');
    return this;
  }

  /// Filter where priority is not null.
  FreezedAdvancedUserQueryBuilder priorityIsNotNull() {
    _whereConditions.add('priority IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  FreezedAdvancedUserQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  FreezedAdvancedUserQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  FreezedAdvancedUserQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  FreezedAdvancedUserQueryBuilder createdAtBetween(
    DateTime start,
    DateTime end,
  ) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where isVerified is true.
  FreezedAdvancedUserQueryBuilder isVerifiedIsTrue() {
    _whereConditions.add('is_verified = ?');
    _whereArgs.add(1);
    return this;
  }

  /// Filter where isVerified is false.
  FreezedAdvancedUserQueryBuilder isVerifiedIsFalse() {
    _whereConditions.add('is_verified = ?');
    _whereArgs.add(0);
    return this;
  }

  /// Sort by id in ascending order.
  FreezedAdvancedUserQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  FreezedAdvancedUserQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  FreezedAdvancedUserQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  FreezedAdvancedUserQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by loginDuration in ascending order.
  FreezedAdvancedUserQueryBuilder sortByLoginDurationAsc() {
    _orderBy = 'login_duration ASC';
    return this;
  }

  /// Sort by loginDuration in descending order.
  FreezedAdvancedUserQueryBuilder sortByLoginDurationDesc() {
    _orderBy = 'login_duration DESC';
    return this;
  }

  /// Sort by profileUrl in ascending order.
  FreezedAdvancedUserQueryBuilder sortByProfileUrlAsc() {
    _orderBy = 'profile_url ASC';
    return this;
  }

  /// Sort by profileUrl in descending order.
  FreezedAdvancedUserQueryBuilder sortByProfileUrlDesc() {
    _orderBy = 'profile_url DESC';
    return this;
  }

  /// Sort by status in ascending order.
  FreezedAdvancedUserQueryBuilder sortByStatusAsc() {
    _orderBy = 'status ASC';
    return this;
  }

  /// Sort by status in descending order.
  FreezedAdvancedUserQueryBuilder sortByStatusDesc() {
    _orderBy = 'status DESC';
    return this;
  }

  /// Sort by priority in ascending order.
  FreezedAdvancedUserQueryBuilder sortByPriorityAsc() {
    _orderBy = 'priority ASC';
    return this;
  }

  /// Sort by priority in descending order.
  FreezedAdvancedUserQueryBuilder sortByPriorityDesc() {
    _orderBy = 'priority DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  FreezedAdvancedUserQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  FreezedAdvancedUserQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Sort by isVerified in ascending order.
  FreezedAdvancedUserQueryBuilder sortByIsVerifiedAsc() {
    _orderBy = 'is_verified ASC';
    return this;
  }

  /// Sort by isVerified in descending order.
  FreezedAdvancedUserQueryBuilder sortByIsVerifiedDesc() {
    _orderBy = 'is_verified DESC';
    return this;
  }

  /// Limit the number of results.
  FreezedAdvancedUserQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  FreezedAdvancedUserQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<FreezedAdvancedUser>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<FreezedAdvancedUser?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql =
        'SELECT COUNT(*) as count FROM freezed_advanced_users$whereClause';
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
      'freezed_advanced_users',
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
    return 'SELECT * FROM freezed_advanced_users$whereClause$orderClause$limitClause$offsetClause';
  }

  FreezedAdvancedUser _fromMap(Map<String, Object?> map) {
    return FreezedAdvancedUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      loginDuration: map['login_duration'] != null
          ? Duration(milliseconds: map['login_duration'] as int)
          : null,
      profileUrl: map['profile_url'] != null
          ? Uri.parse(map['profile_url'] as String)
          : null,
      status: UserStatus.values[map['status'] as int],
      priority: map['priority'] != null
          ? Priority.values[map['priority'] as int]
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isVerified: (map['is_verified'] as int) == 1,
    );
  }
}

// Repository for FreezedAdvancedUser
class FreezedAdvancedUserRepository {
  final String databaseName;

  const FreezedAdvancedUserRepository([this.databaseName = 'example_app']);

  /// Inserts a new FreezedAdvancedUser into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(FreezedAdvancedUser entity) async {
    final id =
        await NativeSqlite.insert(databaseName, 'freezed_advanced_users', {
          'name': entity.name,
          'login_duration': entity.loginDuration?.inMilliseconds,
          'profile_url': entity.profileUrl?.toString(),
          'status': entity.status.index,
          'priority': entity.priority?.index,
          'created_at': entity.createdAt.millisecondsSinceEpoch,
          'is_verified': entity.isVerified ? 1 : 0,
        });
    return id;
  }

  /// Finds a FreezedAdvancedUser by its ID.
  /// Returns null if not found.
  Future<FreezedAdvancedUser?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM freezed_advanced_users WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all FreezedAdvancedUsers in the database.
  Future<List<FreezedAdvancedUser>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM freezed_advanced_users',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing FreezedAdvancedUser in the database.
  /// Returns the number of rows affected.
  Future<int> update(FreezedAdvancedUser entity) async {
    return NativeSqlite.update(
      databaseName,
      'freezed_advanced_users',
      {
        'name': entity.name,
        'login_duration': entity.loginDuration?.inMilliseconds,
        'profile_url': entity.profileUrl?.toString(),
        'status': entity.status.index,
        'priority': entity.priority?.index,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'is_verified': entity.isVerified ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a FreezedAdvancedUser by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'freezed_advanced_users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'freezed_advanced_users');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM freezed_advanced_users',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  FreezedAdvancedUserQueryBuilder queryBuilder() {
    return FreezedAdvancedUserQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as FreezedAdvancedUser objects.
  Future<List<FreezedAdvancedUser>> query(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a FreezedAdvancedUser object.
  FreezedAdvancedUser _fromMap(Map<String, Object?> map) {
    return FreezedAdvancedUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      loginDuration: map['login_duration'] != null
          ? Duration(milliseconds: map['login_duration'] as int)
          : null,
      profileUrl: map['profile_url'] != null
          ? Uri.parse(map['profile_url'] as String)
          : null,
      status: UserStatus.values[map['status'] as int],
      priority: map['priority'] != null
          ? Priority.values[map['priority'] as int]
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isVerified: (map['is_verified'] as int) == 1,
    );
  }
}
