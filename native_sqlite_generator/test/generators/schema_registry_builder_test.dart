import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:native_sqlite_generator/builder.dart';
import 'package:test/test.dart';

import '../utils/annotations.dart';

void main() {
  test('regenerates database manager on every build step', () async {
    final builder = schemaRegistryBuilder(BuilderOptions({}));

    await testBuilder(
      builder,
      {
        ...realAnnotationsPackage,
        'a|lib/user.dart': _model('User', 'final String name;'),
        'a|lib/generated/native_sqlite_schema.json': _schema('User', 'name'),
      },
      outputs: {
        'a|lib/generated/database_manager.dart': decodedMatches(
          allOf(
            contains('UserSchema.createTableSql'),
            isNot(contains('debugPrint(')),
            isNot(contains('package:flutter/foundation.dart')),
          ),
        ),
      },
    );

    await testBuilder(
      builder,
      {
        ...realAnnotationsPackage,
        'a|lib/account.dart': _model('Account', 'final String email;'),
        'a|lib/generated/native_sqlite_schema.json': _schema(
          'Account',
          'email',
        ),
      },
      outputs: {
        'a|lib/generated/database_manager.dart': decodedMatches(
          contains('AccountSchema.createTableSql'),
        ),
      },
    );
  });

  test(
    'fails instead of guessing version 1 when schema JSON is missing',
    () async {
      final builder = schemaRegistryBuilder(BuilderOptions({}));
      final logs = <LogRecord>[];

      await testBuilder(builder, {
        ...realAnnotationsPackage,
        'a|lib/user.dart': _model('User', 'final String name;'),
      }, onLog: logs.add);

      expect(
        logs,
        contains(
          isA<LogRecord>()
              .having((log) => log.level >= Level.SEVERE, 'is severe', isTrue)
              .having(
                (log) => log.message,
                'message',
                contains('native_sqlite_schema.json is missing'),
              ),
        ),
      );
    },
  );

  test('propagates model analysis errors', () async {
    final builder = schemaRegistryBuilder(BuilderOptions({}));
    final logs = <LogRecord>[];
    final invalidModel = '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class InvalidModel {
  @PrimaryKey()
  final String first;

  @PrimaryKey()
  final String second;

  const InvalidModel({required this.first, required this.second});
}
''';

    await testBuilder(builder, {
      ...realAnnotationsPackage,
      'a|lib/invalid_model.dart': invalidModel,
      'a|lib/generated/native_sqlite_schema.json': _schema(
        'InvalidModel',
        'value',
      ),
    }, onLog: logs.add);

    expect(
      logs,
      contains(
        isA<LogRecord>()
            .having((log) => log.level >= Level.SEVERE, 'is severe', isTrue)
            .having(
              (log) => log.message,
              'message',
              contains('Composite primary keys are not supported'),
            ),
      ),
    );
  });
}

String _model(String className, String field) =>
    '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class $className {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  $field

  const $className({this.id, required this.${field.split(' ').last.replaceAll(';', '')}});
}
''';

String _schema(String className, String fieldName) => jsonEncode({
  'schemaVersion': 1,
  'migrationFormat': 2,
  'migrations': <Object>[],
  'schemas': [
    {
      'className': className,
      'tableName': _snakeCase(className),
      'columns': [
        {
          'dartName': 'id',
          'name': 'id',
          'type': 'INTEGER',
          'nullable': true,
          'primaryKey': true,
          'autoIncrement': true,
          'unique': false,
          'isJsonField': false,
          'hasConverter': false,
          'dartType': 'int?',
        },
        {
          'dartName': fieldName,
          'name': fieldName,
          'type': 'TEXT',
          'nullable': false,
          'primaryKey': false,
          'autoIncrement': false,
          'unique': false,
          'isJsonField': false,
          'hasConverter': false,
          'dartType': 'String',
        },
      ],
      'indexes': <Object>[],
      'version': 1,
      'hash': 'test',
    },
  ],
});

String _snakeCase(String value) => value
    .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    )
    .toLowerCase();
