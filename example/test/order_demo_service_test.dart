import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/models/category.dart';
import 'package:native_sqlite_example/models/order.dart';
import 'package:native_sqlite_example/models/product.dart';
import 'package:native_sqlite_example/models/user.dart';
import 'package:native_sqlite_example/services/order_demo_service.dart';
import 'package:native_sqlite_example/screens/order_management_screen.dart';

void main() {
  const databaseName = 'order_demo_service_test';
  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;
  late OrderDemoService service;

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
    service = OrderDemoService(database);
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(databaseName);
  });

  tearDownAll(() {
    backend.dispose();
  });

  Future<(int, int)> seedOrderDependencies() async {
    final userId = await UserRepository(
      database,
    ).insert(User(name: 'Buyer', email: 'buyer@example.com'));
    final categoryId = await CategoryRepository(
      database,
    ).insert(Category(name: 'Hardware'));
    final productId = await ProductRepository(database).insert(
      Product(name: 'Keyboard', price: 50, stock: 5, categoryId: categoryId!),
    );
    return (userId!, productId!);
  }

  test('place order commits the order and stock decrement together', () async {
    final (userId, productId) = await seedOrderDependencies();

    final orderId = await service.placeOrder(
      userId: userId,
      productId: productId,
      quantity: 2,
      totalPrice: 100,
      status: OrderStatus.processing,
    );

    expect(orderId, greaterThan(0));
    expect(await service.stockFor(productId), 3);
    expect(await OrderRepository(database).count(), 1);
    expect(
      (await database.query('SELECT status FROM orders WHERE id = ?', [
        orderId,
      ])).rows.single.single,
      OrderStatus.processing.name,
    );
  });

  test('forced failure rolls back both writes', () async {
    final (userId, productId) = await seedOrderDependencies();

    await expectLater(
      service.placeOrder(
        userId: userId,
        productId: productId,
        quantity: 2,
        totalPrice: 100,
        forceFailure: true,
      ),
      throwsA(isA<StateError>()),
    );

    expect(await service.stockFor(productId), 5);
    expect(await OrderRepository(database).count(), 0);
  });

  test('batch inserts 1000 rows with bound arguments', () async {
    expect(
      await service.insertUsersBatch(count: 1000, uniquePrefix: 'bulk'),
      1000,
    );
    expect(await UserRepository(database).count(), 1000);
  });

  testWidgets('editing preserves the stored total until explicit repricing', (
    tester,
  ) async {
    final user = User(id: 1, name: 'Buyer', email: 'buyer@example.com');
    final product = Product(
      id: 1,
      name: 'Keyboard',
      price: 100,
      stock: 10,
      categoryId: 1,
    );
    final order = Order(
      id: 1,
      userId: 1,
      productId: 1,
      quantity: 1,
      totalPrice: 50,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderFormDialog(
            users: [user],
            products: [product],
            order: order,
          ),
        ),
      ),
    );
    expect(find.text('Stored Total Price'), findsOneWidget);
    expect(find.text(r'$50.00'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '2');
    await tester.pump();
    expect(find.text(r'$50.00'), findsOneWidget);

    await tester.tap(find.text('Recalculate from current product price'));
    await tester.pump();
    expect(find.text(r'$200.00'), findsOneWidget);
  });
}
