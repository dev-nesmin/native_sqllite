# Testing your application

Use `package:native_sqlite/testing.dart` for fast Flutter host tests backed by
real SQLite rather than method-channel mocks.

```dart
late NativeSqliteFfi backend;

setUpAll(() => backend = NativeSqliteTesting.useFfi());
tearDownAll(() => backend.dispose());

test('commits an order', () async {
  final database = await NativeSqlite.open(
    DatabaseConfig(
      name: 'orders_test',
      onCreate: ['CREATE TABLE orders (id INTEGER PRIMARY KEY, total REAL)'],
    ),
  );
  addTearDown(database.close);

  final id = await database.insert('orders', {'total': 19.95});
  expect(id, greaterThan(0));
});
```

The backend uses a fresh system temporary directory unless `directory` is
provided. Close every handle before disposing it.

Host tests cover SQL, generated repositories, migration logic, transactions,
and batches. Keep device integration tests for method-channel contracts,
system SQLite versions, background isolates, native-generated helpers,
WorkManager/BGTaskScheduler, and web IndexedDB. For an upgrade test, install a
fixture build, create and seed its old schema, then install the new build over
it without clearing application data.
