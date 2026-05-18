import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:native_sqlite_generator/builder.dart';
import 'package:test/test.dart';

import '../utils/annotations.dart';

void main() {
  group('SchemaGenerator', () {
    test('generates schema class with table definition', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_user.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'users')
class TestUser {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(name: 'full_name', nullable: false, unique: true)
  final String name;

  const TestUser({this.id, required this.name});
}
''',
        },
        outputs: {
          'a|lib/test_user.table.dart': decodedMatches(
            allOf(
              contains('abstract class TestUserSchema'),
              contains("static const String tableName = 'users';"),
              contains("static const String ID = 'id';"),
              contains("static const String NAME = 'full_name';"),
              contains('CREATE TABLE users'),
              contains('id INTEGER PRIMARY KEY AUTOINCREMENT'),
              contains('full_name TEXT NOT NULL UNIQUE'),
            ),
          ),
        },
      );
    });

    test('generates nullable column without NOT NULL constraint', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_post.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'posts')
class TestPost {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(nullable: true)
  final String? bio;

  const TestPost({this.id, this.bio});
}
''',
        },
        outputs: {
          'a|lib/test_post.table.dart': decodedMatches(
            allOf(
              contains('CREATE TABLE posts'),
              isNot(contains('bio TEXT NOT NULL')),
            ),
          ),
        },
      );
    });

    test('generates column with DEFAULT value', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_item.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'items')
class TestItem {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(defaultValue: "'active'")
  final String status;

  const TestItem({this.id, required this.status});
}
''',
        },
        outputs: {
          'a|lib/test_item.table.dart': decodedMatches(
            contains("DEFAULT 'active'"),
          ),
        },
      );
    });

    test('generates foreign key constraint', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_comment.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'comments')
class TestComment {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @ForeignKey('posts', 'id', onDelete: 'CASCADE')
  @DbColumn()
  final int postId;

  const TestComment({this.id, required this.postId});
}
''',
        },
        outputs: {
          'a|lib/test_comment.table.dart': decodedMatches(
            allOf(
              contains('FOREIGN KEY'),
              contains('posts'),
              contains('CASCADE'),
            ),
          ),
        },
      );
    });

    test('generates inline index from @DbTable indexes parameter', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_product.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'products', indexes: [['name']])
class TestProduct {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String name;

  const TestProduct({this.id, required this.name});
}
''',
        },
        outputs: {
          'a|lib/test_product.table.dart': decodedMatches(
            allOf(
              contains('static const List<String> indexSql'),
              contains('CREATE INDEX'),
              contains('products'),
            ),
          ),
        },
      );
    });

    test('generates column constants in SCREAMING_SNAKE_CASE', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_order.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'orders')
class TestOrder {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final int createdAt;

  const TestOrder({this.id, required this.createdAt});
}
''',
        },
        outputs: {
          'a|lib/test_order.table.dart': decodedMatches(
            contains("static const String CREATED_AT = 'created_at'"),
          ),
        },
      );
    });

    test('generates createTableSql constant', () async {
      await testBuilder(
        tableBuilder(BuilderOptions({})),
        {
          ...mockAnnotationsPackage,
          'a|lib/test_tag.dart': '''
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';

@DbTable(name: 'tags')
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
            contains('static const String createTableSql'),
          ),
        },
      );
    });
  });
}
