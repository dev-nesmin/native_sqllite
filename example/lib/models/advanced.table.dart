// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated on: 2025-10-30T19:25:30.955106

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'advanced.dart';

// Table schema for AdvancedUser
abstract class AdvancedUserSchema {
  static const String tableName = 'advanced_users';

  static const String createTableSql = '''
    CREATE TABLE advanced_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      login_duration INTEGER,
      profile_url TEXT,
      score REAL,
      status INTEGER NOT NULL,
      priority TEXT,
      created_at INTEGER NOT NULL,
      is_verified INTEGER NOT NULL
    )
  ''';

  // Column names
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String LOGIN_DURATION = 'login_duration';
  static const String PROFILE_URL = 'profile_url';
  static const String SCORE = 'score';
  static const String STATUS = 'status';
  static const String PRIORITY = 'priority';
  static const String CREATED_AT = 'created_at';
  static const String IS_VERIFIED = 'is_verified';
}

// Query builder for AdvancedUser
class AdvancedUserQueryBuilder {
  final String _databaseName;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  String? _orderBy;
  int? _limit;
  int? _offset;

  AdvancedUserQueryBuilder(this._databaseName);

  /// Filter where name equals [value].
  AdvancedUserQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('name = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  AdvancedUserQueryBuilder nameContains(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value%');
    return this;
  }

  /// Filter where name starts with [value].
  AdvancedUserQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('$value%');
    return this;
  }

  /// Filter where name ends with [value].
  AdvancedUserQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('name LIKE ?');
    _whereArgs.add('%$value');
    return this;
  }

  /// Filter where loginDuration equals [value].
  AdvancedUserQueryBuilder loginDurationEqualTo(Duration? value) {
    _whereConditions.add('login_duration = ?');
    _whereArgs.add(value?.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is greater than [value].
  AdvancedUserQueryBuilder loginDurationGreaterThan(Duration value) {
    _whereConditions.add('login_duration > ?');
    _whereArgs.add(value.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is less than [value].
  AdvancedUserQueryBuilder loginDurationLessThan(Duration value) {
    _whereConditions.add('login_duration < ?');
    _whereArgs.add(value.inMilliseconds);
    return this;
  }

  /// Filter where loginDuration is null.
  AdvancedUserQueryBuilder loginDurationIsNull() {
    _whereConditions.add('login_duration IS NULL');
    return this;
  }

  /// Filter where loginDuration is not null.
  AdvancedUserQueryBuilder loginDurationIsNotNull() {
    _whereConditions.add('login_duration IS NOT NULL');
    return this;
  }

  /// Filter where profileUrl is null.
  AdvancedUserQueryBuilder profileUrlIsNull() {
    _whereConditions.add('profile_url IS NULL');
    return this;
  }

  /// Filter where profileUrl is not null.
  AdvancedUserQueryBuilder profileUrlIsNotNull() {
    _whereConditions.add('profile_url IS NOT NULL');
    return this;
  }

  /// Filter where score equals [value].
  AdvancedUserQueryBuilder scoreEqualTo(num? value) {
    _whereConditions.add('score = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where score is greater than [value].
  AdvancedUserQueryBuilder scoreGreaterThan(num value) {
    _whereConditions.add('score > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where score is less than [value].
  AdvancedUserQueryBuilder scoreLessThan(num value) {
    _whereConditions.add('score < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where score is between [min] and [max].
  AdvancedUserQueryBuilder scoreBetween(num min, num max) {
    _whereConditions.add('score BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where score is null.
  AdvancedUserQueryBuilder scoreIsNull() {
    _whereConditions.add('score IS NULL');
    return this;
  }

  /// Filter where score is not null.
  AdvancedUserQueryBuilder scoreIsNotNull() {
    _whereConditions.add('score IS NOT NULL');
    return this;
  }

  /// Filter where status equals [value].
  AdvancedUserQueryBuilder statusEqualTo(UserStatus value) {
    _whereConditions.add('status = ?');
    _whereArgs.add(value.index);
    return this;
  }

  /// Filter where priority equals [value].
  AdvancedUserQueryBuilder priorityEqualTo(Priority? value) {
    _whereConditions.add('priority = ?');
    _whereArgs.add(value?.name);
    return this;
  }

  /// Filter where priority is null.
  AdvancedUserQueryBuilder priorityIsNull() {
    _whereConditions.add('priority IS NULL');
    return this;
  }

  /// Filter where priority is not null.
  AdvancedUserQueryBuilder priorityIsNotNull() {
    _whereConditions.add('priority IS NOT NULL');
    return this;
  }

  /// Filter where createdAt equals [value].
  AdvancedUserQueryBuilder createdAtEqualTo(DateTime value) {
    _whereConditions.add('created_at = ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is after [value].
  AdvancedUserQueryBuilder createdAtAfter(DateTime value) {
    _whereConditions.add('created_at > ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is before [value].
  AdvancedUserQueryBuilder createdAtBefore(DateTime value) {
    _whereConditions.add('created_at < ?');
    _whereArgs.add(value.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where createdAt is between [start] and [end].
  AdvancedUserQueryBuilder createdAtBetween(DateTime start, DateTime end) {
    _whereConditions.add('created_at BETWEEN ? AND ?');
    _whereArgs.add(start.millisecondsSinceEpoch);
    _whereArgs.add(end.millisecondsSinceEpoch);
    return this;
  }

  /// Filter where isVerified is true.
  AdvancedUserQueryBuilder isVerifiedIsTrue() {
    _whereConditions.add('is_verified = ?');
    _whereArgs.add(1);
    return this;
  }

  /// Filter where isVerified is false.
  AdvancedUserQueryBuilder isVerifiedIsFalse() {
    _whereConditions.add('is_verified = ?');
    _whereArgs.add(0);
    return this;
  }

  /// Sort by id in ascending order.
  AdvancedUserQueryBuilder sortByIdAsc() {
    _orderBy = 'id ASC';
    return this;
  }

  /// Sort by id in descending order.
  AdvancedUserQueryBuilder sortByIdDesc() {
    _orderBy = 'id DESC';
    return this;
  }

  /// Sort by name in ascending order.
  AdvancedUserQueryBuilder sortByNameAsc() {
    _orderBy = 'name ASC';
    return this;
  }

  /// Sort by name in descending order.
  AdvancedUserQueryBuilder sortByNameDesc() {
    _orderBy = 'name DESC';
    return this;
  }

  /// Sort by loginDuration in ascending order.
  AdvancedUserQueryBuilder sortByLoginDurationAsc() {
    _orderBy = 'login_duration ASC';
    return this;
  }

  /// Sort by loginDuration in descending order.
  AdvancedUserQueryBuilder sortByLoginDurationDesc() {
    _orderBy = 'login_duration DESC';
    return this;
  }

  /// Sort by profileUrl in ascending order.
  AdvancedUserQueryBuilder sortByProfileUrlAsc() {
    _orderBy = 'profile_url ASC';
    return this;
  }

  /// Sort by profileUrl in descending order.
  AdvancedUserQueryBuilder sortByProfileUrlDesc() {
    _orderBy = 'profile_url DESC';
    return this;
  }

  /// Sort by score in ascending order.
  AdvancedUserQueryBuilder sortByScoreAsc() {
    _orderBy = 'score ASC';
    return this;
  }

  /// Sort by score in descending order.
  AdvancedUserQueryBuilder sortByScoreDesc() {
    _orderBy = 'score DESC';
    return this;
  }

  /// Sort by status in ascending order.
  AdvancedUserQueryBuilder sortByStatusAsc() {
    _orderBy = 'status ASC';
    return this;
  }

  /// Sort by status in descending order.
  AdvancedUserQueryBuilder sortByStatusDesc() {
    _orderBy = 'status DESC';
    return this;
  }

  /// Sort by priority in ascending order.
  AdvancedUserQueryBuilder sortByPriorityAsc() {
    _orderBy = 'priority ASC';
    return this;
  }

  /// Sort by priority in descending order.
  AdvancedUserQueryBuilder sortByPriorityDesc() {
    _orderBy = 'priority DESC';
    return this;
  }

  /// Sort by createdAt in ascending order.
  AdvancedUserQueryBuilder sortByCreatedAtAsc() {
    _orderBy = 'created_at ASC';
    return this;
  }

  /// Sort by createdAt in descending order.
  AdvancedUserQueryBuilder sortByCreatedAtDesc() {
    _orderBy = 'created_at DESC';
    return this;
  }

  /// Sort by isVerified in ascending order.
  AdvancedUserQueryBuilder sortByIsVerifiedAsc() {
    _orderBy = 'is_verified ASC';
    return this;
  }

  /// Sort by isVerified in descending order.
  AdvancedUserQueryBuilder sortByIsVerifiedDesc() {
    _orderBy = 'is_verified DESC';
    return this;
  }

  /// Limit the number of results.
  AdvancedUserQueryBuilder limit(int value) {
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  AdvancedUserQueryBuilder offset(int value) {
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<AdvancedUser>> findAll() async {
    final sql = _buildQuery();
    final result = await NativeSqlite.query(_databaseName, sql, _whereArgs);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<AdvancedUser?> findFirst() async {
    _limit = 1;
    final results = await findAll();
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM advanced_users$whereClause';
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
      'advanced_users',
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
    return 'SELECT * FROM advanced_users$whereClause$orderClause$limitClause$offsetClause';
  }

  AdvancedUser _fromMap(Map<String, Object?> map) {
    return AdvancedUser(
      id: map['id'] as int?,
      name: map['name'] as String,
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
}

// Repository for AdvancedUser
class AdvancedUserRepository {
  final String databaseName;

  const AdvancedUserRepository([this.databaseName = 'example_app']);

  /// Inserts a new AdvancedUser into the database.
  /// Returns the ID of the inserted row.
  Future<int> insert(AdvancedUser entity) async {
    return NativeSqlite.insert(databaseName, 'advanced_users', {
      'name': entity.name,
      'login_duration': entity.loginDuration?.inMilliseconds,
      'profile_url': entity.profileUrl?.toString(),
      'score': entity.score,
      'status': entity.status.index,
      'priority': entity.priority?.name,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'is_verified': entity.isVerified ? 1 : 0,
    });
  }

  /// Finds a AdvancedUser by its ID.
  /// Returns null if not found.
  Future<AdvancedUser?> findById(int? id) async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM advanced_users WHERE id = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _fromMap(rows.first);
  }

  /// Finds all AdvancedUsers in the database.
  Future<List<AdvancedUser>> findAll() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT * FROM advanced_users',
    );

    return result.toMapList().map(_fromMap).toList();
  }

  /// Updates an existing AdvancedUser in the database.
  /// Returns the number of rows affected.
  Future<int> update(AdvancedUser entity) async {
    return NativeSqlite.update(
      databaseName,
      'advanced_users',
      {
        'name': entity.name,
        'login_duration': entity.loginDuration?.inMilliseconds,
        'profile_url': entity.profileUrl?.toString(),
        'score': entity.score,
        'status': entity.status.index,
        'priority': entity.priority?.name,
        'created_at': entity.createdAt.millisecondsSinceEpoch,
        'is_verified': entity.isVerified ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a AdvancedUser by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return NativeSqlite.delete(
      databaseName,
      'advanced_users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return NativeSqlite.delete(databaseName, 'advanced_users');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await NativeSqlite.query(
      databaseName,
      'SELECT COUNT(*) as count FROM advanced_users',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  AdvancedUserQueryBuilder queryBuilder() {
    return AdvancedUserQueryBuilder(databaseName);
  }

  /// Executes a custom query and returns the results as AdvancedUser objects.
  Future<List<AdvancedUser>> query(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final result = await NativeSqlite.query(databaseName, sql, arguments);
    return result.toMapList().map(_fromMap).toList();
  }

  /// Converts a map to a AdvancedUser object.
  AdvancedUser _fromMap(Map<String, Object?> map) {
    return AdvancedUser(
      id: map['id'] as int?,
      name: map['name'] as String,
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
}
