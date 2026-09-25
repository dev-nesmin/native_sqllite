import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/models/advanced.dart';
import 'package:native_sqlite_example/models/category.dart';
import 'package:native_sqlite_example/models/custom_converter.dart';
import 'package:native_sqlite_example/models/demo_enums.dart';
import 'package:native_sqlite_example/models/note.dart';
import 'package:native_sqlite_example/models/order.dart';
import 'package:native_sqlite_example/models/product.dart';
import 'package:native_sqlite_example/models/profile.dart';
import 'package:native_sqlite_example/models/user.dart';

void main() {
  const databaseName = 'generated_converter_test';
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
          StyledItemSchema.createTableSql,
          ProfileSchema.createTableSql,
          CategorySchema.createTableSql,
          UserSchema.createTableSql,
          ProductSchema.createTableSql,
          OrderSchema.createTableSql,
          AdvancedUserSchema.createTableSql,
          NoteSchema.createTableSql,
          ...UserSchema.indexSql,
        ],
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

  test('round-trips inferred INTEGER and JSON converter storage', () async {
    final repository = StyledItemRepository(database);
    final id = await repository.insert(
      StyledItem(
        name: 'converted',
        backgroundColor: const Color(0xff123456),
        textColor: const Color(0xffabcdef),
        tags: const [' one ', 'two '],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234),
      ),
    );

    final item = await repository.findById(id);
    expect(item, isNotNull);
    expect(item!.backgroundColor, const Color(0xff123456));
    expect(item.textColor, const Color(0xffabcdef));
    expect(item.tags, [' one ', 'two ']);
  });

  test('query builder produces correct SQL without hidden state', () async {
    final repository = UserRepository(database);
    final firstId = await repository.insert(
      User(name: r'100%_match\end', email: 'one@example.com', age: 20),
    );
    final secondId = await repository.insert(
      User(name: 'Zulu', email: 'two@example.com', age: 10),
    );
    await repository.insert(
      User(name: 'Alpha', email: 'three@example.com', age: 10),
    );

    final literalLike = await UserQueryBuilder(
      database,
    ).nameContains('%_match\\').findAll();
    expect(literalLike.map((user) => user.id), [firstId]);

    final nullPhones = UserQueryBuilder(database).phoneNumberEqualTo(null);
    expect(nullPhones.toSql(), contains('"phone_number" IS NULL'));
    expect(nullPhones.arguments, isEmpty);
    expect(await nullPhones.count(), 3);

    final byPrimaryKey = await UserQueryBuilder(
      database,
    ).idEqualTo(secondId).findFirst();
    expect(byPrimaryKey?.name, 'Zulu');

    final sorted = UserQueryBuilder(database).sortByAgeAsc().thenByNameDesc();
    expect(sorted.toSql(), contains('ORDER BY "age" ASC, "name" DESC'));
    expect((await sorted.findAll()).map((user) => user.name), [
      'Zulu',
      'Alpha',
      r'100%_match\end',
    ]);

    final offset = UserQueryBuilder(database).sortByIdAsc().offset(1);
    expect(offset.debugSql, contains('LIMIT -1 OFFSET 1'));
    expect((await offset.findAll()).map((user) => user.id), [secondId, 3]);

    final first = UserQueryBuilder(database).sortByIdAsc();
    final sqlBefore = first.toSql();
    expect((await first.findFirst())?.id, firstId);
    expect(first.toSql(), sqlBefore);
    expect(first.toSql(), isNot(contains('LIMIT 1')));
  });

  test('round-trips JSON fields without a dart:convert model import', () async {
    final repository = ProfileRepository(database);
    final id = await repository.insert(
      const Profile(
        name: 'JSON',
        email: 'json@example.com',
        settings: {'dark': true, 'density': 2},
        tags: ['generated', 'codec'],
        address: Address(street: 'Main', city: 'Istanbul', zipCode: '34000'),
        metadata: {
          'values': [1, null, 'three'],
        },
      ),
    );

    final profile = await repository.findById(id);
    expect(profile?.settings, {'dark': true, 'density': 2});
    expect(profile?.tags, ['generated', 'codec']);
    expect(profile?.address?.city, 'Istanbul');
    expect(profile?.metadata, {
      'values': [1, null, 'three'],
    });
  });

  test('round-trips enums, DateTime, ignored fields, and UUID keys', () async {
    final instant = DateTime.utc(2025, 2, 3, 4, 5, 6, 789);
    final advancedRepository = AdvancedUserRepository(database);
    final advancedId = await advancedRepository.insert(
      AdvancedUser(
        name: 'generated-shapes',
        status: UserStatus.suspended,
        priority: Priority.urgent,
        createdAt: instant,
        isVerified: true,
      ),
    );

    final rawAdvanced = (await database.query(
      'SELECT status, priority, created_at FROM advanced_users WHERE id = ?',
      [advancedId],
    )).toMapList().single;
    expect(rawAdvanced['status'], UserStatus.suspended.index);
    expect(rawAdvanced['priority'], Priority.urgent.name);
    expect(rawAdvanced['created_at'], instant.millisecondsSinceEpoch);

    final advanced = await advancedRepository.findById(advancedId);
    expect(advanced?.status, UserStatus.suspended);
    expect(advanced?.priority, Priority.urgent);
    expect(
      advanced?.createdAt.millisecondsSinceEpoch,
      instant.millisecondsSinceEpoch,
    );

    final userRepository = UserRepository(database);
    final userId = await userRepository.insert(
      User(
        name: 'ignored-field',
        email: 'ignored@example.com',
        tempPassword: 'must-not-persist',
      ),
    );
    final columns = (await database.query(
      'PRAGMA table_info(${UserSchema.tableName})',
    )).toMapList();
    expect(
      columns.map((column) => column['name']),
      isNot(contains('temp_password')),
    );
    expect((await userRepository.findById(userId))?.tempPassword, isNull);

    final noteRepository = NoteRepository(database);
    final noteId = await noteRepository.insert(const Note(body: 'local UUID'));
    expect(
      noteId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect((await noteRepository.findById(noteId))?.body, 'local UUID');
  });

  test('generated foreign keys are enforced by real SQLite', () async {
    final userId = await UserRepository(
      database,
    ).insert(User(name: 'buyer', email: 'buyer@example.com'));
    final requiredUserId = userId!;
    final categoryId = await CategoryRepository(
      database,
    ).insert(Category(name: 'hardware'));
    final productId = await ProductRepository(
      database,
    ).insert(Product(name: 'keyboard', price: 99, categoryId: categoryId!));

    final orderRepository = OrderRepository(database);
    final orderId = await orderRepository.insert(
      Order(
        userId: requiredUserId,
        productId: productId!,
        quantity: 1,
        totalPrice: 99,
      ),
    );
    expect((await orderRepository.findById(orderId))?.productId, productId);

    await expectLater(
      orderRepository.insert(
        Order(
          userId: requiredUserId,
          productId: -1,
          quantity: 1,
          totalPrice: 1,
        ),
      ),
      throwsA(
        isA<NativeSqliteException>().having(
          (error) => error.isForeignKeyViolation,
          'isForeignKeyViolation',
          isTrue,
        ),
      ),
    );
  });
}
