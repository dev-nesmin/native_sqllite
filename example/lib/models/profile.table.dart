// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, prefer_single_quotes, lines_longer_than_80_chars, depend_on_referenced_packages, unused_element, unused_import

// **************************************************************************
// TableGenerator
// **************************************************************************

part of 'profile.dart';

/// Generated table schema for [Profile].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
abstract class ProfileSchema {
  static const String tableName = 'profiles';

  static const String createTableSql =
      'CREATE TABLE "profiles" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "email" TEXT NOT NULL, "phone_number" TEXT, "settings" TEXT, "tags" TEXT, "address" TEXT, "addresses" TEXT, "metadata" TEXT NOT NULL)';

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

Profile _ProfileFromMap(Map<String, Object?> map) {
  return Profile(
    id: map['id'] as int?,
    name: map['name'] as String,
    email: map['email'] as String,
    phoneNumber: map['phone_number'] as String?,
    settings: map['settings'] != null
        ? NativeSqliteCodec.jsonDecode(map['settings'] as String)
              as Map<String, dynamic>
        : null,
    tags: map['tags'] != null
        ? (NativeSqliteCodec.jsonDecode(map['tags'] as String) as List)
              .cast<String>()
        : null,
    address: map['address'] != null
        ? Address.fromJson(
            NativeSqliteCodec.jsonDecode(map['address'] as String)
                as Map<String, dynamic>,
          )
        : null,
    addresses: map['addresses'] != null
        ? (NativeSqliteCodec.jsonDecode(map['addresses'] as String) as List)
              .map((e) => Address.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
    metadata: NativeSqliteCodec.jsonDecode(map['metadata'] as String),
  );
}

/// Generated query builder for [Profile].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class ProfileQueryBuilder {
  final NativeSqliteDatabase _database;
  final List<String> _whereConditions = [];
  final List<Object?> _whereArgs = [];
  final List<String> _orderBy = [];
  int? _limit;
  int? _offset;

  ProfileQueryBuilder(this._database);

  /// Filter where id equals [value].
  ProfileQueryBuilder idEqualTo(int? value) {
    if (value == null) {
      _whereConditions.add('"id" IS NULL');
    } else {
      _whereConditions.add('"id" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where id is greater than [value].
  ProfileQueryBuilder idGreaterThan(int value) {
    _whereConditions.add('"id" > ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is less than [value].
  ProfileQueryBuilder idLessThan(int value) {
    _whereConditions.add('"id" < ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where id is between [min] and [max].
  ProfileQueryBuilder idBetween(int min, int max) {
    _whereConditions.add('"id" BETWEEN ? AND ?');
    _whereArgs.add(min);
    _whereArgs.add(max);
    return this;
  }

  /// Filter where id is null.
  ProfileQueryBuilder idIsNull() {
    _whereConditions.add('"id" IS NULL');
    return this;
  }

  /// Filter where id is not null.
  ProfileQueryBuilder idIsNotNull() {
    _whereConditions.add('"id" IS NOT NULL');
    return this;
  }

  /// Filter where name equals [value].
  ProfileQueryBuilder nameEqualTo(String value) {
    _whereConditions.add('"name" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where name contains [value].
  ProfileQueryBuilder nameContains(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name starts with [value].
  ProfileQueryBuilder nameStartsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where name ends with [value].
  ProfileQueryBuilder nameEndsWith(String value) {
    _whereConditions.add('"name" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where email equals [value].
  ProfileQueryBuilder emailEqualTo(String value) {
    _whereConditions.add('"email" = ?');
    _whereArgs.add(value);
    return this;
  }

  /// Filter where email contains [value].
  ProfileQueryBuilder emailContains(String value) {
    _whereConditions.add('"email" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where email starts with [value].
  ProfileQueryBuilder emailStartsWith(String value) {
    _whereConditions.add('"email" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where email ends with [value].
  ProfileQueryBuilder emailEndsWith(String value) {
    _whereConditions.add('"email" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where phoneNumber equals [value].
  ProfileQueryBuilder phoneNumberEqualTo(String? value) {
    if (value == null) {
      _whereConditions.add('"phone_number" IS NULL');
    } else {
      _whereConditions.add('"phone_number" = ?');
      _whereArgs.add(value);
    }
    return this;
  }

  /// Filter where phoneNumber contains [value].
  ProfileQueryBuilder phoneNumberContains(String value) {
    _whereConditions.add('"phone_number" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}%');
    return this;
  }

  /// Filter where phoneNumber starts with [value].
  ProfileQueryBuilder phoneNumberStartsWith(String value) {
    _whereConditions.add('"phone_number" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('${_escapeLike(value)}%');
    return this;
  }

  /// Filter where phoneNumber ends with [value].
  ProfileQueryBuilder phoneNumberEndsWith(String value) {
    _whereConditions.add('"phone_number" LIKE ? ESCAPE \'\\\'');
    _whereArgs.add('%${_escapeLike(value)}');
    return this;
  }

  /// Filter where phoneNumber is null.
  ProfileQueryBuilder phoneNumberIsNull() {
    _whereConditions.add('"phone_number" IS NULL');
    return this;
  }

  /// Filter where phoneNumber is not null.
  ProfileQueryBuilder phoneNumberIsNotNull() {
    _whereConditions.add('"phone_number" IS NOT NULL');
    return this;
  }

  /// Filter where settings is null.
  ProfileQueryBuilder settingsIsNull() {
    _whereConditions.add('"settings" IS NULL');
    return this;
  }

  /// Filter where settings is not null.
  ProfileQueryBuilder settingsIsNotNull() {
    _whereConditions.add('"settings" IS NOT NULL');
    return this;
  }

  /// Filter where tags is null.
  ProfileQueryBuilder tagsIsNull() {
    _whereConditions.add('"tags" IS NULL');
    return this;
  }

  /// Filter where tags is not null.
  ProfileQueryBuilder tagsIsNotNull() {
    _whereConditions.add('"tags" IS NOT NULL');
    return this;
  }

  /// Filter where address is null.
  ProfileQueryBuilder addressIsNull() {
    _whereConditions.add('"address" IS NULL');
    return this;
  }

  /// Filter where address is not null.
  ProfileQueryBuilder addressIsNotNull() {
    _whereConditions.add('"address" IS NOT NULL');
    return this;
  }

  /// Filter where addresses is null.
  ProfileQueryBuilder addressesIsNull() {
    _whereConditions.add('"addresses" IS NULL');
    return this;
  }

  /// Filter where addresses is not null.
  ProfileQueryBuilder addressesIsNotNull() {
    _whereConditions.add('"addresses" IS NOT NULL');
    return this;
  }

  /// Sort by id in ascending order.
  ProfileQueryBuilder sortByIdAsc() {
    _orderBy
      ..clear()
      ..add('"id" ASC');
    return this;
  }

  /// Sort by id in descending order.
  ProfileQueryBuilder sortByIdDesc() {
    _orderBy
      ..clear()
      ..add('"id" DESC');
    return this;
  }

  /// Then sort by id in ascending order.
  ProfileQueryBuilder thenByIdAsc() {
    _orderBy.add('"id" ASC');
    return this;
  }

  /// Then sort by id in descending order.
  ProfileQueryBuilder thenByIdDesc() {
    _orderBy.add('"id" DESC');
    return this;
  }

  /// Sort by name in ascending order.
  ProfileQueryBuilder sortByNameAsc() {
    _orderBy
      ..clear()
      ..add('"name" ASC');
    return this;
  }

  /// Sort by name in descending order.
  ProfileQueryBuilder sortByNameDesc() {
    _orderBy
      ..clear()
      ..add('"name" DESC');
    return this;
  }

  /// Then sort by name in ascending order.
  ProfileQueryBuilder thenByNameAsc() {
    _orderBy.add('"name" ASC');
    return this;
  }

  /// Then sort by name in descending order.
  ProfileQueryBuilder thenByNameDesc() {
    _orderBy.add('"name" DESC');
    return this;
  }

  /// Sort by email in ascending order.
  ProfileQueryBuilder sortByEmailAsc() {
    _orderBy
      ..clear()
      ..add('"email" ASC');
    return this;
  }

  /// Sort by email in descending order.
  ProfileQueryBuilder sortByEmailDesc() {
    _orderBy
      ..clear()
      ..add('"email" DESC');
    return this;
  }

  /// Then sort by email in ascending order.
  ProfileQueryBuilder thenByEmailAsc() {
    _orderBy.add('"email" ASC');
    return this;
  }

  /// Then sort by email in descending order.
  ProfileQueryBuilder thenByEmailDesc() {
    _orderBy.add('"email" DESC');
    return this;
  }

  /// Sort by phoneNumber in ascending order.
  ProfileQueryBuilder sortByPhoneNumberAsc() {
    _orderBy
      ..clear()
      ..add('"phone_number" ASC');
    return this;
  }

  /// Sort by phoneNumber in descending order.
  ProfileQueryBuilder sortByPhoneNumberDesc() {
    _orderBy
      ..clear()
      ..add('"phone_number" DESC');
    return this;
  }

  /// Then sort by phoneNumber in ascending order.
  ProfileQueryBuilder thenByPhoneNumberAsc() {
    _orderBy.add('"phone_number" ASC');
    return this;
  }

  /// Then sort by phoneNumber in descending order.
  ProfileQueryBuilder thenByPhoneNumberDesc() {
    _orderBy.add('"phone_number" DESC');
    return this;
  }

  /// Sort by settings in ascending order.
  ProfileQueryBuilder sortBySettingsAsc() {
    _orderBy
      ..clear()
      ..add('"settings" ASC');
    return this;
  }

  /// Sort by settings in descending order.
  ProfileQueryBuilder sortBySettingsDesc() {
    _orderBy
      ..clear()
      ..add('"settings" DESC');
    return this;
  }

  /// Then sort by settings in ascending order.
  ProfileQueryBuilder thenBySettingsAsc() {
    _orderBy.add('"settings" ASC');
    return this;
  }

  /// Then sort by settings in descending order.
  ProfileQueryBuilder thenBySettingsDesc() {
    _orderBy.add('"settings" DESC');
    return this;
  }

  /// Sort by tags in ascending order.
  ProfileQueryBuilder sortByTagsAsc() {
    _orderBy
      ..clear()
      ..add('"tags" ASC');
    return this;
  }

  /// Sort by tags in descending order.
  ProfileQueryBuilder sortByTagsDesc() {
    _orderBy
      ..clear()
      ..add('"tags" DESC');
    return this;
  }

  /// Then sort by tags in ascending order.
  ProfileQueryBuilder thenByTagsAsc() {
    _orderBy.add('"tags" ASC');
    return this;
  }

  /// Then sort by tags in descending order.
  ProfileQueryBuilder thenByTagsDesc() {
    _orderBy.add('"tags" DESC');
    return this;
  }

  /// Sort by address in ascending order.
  ProfileQueryBuilder sortByAddressAsc() {
    _orderBy
      ..clear()
      ..add('"address" ASC');
    return this;
  }

  /// Sort by address in descending order.
  ProfileQueryBuilder sortByAddressDesc() {
    _orderBy
      ..clear()
      ..add('"address" DESC');
    return this;
  }

  /// Then sort by address in ascending order.
  ProfileQueryBuilder thenByAddressAsc() {
    _orderBy.add('"address" ASC');
    return this;
  }

  /// Then sort by address in descending order.
  ProfileQueryBuilder thenByAddressDesc() {
    _orderBy.add('"address" DESC');
    return this;
  }

  /// Sort by addresses in ascending order.
  ProfileQueryBuilder sortByAddressesAsc() {
    _orderBy
      ..clear()
      ..add('"addresses" ASC');
    return this;
  }

  /// Sort by addresses in descending order.
  ProfileQueryBuilder sortByAddressesDesc() {
    _orderBy
      ..clear()
      ..add('"addresses" DESC');
    return this;
  }

  /// Then sort by addresses in ascending order.
  ProfileQueryBuilder thenByAddressesAsc() {
    _orderBy.add('"addresses" ASC');
    return this;
  }

  /// Then sort by addresses in descending order.
  ProfileQueryBuilder thenByAddressesDesc() {
    _orderBy.add('"addresses" DESC');
    return this;
  }

  /// Sort by metadata in ascending order.
  ProfileQueryBuilder sortByMetadataAsc() {
    _orderBy
      ..clear()
      ..add('"metadata" ASC');
    return this;
  }

  /// Sort by metadata in descending order.
  ProfileQueryBuilder sortByMetadataDesc() {
    _orderBy
      ..clear()
      ..add('"metadata" DESC');
    return this;
  }

  /// Then sort by metadata in ascending order.
  ProfileQueryBuilder thenByMetadataAsc() {
    _orderBy.add('"metadata" ASC');
    return this;
  }

  /// Then sort by metadata in descending order.
  ProfileQueryBuilder thenByMetadataDesc() {
    _orderBy.add('"metadata" DESC');
    return this;
  }

  /// Limit the number of results.
  ProfileQueryBuilder limit(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _limit = value;
    return this;
  }

  /// Skip [value] results.
  ProfileQueryBuilder offset(int value) {
    if (value < 0)
      throw ArgumentError.value(value, 'value', 'must not be negative');
    _offset = value;
    return this;
  }

  /// Execute the query and return all matching records.
  Future<List<Profile>> findAll() async {
    final sql = toSql();
    final result = await _database.query(sql, _whereArgs);
    return result.toMapList().map(_ProfileFromMap).toList();
  }

  /// Execute the query and return the first matching record.
  Future<Profile?> findFirst() async {
    final result = await _database.query(
      _buildQuery(limitOverride: 1),
      _whereArgs,
    );
    final rows = result.toMapList();
    return rows.isEmpty ? null : _ProfileFromMap(rows.first);
  }

  /// Count the number of matching records.
  Future<int> count() async {
    final whereClause = _whereConditions.isEmpty
        ? ''
        : ' WHERE ${_whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM "profiles"$whereClause';
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
      'profiles',
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
    return 'SELECT * FROM "profiles"$whereClause$orderClause$limitClause$offsetClause';
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Generated repository for [Profile].
///
/// Regenerate with `flutter pub run build_runner build` after changing the model.
class ProfileRepository {
  final NativeSqliteDatabase database;

  const ProfileRepository(this.database);

  /// Inserts a new Profile into the database.
  /// Returns the ID of the inserted row.
  Future<int?> insert(Profile entity) async {
    final rowId = await database.insert('profiles', {
      'name': entity.name,
      'email': entity.email,
      'phone_number': entity.phoneNumber,
      'settings': entity.settings != null
          ? NativeSqliteCodec.jsonEncode(entity.settings)
          : null,
      'tags': entity.tags != null
          ? NativeSqliteCodec.jsonEncode(entity.tags)
          : null,
      'address': entity.address != null
          ? NativeSqliteCodec.jsonEncode(entity.address!.toJson())
          : null,
      'addresses': entity.addresses != null
          ? NativeSqliteCodec.jsonEncode(
              entity.addresses!.map((e) => e.toJson()).toList(),
            )
          : null,
      'metadata': NativeSqliteCodec.jsonEncode(entity.metadata),
    });
    return rowId;
  }

  /// Finds a Profile by its ID.
  /// Returns null if not found.
  Future<Profile?> findById(int? id) async {
    final result = await database.query(
      'SELECT * FROM "profiles" WHERE "id" = ? LIMIT 1',
      [id],
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return null;

    return _ProfileFromMap(rows.first);
  }

  /// Finds all Profiles in the database.
  Future<List<Profile>> findAll() async {
    final result = await database.query('SELECT * FROM "profiles"');

    return result.toMapList().map(_ProfileFromMap).toList();
  }

  /// Updates an existing Profile in the database.
  /// Returns the number of rows affected.
  Future<int> update(Profile entity) async {
    return database.update(
      'profiles',
      {
        'name': entity.name,
        'email': entity.email,
        'phone_number': entity.phoneNumber,
        'settings': entity.settings != null
            ? NativeSqliteCodec.jsonEncode(entity.settings)
            : null,
        'tags': entity.tags != null
            ? NativeSqliteCodec.jsonEncode(entity.tags)
            : null,
        'address': entity.address != null
            ? NativeSqliteCodec.jsonEncode(entity.address!.toJson())
            : null,
        'addresses': entity.addresses != null
            ? NativeSqliteCodec.jsonEncode(
                entity.addresses!.map((e) => e.toJson()).toList(),
              )
            : null,
        'metadata': NativeSqliteCodec.jsonEncode(entity.metadata),
      },
      where: '"id" = ?',
      whereArgs: [entity.id],
    );
  }

  /// Deletes a Profile by its ID.
  /// Returns the number of rows deleted.
  Future<int> delete(int? id) async {
    return database.delete('profiles', where: '"id" = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table.
  /// Returns the number of rows deleted.
  Future<int> deleteAll() async {
    return database.delete('profiles');
  }

  /// Returns the total count of records in the table.
  Future<int> count() async {
    final result = await database.query(
      'SELECT COUNT(*) as count FROM "profiles"',
    );

    final rows = result.toMapList();
    if (rows.isEmpty) return 0;

    return rows.first['count'] as int;
  }

  /// Creates a new query builder for type-safe queries.
  ProfileQueryBuilder queryBuilder() {
    return ProfileQueryBuilder(database);
  }

  /// Executes a custom query and returns the results as Profile objects.
  Future<List<Profile>> query(String sql, [List<Object?>? arguments]) async {
    final result = await database.query(sql, arguments);
    return result.toMapList().map(_ProfileFromMap).toList();
  }
}
