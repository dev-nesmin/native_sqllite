import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';

void main() {
  test('NativeSqliteUuid generates distinct RFC 4122 version 4 UUIDs', () {
    final values = List.generate(100, (_) => NativeSqliteUuid.generate());
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(values, everyElement(matches(pattern)));
    expect(values.toSet(), hasLength(values.length));
  });
}
