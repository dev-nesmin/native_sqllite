import 'package:flutter_test/flutter_test.dart';

import 'package:native_sqlite_example/main.dart';

void main() {
  testWidgets('home screen lists every demo', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Native SQLite Example'), findsOneWidget);
    for (final demo in [
      'CRUD Operations',
      'Order Management',
      'Query Builder',
      'Advanced Features',
      'JSON & Custom Types',
      'Manual API Demo',
      'Native Code Integration',
      'Database Statistics',
    ]) {
      await tester.scrollUntilVisible(find.text(demo), 200);
      expect(find.text(demo), findsOneWidget);
    }
  });
}
