import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/models/category.dart';
import 'package:native_sqlite_example/models/order.dart';
import 'package:native_sqlite_example/models/product.dart';
import 'package:native_sqlite_example/models/user.dart';

void main() {
  const databaseName = 'query_builder_playground_test';
  final january = DateTime.utc(2024, 1, 15);
  final june = DateTime.utc(2024, 6, 1);
  final nextYear = DateTime.utc(2025, 1, 1);
  final previousYear = DateTime.utc(2023, 12, 1);

  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;

  setUpAll(() {
    backend = NativeSqliteTesting.useFfi();
  });

  setUp(() async {
    await NativeSqlite.deleteDatabase(databaseName);
    database = await NativeSqlite.open(
      DatabaseConfig(
        name: databaseName,
        onCreate: [
          CategorySchema.createTableSql,
          UserSchema.createTableSql,
          ProductSchema.createTableSql,
          OrderSchema.createTableSql,
        ],
      ),
    );

    final users = UserRepository(database);
    await users.insert(
      User(
        name: 'Alice',
        email: 'alice@example.com',
        age: 20,
        isActive: true,
        createdAt: january,
      ),
    );
    await users.insert(
      User(
        name: 'Albert',
        email: 'albert@example.net',
        phoneNumber: '111',
        address: 'Ankara',
        age: 30,
        isActive: false,
        createdAt: june,
        updatedAt: june.add(const Duration(days: 1)),
      ),
    );
    await users.insert(
      User(
        name: 'Bianca',
        email: 'bianca@example.com',
        phoneNumber: '222',
        address: 'Izmir',
        age: 30,
        isActive: true,
        createdAt: nextYear,
        updatedAt: nextYear,
      ),
    );
    await users.insert(
      User(
        name: 'Carla',
        email: 'carla@example.org',
        age: 40,
        isActive: false,
        createdAt: previousYear,
        updatedAt: january,
      ),
    );

    final categoryId = await CategoryRepository(
      database,
    ).insert(Category(name: 'Query samples'));
    final productId = await ProductRepository(
      database,
    ).insert(Product(name: 'Sample', price: 1, categoryId: categoryId!));
    await OrderRepository(database).insert(
      Order(
        userId: 1,
        productId: productId!,
        quantity: 1,
        totalPrice: 1,
        status: OrderStatus.processing,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(databaseName);
  });

  tearDownAll(() {
    backend.dispose();
  });

  Future<void> expectUsers(
    UserQueryBuilder query, {
    required String sql,
    required List<Object?> arguments,
    required List<String> names,
  }) async {
    expect(query.toSql(), contains(sql));
    expect(query.arguments, arguments);
    expect(
      (await query.sortByIdAsc().findAll()).map((user) => user.name),
      names,
    );
  }

  test('equality, comparison, and between operators bind and filter', () async {
    await expectUsers(
      UserQueryBuilder(database).nameEqualTo('Alice'),
      sql: '"name" = ?',
      arguments: ['Alice'],
      names: ['Alice'],
    );
    await expectUsers(
      UserQueryBuilder(database).ageGreaterThan(25),
      sql: '"age" > ?',
      arguments: [25],
      names: ['Albert', 'Bianca', 'Carla'],
    );
    await expectUsers(
      UserQueryBuilder(database).ageLessThan(30),
      sql: '"age" < ?',
      arguments: [30],
      names: ['Alice'],
    );
    await expectUsers(
      UserQueryBuilder(database).ageBetween(20, 30),
      sql: '"age" BETWEEN ? AND ?',
      arguments: [20, 30],
      names: ['Alice', 'Albert', 'Bianca'],
    );
  });

  test('string pattern operators bind and filter', () async {
    await expectUsers(
      UserQueryBuilder(database).nameContains('lic'),
      sql: '"name" LIKE ? ESCAPE',
      arguments: ['%lic%'],
      names: ['Alice'],
    );
    await expectUsers(
      UserQueryBuilder(database).nameStartsWith('Al'),
      sql: '"name" LIKE ? ESCAPE',
      arguments: ['Al%'],
      names: ['Alice', 'Albert'],
    );
    await expectUsers(
      UserQueryBuilder(database).nameEndsWith('a'),
      sql: '"name" LIKE ? ESCAPE',
      arguments: ['%a'],
      names: ['Bianca', 'Carla'],
    );
  });

  test('null and non-null operators do not bind values', () async {
    await expectUsers(
      UserQueryBuilder(database).phoneNumberIsNull(),
      sql: '"phone_number" IS NULL',
      arguments: const [],
      names: ['Alice', 'Carla'],
    );
    await expectUsers(
      UserQueryBuilder(database).phoneNumberIsNotNull(),
      sql: '"phone_number" IS NOT NULL',
      arguments: const [],
      names: ['Albert', 'Bianca'],
    );

    final nullableEquality = UserQueryBuilder(
      database,
    ).phoneNumberEqualTo(null);
    expect(nullableEquality.toSql(), contains('"phone_number" IS NULL'));
    expect(nullableEquality.arguments, isEmpty);
    expect(await nullableEquality.count(), 2);
  });

  test('boolean operators bind SQLite integer values', () async {
    await expectUsers(
      UserQueryBuilder(database).isActiveIsTrue(),
      sql: '"is_active" = ?',
      arguments: [1],
      names: ['Alice', 'Bianca'],
    );
    await expectUsers(
      UserQueryBuilder(database).isActiveIsFalse(),
      sql: '"is_active" = ?',
      arguments: [0],
      names: ['Albert', 'Carla'],
    );
  });

  test('DateTime operators bind epoch milliseconds and filter', () async {
    await expectUsers(
      UserQueryBuilder(database).createdAtEqualTo(january),
      sql: '"created_at" = ?',
      arguments: [january.millisecondsSinceEpoch],
      names: ['Alice'],
    );
    await expectUsers(
      UserQueryBuilder(database).createdAtAfter(january),
      sql: '"created_at" > ?',
      arguments: [january.millisecondsSinceEpoch],
      names: ['Albert', 'Bianca'],
    );
    await expectUsers(
      UserQueryBuilder(database).createdAtBefore(january),
      sql: '"created_at" < ?',
      arguments: [january.millisecondsSinceEpoch],
      names: ['Carla'],
    );
    await expectUsers(
      UserQueryBuilder(database).createdAtBetween(january, nextYear),
      sql: '"created_at" BETWEEN ? AND ?',
      arguments: [
        january.millisecondsSinceEpoch,
        nextYear.millisecondsSinceEpoch,
      ],
      names: ['Alice', 'Albert', 'Bianca'],
    );
  });

  test('enum equality uses its declared name storage', () async {
    final query = OrderQueryBuilder(
      database,
    ).statusEqualTo(OrderStatus.processing);
    expect(query.toSql(), contains('"status" = ?'));
    expect(query.arguments, [OrderStatus.processing.name]);
    expect((await query.findAll()).single.status, OrderStatus.processing);
  });

  test('chained sorting, limit, and offset affect SQL and results', () async {
    final query = UserQueryBuilder(
      database,
    ).sortByAgeAsc().thenByNameDesc().limit(2).offset(1);
    expect(
      query.toSql(),
      endsWith('ORDER BY "age" ASC, "name" DESC LIMIT 2 OFFSET 1'),
    );
    expect(query.arguments, isEmpty);
    expect((await query.findAll()).map((user) => user.name), [
      'Bianca',
      'Albert',
    ]);
  });

  test('findFirst, count, and deleteAll honor filters', () async {
    final first = UserQueryBuilder(database).isActiveIsFalse().sortByIdAsc();
    final sqlBefore = first.toSql();
    expect((await first.findFirst())?.name, 'Albert');
    expect(first.toSql(), sqlBefore, reason: 'findFirst must not mutate limit');

    expect(await UserQueryBuilder(database).ageEqualTo(30).count(), 2);

    final delete = UserQueryBuilder(database).nameStartsWith('Al');
    expect(delete.toSql(), contains('"name" LIKE ? ESCAPE'));
    expect(delete.arguments, ['Al%']);
    expect(await delete.deleteAll(), 2);
    expect(await UserRepository(database).count(), 2);
  });
}
