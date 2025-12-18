import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:native_sqlite_generator/builder.dart';
import 'package:test/test.dart';

import '../utils/annotations.dart';

void main() {
  group('PrimaryKey Enhancements', () {
    test('validates that autoIncrement=true requires int field', () async {
      final logs = <LogRecord>[];
      await testBuilder(tableBuilder(BuilderOptions({})), {
        ...mockAnnotationsPackage,
        'a|lib/test_model.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestModel {
  @PrimaryKey(autoIncrement: true)
  final String id;

  const TestModel({required this.id});
}
''',
      }, onLog: logs.add);

      expect(
        logs,
        contains(
          isA<LogRecord>().having(
            (l) => l.message,
            'message',
            contains(
              'PrimaryKey with autoIncrement=true must be an integer field',
            ),
          ),
        ),
      );
    });

    test('validates that useLocalUuid=true requires String field', () async {
      final logs = <LogRecord>[];
      await testBuilder(tableBuilder(BuilderOptions({})), {
        ...mockAnnotationsPackage,
        'a|lib/test_model.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestModel {
  @PrimaryKey(useLocalUuid: true)
  final int id;

  const TestModel({required this.id});
}
''',
      }, onLog: logs.add);

      expect(
        logs,
        contains(
          isA<LogRecord>().having(
            (l) => l.message,
            'message',
            contains('must be a String field'),
          ),
        ),
      );
    });

    test('validates that useLocalUuid=true requires nullable field', () async {
      final logs = <LogRecord>[];
      await testBuilder(tableBuilder(BuilderOptions({})), {
        ...mockAnnotationsPackage,
        'a|lib/test_model.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestModel {
  @PrimaryKey(useLocalUuid: true)
  final String id;

  const TestModel({required this.id});
}
''',
      }, onLog: logs.add);

      expect(
        logs,
        contains(
          isA<LogRecord>().having(
            (l) => l.message,
            'message',
            contains('must be nullable'),
          ),
        ),
      );
    });

    test(
      'validates that autoIncrement and useLocalUuid cannot be both true',
      () async {
        final logs = <LogRecord>[];
        await testBuilder(tableBuilder(BuilderOptions({})), {
          ...mockAnnotationsPackage,
          'a|lib/test_model.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestModel {
  @PrimaryKey(autoIncrement: true, useLocalUuid: true)
  final String? id;

  const TestModel({this.id});
}
''',
        }, onLog: logs.add);

        expect(
          logs,
          contains(
            isA<LogRecord>().having(
              (l) => l.message,
              'message',
              contains('cannot have both autoIncrement=true'),
            ),
          ),
        );
      },
    );

    test('generates correctly for useLocalUuid=true', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_uuid.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestUuid {
  @PrimaryKey(useLocalUuid: true)
  final String? id;

  @DbColumn()
  final String name;

  const TestUuid({this.id, required this.name});
}
''',
        },
        outputs: {
          'a|lib/test_uuid.table.dart': decodedMatches(
            allOf(
              contains('Future<String> insert(TestUuid entity)'),
              contains('final id = entity.id ?? _generateUuid();'),
              contains('return id as String;'),
              contains('String _generateUuid()'),
            ),
          ),
        },
      );
    });
  });
}
