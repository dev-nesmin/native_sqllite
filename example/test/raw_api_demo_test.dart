import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite/testing.dart';
import 'package:native_sqlite_example/services/raw_api_demo_service.dart';

void main() {
  late NativeSqliteFfi backend;

  setUpAll(() {
    backend = NativeSqliteTesting.useFfi();
  });

  tearDownAll(() {
    backend.dispose();
  });

  test('raw API tour covers every operation and typed error', () async {
    final results = await const RawApiDemoService().run();

    expect(results, hasLength(16));
    expect(
      results
          .where((result) => !result.passed)
          .map((result) => '${result.operation}: ${result.detail}'),
      isEmpty,
    );
    expect(
      results.map((result) => result.operation),
      containsAll([
        'getDatabasePath',
        'open',
        'executeInsert',
        'execute',
        'query',
        'insert',
        'update',
        'transaction',
        'batch',
        'delete',
        'close',
        'deleteDatabase',
      ]),
    );

    final errors = {
      for (final result in results) result.operation: result.error,
    };
    expect(errors['UNIQUE']?.extendedResultCode, 2067);
    expect(errors['NOT NULL']?.extendedResultCode, 1299);
    expect(errors['FOREIGN KEY']?.extendedResultCode, 787);
    expect(errors['syntax error']?.resultCode, 1);
    expect(errors.values.whereType<NativeSqliteException>(), hasLength(4));
  });
}
