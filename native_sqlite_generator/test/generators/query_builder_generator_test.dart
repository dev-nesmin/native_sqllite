import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:native_sqlite_generator/builder.dart';
import 'package:test/test.dart';

import '../utils/annotations.dart';

void main() {
  group('QueryBuilderGenerator', () {
    test('generates query builder with filter methods', () async {
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

  @DbColumn()
  final int age;

  const TestUser({this.id, required this.name, required this.age});
}
''',
        },
        outputs: {
          'a|lib/test_user.table.dart': decodedMatches(
            allOf(
              contains('class TestUserQueryBuilder'),
              contains('TestUserQueryBuilder nameEqualTo(String value)'),
              contains('TestUserQueryBuilder ageGreaterThan(int value)'),
            ),
          ),
        },
      );
    });

    test('generates string filter methods (contains, startsWith, endsWith)',
        () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_post.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestPost {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String title;

  const TestPost({this.id, required this.title});
}
''',
        },
        outputs: {
          'a|lib/test_post.table.dart': decodedMatches(
            allOf(
              contains('titleContains(String value)'),
              contains('titleStartsWith(String value)'),
              contains('titleEndsWith(String value)'),
            ),
          ),
        },
      );
    });

    test('generates numeric range filter methods (between, lessThan, etc.)',
        () async {
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
  final double price;

  const TestProduct({this.id, required this.price});
}
''',
        },
        outputs: {
          'a|lib/test_product.table.dart': decodedMatches(
            allOf(
              contains('priceLessThan(double value)'),
              contains('priceGreaterThanOrEqual(double value)'),
              contains('priceBetween(double min, double max)'),
            ),
          ),
        },
      );
    });

    test('generates sort methods for columns', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_article.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestArticle {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String title;

  const TestArticle({this.id, required this.title});
}
''',
        },
        outputs: {
          'a|lib/test_article.table.dart': decodedMatches(
            allOf(
              contains('orderByTitle()'),
              contains('orderByTitleDesc()'),
            ),
          ),
        },
      );
    });

    test('generates pagination methods (limit, offset)', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_comment.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable()
class TestComment {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String body;

  const TestComment({this.id, required this.body});
}
''',
        },
        outputs: {
          'a|lib/test_comment.table.dart': decodedMatches(
            allOf(
              contains('limit(int value)'),
              contains('offset(int value)'),
            ),
          ),
        },
      );
    });

    test('generates find and count execution methods', () async {
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
            allOf(
              contains('Future<List<TestTag>> find()'),
              contains('Future<int> count()'),
            ),
          ),
        },
      );
    });
  });
}
