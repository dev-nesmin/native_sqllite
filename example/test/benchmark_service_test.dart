import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/services/benchmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const name = 'benchmark_service_test';
  late NativeSqliteFfi backend;
  late NativeSqliteDatabase database;

  setUpAll(() => backend = NativeSqliteTesting.useFfi());

  setUp(() async {
    await NativeSqlite.deleteDatabase(name);
    database = await NativeSqlite.open(DatabaseConfig(name: name));
  });

  tearDown(() async {
    await database.close();
    await NativeSqlite.deleteDatabase(name);
  });

  tearDownAll(() => backend.dispose());

  test('reports all write strategies and both query plans', () async {
    final report = await BenchmarkService.run(database, rowCount: 20);

    expect(report.measurements, hasLength(5));
    expect(
      report.measurements.map((measurement) => measurement.label),
      containsAll(<String>[
        'Loop: 20 inserts',
        'One transaction',
        'Native platform batch',
        'Query without index',
        'Query with index',
      ]),
    );
    expect(report.measurements.last.detail, contains('benchmark_lookup_idx'));
  });
}
