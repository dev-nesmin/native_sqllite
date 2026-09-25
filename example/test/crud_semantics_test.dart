import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/models/category.dart';
import 'package:native_sqlite_example/models/order.dart';
import 'package:native_sqlite_example/models/product.dart';
import 'package:native_sqlite_example/models/user.dart';

void main() {
  test('copyWith distinguishes omitted nullable values from explicit null', () {
    final instant = DateTime.fromMillisecondsSinceEpoch(1234);
    final user = User(
      name: 'User',
      email: 'user@example.com',
      phoneNumber: '123',
      address: 'Address',
      updatedAt: instant,
      tempPassword: 'temporary',
    );
    expect(user.copyWith().phoneNumber, '123');
    final clearedUser = user.copyWith(
      phoneNumber: null,
      address: null,
      updatedAt: null,
      tempPassword: null,
    );
    expect(clearedUser.phoneNumber, isNull);
    expect(clearedUser.address, isNull);
    expect(clearedUser.updatedAt, isNull);
    expect(clearedUser.tempPassword, isNull);

    final category = Category(name: 'Category', description: 'Description');
    expect(category.copyWith().description, 'Description');
    expect(category.copyWith(description: null).description, isNull);

    final product = Product(
      name: 'Product',
      description: 'Description',
      price: 1,
      categoryId: 1,
      imageUrl: 'image',
      updatedAt: instant,
    );
    expect(product.copyWith().description, 'Description');
    final clearedProduct = product.copyWith(
      description: null,
      imageUrl: null,
      updatedAt: null,
    );
    expect(clearedProduct.description, isNull);
    expect(clearedProduct.imageUrl, isNull);
    expect(clearedProduct.updatedAt, isNull);

    final order = Order(
      userId: 1,
      productId: 1,
      quantity: 1,
      totalPrice: 1,
      notes: 'Note',
      updatedAt: instant,
      deliveredAt: instant,
    );
    expect(order.copyWith().notes, 'Note');
    final clearedOrder = order.copyWith(
      notes: null,
      updatedAt: null,
      deliveredAt: null,
    );
    expect(clearedOrder.notes, isNull);
    expect(clearedOrder.updatedAt, isNull);
    expect(clearedOrder.deliveredAt, isNull);
  });

  group('generated CRUD query behavior', () {
    const databaseName = 'crud_semantics_test';
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
          onCreate: [UserSchema.createTableSql],
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

    test('sorts and paginates through the generated query builder', () async {
      final repository = UserRepository(database);
      for (var index = 24; index >= 0; index--) {
        await repository.insert(
          User(
            name: 'User ${index.toString().padLeft(2, '0')}',
            email: 'user-$index@example.com',
          ),
        );
      }

      final query = UserQueryBuilder(
        database,
      ).sortByNameAsc().limit(5).offset(10);
      expect((await query.findAll()).map((user) => user.name), [
        'User 10',
        'User 11',
        'User 12',
        'User 13',
        'User 14',
      ]);
      expect(await UserQueryBuilder(database).nameContains('2').count(), 7);
    });

    test('reports UNIQUE violations with their typed contract', () async {
      final repository = UserRepository(database);
      await repository.insert(User(name: 'One', email: 'same@example.com'));

      await expectLater(
        repository.insert(User(name: 'Two', email: 'same@example.com')),
        throwsA(
          isA<NativeSqliteException>().having(
            (error) => error.isUniqueViolation,
            'isUniqueViolation',
            isTrue,
          ),
        ),
      );
    });
  });
}
