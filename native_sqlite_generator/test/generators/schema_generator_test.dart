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
  });
}
