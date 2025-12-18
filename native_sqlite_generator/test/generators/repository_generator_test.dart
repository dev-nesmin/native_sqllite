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
  });
}
