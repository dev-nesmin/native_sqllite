import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_sqlite_inspector/widgets/data_grid.dart';

void main() {
  testWidgets('renders duplicate result columns without row actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DataGrid(
            columns: ['value', 'value'],
            rows: [
              [1, 2],
            ],
          ),
        ),
      ),
    );

    expect(find.text('value'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Actions'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('renders NULL, BLOB, and non-finite values safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DataGrid(
            columns: ['null', 'blob', 'number'],
            rows: [
              [
                null,
                {r'$type': 'blob', 'base64': 'AAE=', 'length': 2},
                {r'$type': 'number', 'value': 'Infinity'},
              ],
            ],
          ),
        ),
      ),
    );

    expect(find.text('NULL'), findsOneWidget);
    expect(find.text('BLOB (2 bytes)'), findsOneWidget);
    expect(find.text('Infinity'), findsOneWidget);
  });
}
