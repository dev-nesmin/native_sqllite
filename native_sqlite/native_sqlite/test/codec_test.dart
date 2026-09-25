import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite/native_sqlite.dart';

void main() {
  test('NativeSqliteCodec round-trips JSON values', () {
    final encoded = NativeSqliteCodec.jsonEncode({
      'name': 'native_sqlite',
      'values': [1, true, null],
    });

    expect(NativeSqliteCodec.jsonDecode(encoded), {
      'name': 'native_sqlite',
      'values': [1, true, null],
    });
  });

  test('NativeSqliteCodec validates BLOB values for generated parts', () {
    final value = Uint8List.fromList([0, 127, 255]);

    expect(NativeSqliteCodec.asBlob(value), same(value));
    expect(
      () => NativeSqliteCodec.asBlob('not a blob'),
      throwsA(isA<TypeError>()),
    );
  });
}
