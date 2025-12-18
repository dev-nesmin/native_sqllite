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
  });
}
