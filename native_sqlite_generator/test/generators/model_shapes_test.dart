import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:native_sqlite_generator/builder.dart';
import 'package:test/test.dart';

import '../utils/annotations.dart';

void main() {
  group('real-world model shapes', () {
    test('ignores synthetic fields created for getters and hashCode', () async {
      await _expectOutput(
        '''
@DbTable()
class ComputedModel {
  @PrimaryKey()
  final String name;

  const ComputedModel(this.name);

  String get displayName => name.toUpperCase();

  @override
  int get hashCode => name.hashCode;
}
''',
        allOf(
          contains('"name" TEXT PRIMARY KEY NOT NULL'),
          isNot(contains('"display_name" TEXT')),
          isNot(contains('"hash_code" INTEGER')),
          contains("return ComputedModel(map['name'] as String);"),
        ),
      );
    });

    test('includes inherited fields and maps super parameters', () async {
      await _expectOutput(
        '''
class BaseModel {
  @PrimaryKey()
  final DateTime createdAt;

  const BaseModel({required this.createdAt});
}

@DbTable()
class InheritedModel extends BaseModel {
  final String name;

  const InheritedModel({required super.createdAt, required this.name});
}
''',
        allOf(
          contains('"created_at" INTEGER PRIMARY KEY'),
          contains('"name" TEXT NOT NULL'),
          contains('createdAt: DateTime.fromMillisecondsSinceEpoch'),
          contains("name: map['name'] as String"),
        ),
      );
    });

    test(
      'emits positional constructor arguments in declaration order',
      () async {
        await _expectOutput(
          '''
@DbTable()
class PositionalModel {
  @PrimaryKey()
  final int id;
  final String name;

  const PositionalModel(this.id, this.name);
}
''',
          contains(
            "return PositionalModel(map['id'] as int, map['name'] as String);",
          ),
        );
      },
    );

    test('quotes a default table name that is a SQL keyword', () async {
      await _expectOutput(
        '''
@DbTable()
class Order {
  @PrimaryKey()
  final String group;

  const Order(this.group);
}
''',
        allOf(
          contains('CREATE TABLE "order"'),
          contains('"group" TEXT PRIMARY KEY NOT NULL'),
          contains('SELECT * FROM "order"'),
        ),
      );
    });

    test('rejects private fields unless ignored', () async {
      await _expectError('''
@DbTable()
class PrivateModel {
  final String _secret;

  const PrivateModel(this._secret);
}
''', 'Private database field "_secret" must be annotated with @Ignore()');
    });

    test('rejects a late field missing from the constructor', () async {
      await _expectError('''
@DbTable()
class LateModel {
  final String name;
  late final String slug;

  LateModel(this.name);
}
''', 'Database field "slug" has no matching parameter');
    });

    test('rejects an initialized field missing from the constructor', () async {
      await _expectError('''
@DbTable()
class InitializedModel {
  final String name;
  final bool enabled = true;

  InitializedModel(this.name);
}
''', 'Database field "enabled" has no matching parameter');
    });
  });
}

Future<void> _expectOutput(String model, Matcher matcher) async {
  await testBuilder(
    tableBuilder(BuilderOptions({})),
    {
      ...realAnnotationsPackage,
      'a|lib/model.dart':
          '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

$model
''',
    },
    outputs: {'a|lib/model.table.dart': decodedMatches(matcher)},
  );
}

Future<void> _expectError(String model, String message) async {
  final logs = <LogRecord>[];
  await testBuilder(tableBuilder(BuilderOptions({})), {
    ...realAnnotationsPackage,
    'a|lib/model.dart':
        '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

$model
''',
  }, onLog: logs.add);

  expect(
    logs,
    contains(
      isA<LogRecord>().having(
        (record) => record.message,
        'message',
        contains(message),
      ),
    ),
  );
}
