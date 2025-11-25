import 'package:native_sqlite_generator/src/helpers/naming_conventions.dart';
import 'package:test/test.dart';

void main() {
  group('NamingConventions.toSnakeCase', () {
    test('converts camelCase to snake_case', () {
      expect(NamingConventions.toSnakeCase('userName'), equals('user_name'));
      expect(NamingConventions.toSnakeCase('userId'), equals('user_id'));
      expect(NamingConventions.toSnakeCase('createdAt'), equals('created_at'));
    });

    test('converts PascalCase to snake_case', () {
      expect(NamingConventions.toSnakeCase('UserName'), equals('user_name'));
      expect(NamingConventions.toSnakeCase('UserId'), equals('user_id'));
      expect(NamingConventions.toSnakeCase('CreatedAt'), equals('created_at'));
    });

    test('handles acronyms correctly', () {
      expect(NamingConventions.toSnakeCase('userID'), equals('user_id'));
      expect(NamingConventions.toSnakeCase('HTTPResponse'),
          equals('http_response'));
      expect(NamingConventions.toSnakeCase('parseHTML'), equals('parse_html'));
    });

    test('preserves existing snake_case', () {
      expect(NamingConventions.toSnakeCase('user_name'), equals('user_name'));
      expect(NamingConventions.toSnakeCase('user_id'), equals('user_id'));
    });

    test('handles edge cases', () {
      expect(NamingConventions.toSnakeCase(''), equals(''));
      expect(NamingConventions.toSnakeCase('a'), equals('a'));
      expect(NamingConventions.toSnakeCase('A'), equals('a'));
    });
  });

  group('NamingConventions.toCamelCase', () {
    test('converts snake_case to camelCase', () {
      expect(NamingConventions.toCamelCase('user_name'), equals('userName'));
      expect(NamingConventions.toCamelCase('user_id'), equals('userId'));
      expect(NamingConventions.toCamelCase('created_at'), equals('createdAt'));
    });

    test('converts PascalCase to camelCase', () {
      expect(NamingConventions.toCamelCase('UserName'), equals('userName'));
      expect(NamingConventions.toCamelCase('UserId'), equals('userId'));
    });

    test('preserves existing camelCase', () {
      expect(NamingConventions.toCamelCase('userName'), equals('userName'));
      expect(NamingConventions.toCamelCase('userId'), equals('userId'));
    });

    test('handles edge cases', () {
      expect(NamingConventions.toCamelCase(''), equals(''));
      expect(NamingConventions.toCamelCase('a'), equals('a'));
      expect(NamingConventions.toCamelCase('A'), equals('a'));
    });
  });

  group('NamingConventions.toPascalCase', () {
    test('converts snake_case to PascalCase', () {
      expect(NamingConventions.toPascalCase('user_name'), equals('UserName'));
      expect(NamingConventions.toPascalCase('user_id'), equals('UserId'));
      expect(NamingConventions.toPascalCase('created_at'), equals('CreatedAt'));
    });

    test('converts camelCase to PascalCase', () {
      expect(NamingConventions.toPascalCase('userName'), equals('UserName'));
      expect(NamingConventions.toPascalCase('userId'), equals('UserId'));
    });

    test('preserves existing PascalCase', () {
      expect(NamingConventions.toPascalCase('UserName'), equals('UserName'));
      expect(NamingConventions.toPascalCase('UserId'), equals('UserId'));
    });

    test('handles edge cases', () {
      expect(NamingConventions.toPascalCase(''), equals(''));
      expect(NamingConventions.toPascalCase('a'), equals('A'));
      expect(NamingConventions.toPascalCase('A'), equals('A'));
    });
  });

  group('NamingConventions validation', () {
    test('isSnakeCase correctly identifies snake_case', () {
      expect(NamingConventions.isSnakeCase('user_name'), isTrue);
      expect(NamingConventions.isSnakeCase('user_id'), isTrue);
      expect(NamingConventions.isSnakeCase('userName'), isFalse);
      expect(NamingConventions.isSnakeCase('UserName'), isFalse);
    });

    test('isCamelCase correctly identifies camelCase', () {
      expect(NamingConventions.isCamelCase('userName'), isTrue);
      expect(NamingConventions.isCamelCase('userId'), isTrue);
      expect(NamingConventions.isCamelCase('user_name'), isFalse);
      expect(NamingConventions.isCamelCase('UserName'), isFalse);
    });

    test('isPascalCase correctly identifies PascalCase', () {
      expect(NamingConventions.isPascalCase('UserName'), isTrue);
      expect(NamingConventions.isPascalCase('UserId'), isTrue);
      expect(NamingConventions.isPascalCase('userName'), isFalse);
      expect(NamingConventions.isPascalCase('user_name'), isFalse);
    });
  });

  group('NamingConventions.format', () {
    test('formats to specified convention', () {
      expect(
          NamingConventions.format('userName', 'snake'), equals('user_name'));
      expect(
          NamingConventions.format('user_name', 'camel'), equals('userName'));
      expect(
          NamingConventions.format('user_name', 'pascal'), equals('UserName'));
    });

    test('returns original for unknown convention', () {
      expect(
          NamingConventions.format('userName', 'unknown'), equals('userName'));
    });
  });
}
