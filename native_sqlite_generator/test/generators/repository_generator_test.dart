import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:native_sqlite_generator/builder.dart';
import 'package:test/test.dart';

import '../utils/annotations.dart';

void main() {
  group('RepositoryGenerator', () {
    test('generates repository class with basic CRUD methods', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_user.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestUser {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String name;

  const TestUser({this.id, required this.name});
}
''',
        },
        outputs: {
          'a|lib/test_user.table.dart': decodedMatches(
            allOf(
              contains('class TestUserRepository'),
              contains('Future<int> insert(TestUser entity)'),
              contains('Future<TestUser?> findById(int? id)'),
              contains('Future<List<TestUser>> findAll()'),
              contains('Future<int> update(TestUser entity)'),
              contains('Future<int> delete(int? id)'),
            ),
          ),
        },
      );
    });

    test('generates deleteAll and count methods', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_product.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestProduct {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String title;

  const TestProduct({this.id, required this.title});
}
''',
        },
        outputs: {
          'a|lib/test_product.table.dart': decodedMatches(
            allOf(
              contains('Future<int> deleteAll()'),
              contains('Future<int> count()'),
            ),
          ),
        },
      );
    });

    test('generates raw query method', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_category.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestCategory {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String name;

  const TestCategory({this.id, required this.name});
}
''',
        },
        outputs: {
          'a|lib/test_category.table.dart': decodedMatches(
            contains('Future<QueryResult> query('),
          ),
        },
      );
    });

    test('constructor accepts optional databaseName parameter', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_tag.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestTag {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String label;

  const TestTag({this.id, required this.label});
}
''',
        },
        outputs: {
          'a|lib/test_tag.table.dart': decodedMatches(
            contains('TestTagRepository('),
          ),
        },
      );
    });

    test('generates _fromMap private deserializer', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_note.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestNote {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String content;

  const TestNote({this.id, required this.content});
}
''',
        },
        outputs: {
          'a|lib/test_note.table.dart': decodedMatches(
            contains('_fromMap('),
          ),
        },
      );
    });

    test('generates findAll returning typed list', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_order.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestOrder {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String reference;

  const TestOrder({this.id, required this.reference});
}
''',
        },
        outputs: {
          'a|lib/test_order.table.dart': decodedMatches(
            contains('Future<List<TestOrder>> findAll()'),
          ),
        },
      );
    });
  });
}
