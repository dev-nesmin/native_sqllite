import 'dart:convert';
import 'dart:io';

import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/native/native_database_spec.dart';
import 'package:native_sqlite_generator/src/native_generator.dart';
import 'package:test/test.dart';

void main() {
  group('native output manifest', () {
    late Directory output;

    setUp(() {
      output = Directory.systemTemp.createTempSync('native_output_test_');
    });

    tearDown(() {
      output.deleteSync(recursive: true);
    });

    test('removes stale generated files and updates the manifest', () async {
      final generator = NativeCodeGenerator();
      await generator.writeGeneratedFiles(output.path, {
        'Old.kt': '// AUTO-GENERATED\nold',
      });

      await generator.writeGeneratedFiles(output.path, {
        'Current.kt': '// AUTO-GENERATED\ncurrent',
      });

      expect(File('${output.path}/Old.kt').existsSync(), isFalse);
      expect(File('${output.path}/Current.kt').existsSync(), isTrue);
      final manifest =
          jsonDecode(
                File(
                  '${output.path}/.native_sqlite_generated.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['files'], ['Current.kt']);
    });

    test('keeps a tracked file whose generated marker was removed', () async {
      final generator = NativeCodeGenerator();
      await generator.writeGeneratedFiles(output.path, {
        'Edited.swift': '// AUTO-GENERATED\noriginal',
      });
      File('${output.path}/Edited.swift').writeAsStringSync('hand edited');

      await generator.writeGeneratedFiles(output.path, const {});

      expect(
        File('${output.path}/Edited.swift').readAsStringSync(),
        'hand edited',
      );
    });
  });

  test('native type prefix namespaces model and enum types only', () {
    const table = TableSchemaSnapshot(
      sourcePath: 'lib/domain/account.dart',
      className: 'Account',
      tableName: 'accounts',
      columns: [
        ColumnSchemaSnapshot(
          dartName: 'priority',
          name: 'priority',
          type: 'TEXT',
          nullable: true,
          primaryKey: false,
          autoIncrement: false,
          unique: false,
          isJsonField: false,
          hasConverter: false,
          dartType: 'Priority?',
          enumType: 'name',
          enumValues: ['low', 'high'],
        ),
      ],
      indexes: [],
      version: 1,
      hash: 'hash',
    );
    final spec = NativeDatabaseSpec(
      databaseName: 'app',
      schemaVersion: 1,
      tables: const [table],
      migrations: const {},
      ensureSchema: const [],
    ).withNativeTypePrefix('App');

    expect(spec.tables.single.className, 'AppAccount');
    expect(spec.tables.single.columns.single.dartType, 'AppPriority?');
    expect(spec.tables.single.tableName, 'accounts');
    expect(spec.tables.single.sourcePath, 'lib/domain/account.dart');
  });
}
