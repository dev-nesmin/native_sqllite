import 'package:native_sqlite_generator/src/helpers/naming.dart';
import 'package:test/test.dart';

void main() {
  group('NamingUtils.toSnakeCase', () {
    test('converts camelCase to snake_case', () {
      expect(NamingUtils.toSnakeCase('userName'), 'user_name');
      expect(NamingUtils.toSnakeCase('createdAt'), 'created_at');
    });

    test('converts PascalCase to snake_case', () {
      expect(NamingUtils.toSnakeCase('UserName'), 'user_name');
    });

    test('preserves existing snake_case', () {
      expect(NamingUtils.toSnakeCase('user_name'), 'user_name');
    });

    test('handles empty string', () {
      expect(NamingUtils.toSnakeCase(''), '');
    });
  });

  group('NamingUtils.toScreamingSnakeCase', () {
    test('converts camelCase to SCREAMING_SNAKE_CASE', () {
      expect(NamingUtils.toScreamingSnakeCase('userName'), 'USER_NAME');
      expect(NamingUtils.toScreamingSnakeCase('createdAt'), 'CREATED_AT');
    });

    test('converts PascalCase to SCREAMING_SNAKE_CASE', () {
      expect(NamingUtils.toScreamingSnakeCase('UserName'), 'USER_NAME');
    });

    test('converts snake_case to SCREAMING_SNAKE_CASE', () {
      expect(NamingUtils.toScreamingSnakeCase('user_name'), 'USER_NAME');
    });

    test('handles single word', () {
      expect(NamingUtils.toScreamingSnakeCase('id'), 'ID');
    });
  });

  group('NamingUtils.toCamelCase', () {
    test('converts snake_case to camelCase', () {
      expect(NamingUtils.toCamelCase('user_name'), 'userName');
      expect(NamingUtils.toCamelCase('created_at'), 'createdAt');
    });

    test('converts PascalCase to camelCase', () {
      expect(NamingUtils.toCamelCase('UserName'), 'userName');
    });

    test('preserves existing camelCase', () {
      expect(NamingUtils.toCamelCase('userName'), 'userName');
    });
  });

  group('NamingUtils.toPascalCase', () {
    test('converts snake_case to PascalCase', () {
      expect(NamingUtils.toPascalCase('user_name'), 'UserName');
      expect(NamingUtils.toPascalCase('created_at'), 'CreatedAt');
    });

    test('converts camelCase to PascalCase', () {
      expect(NamingUtils.toPascalCase('userName'), 'UserName');
    });

    test('preserves existing PascalCase', () {
      expect(NamingUtils.toPascalCase('UserName'), 'UserName');
    });
  });

  group('NamingUtils.capitalize', () {
    test('capitalizes first letter', () {
      expect(NamingUtils.capitalize('hello'), 'Hello');
      expect(NamingUtils.capitalize('world'), 'World');
    });

    test('preserves rest of string', () {
      expect(NamingUtils.capitalize('helloWorld'), 'HelloWorld');
    });

    test('handles single character', () {
      expect(NamingUtils.capitalize('a'), 'A');
    });

    test('handles empty string', () {
      expect(NamingUtils.capitalize(''), '');
    });

    test('no-op on already-capitalized string', () {
      expect(NamingUtils.capitalize('Hello'), 'Hello');
    });
  });

  group('NamingUtils.decapitalize', () {
    test('lowercases first letter', () {
      expect(NamingUtils.decapitalize('Hello'), 'hello');
      expect(NamingUtils.decapitalize('UserName'), 'userName');
    });

    test('handles single character', () {
      expect(NamingUtils.decapitalize('A'), 'a');
    });

    test('handles empty string', () {
      expect(NamingUtils.decapitalize(''), '');
    });

    test('no-op on already-lowercase string', () {
      expect(NamingUtils.decapitalize('hello'), 'hello');
    });
  });

  group('NamingUtils.getSchemaClassName', () {
    test('appends Schema suffix', () {
      expect(NamingUtils.getSchemaClassName('User'), 'UserSchema');
      expect(NamingUtils.getSchemaClassName('Post'), 'PostSchema');
    });

    test('works with multi-word class names', () {
      expect(NamingUtils.getSchemaClassName('UserProfile'), 'UserProfileSchema');
    });
  });

  group('NamingUtils.getRepositoryClassName', () {
    test('appends Repository suffix', () {
      expect(NamingUtils.getRepositoryClassName('User'), 'UserRepository');
      expect(NamingUtils.getRepositoryClassName('Post'), 'PostRepository');
    });

    test('works with multi-word class names', () {
      expect(
        NamingUtils.getRepositoryClassName('OrderItem'),
        'OrderItemRepository',
      );
    });
  });

  group('NamingUtils.getColumnConstantName', () {
    test('converts camelCase column to SCREAMING_SNAKE_CASE', () {
      expect(NamingUtils.getColumnConstantName('userName'), 'USER_NAME');
      expect(NamingUtils.getColumnConstantName('createdAt'), 'CREATED_AT');
    });

    test('converts snake_case column to SCREAMING_SNAKE_CASE', () {
      expect(NamingUtils.getColumnConstantName('user_name'), 'USER_NAME');
    });

    test('handles single word', () {
      expect(NamingUtils.getColumnConstantName('id'), 'ID');
      expect(NamingUtils.getColumnConstantName('name'), 'NAME');
    });
  });
}
