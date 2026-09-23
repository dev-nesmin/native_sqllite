import 'dart:convert';
import 'dart:io';

import 'package:native_sqlite_generator/src/migration/migration_steps.dart';
import 'package:native_sqlite_generator/src/migration/schema_tracking_builder.dart'
    show migrationFormat;
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('schemas'));
  tearDown(() => dir.deleteSync(recursive: true));

  String snapshot(int version, List<String> sql, {bool legacy = false}) =>
      jsonEncode({
        'schemaVersion': version,
        if (!legacy) 'migrationFormat': migrationFormat,
        'schemas': [],
        'migrations': [
          {'tableName': 't', 'sql': sql},
        ],
      });

  void write(String name, String content) =>
      File('${dir.path}/$name').writeAsStringSync(content);

  test('collects each version step in order, current schema last', () {
    write('native_sqlite_schema_v3.json', snapshot(3, ['C']));
    write('native_sqlite_schema_v2.json', snapshot(2, ['B']));

    final steps = MigrationSteps.load(
      schemasDirectory: dir.path,
      currentSchemaJson: snapshot(4, ['D1', 'D2']),
    );

    expect(steps, {
      2: ['B'],
      3: ['C'],
      4: ['D1', 'D2'],
    });
    expect(steps.keys, [2, 3, 4]);
  });

  test('skips snapshots written before the current migration format', () {
    write('native_sqlite_schema_v2.json', snapshot(2, ['OLD'], legacy: true));
    final skipped = <String>[];

    final steps = MigrationSteps.load(
      schemasDirectory: dir.path,
      currentSchemaJson: null,
      onSkipped: skipped.add,
    );

    expect(steps, isEmpty);
    expect(skipped, ['native_sqlite_schema_v2.json']);
  });
}
