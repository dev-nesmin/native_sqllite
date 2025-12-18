import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/native_swift_generator.dart';
import 'package:test/test.dart';

void main() {
  group('NativeSwiftGenerator', () {
    late NativeSwiftGenerator generator;

    setUp(() {
      generator = NativeSwiftGenerator(
        databaseName: 'test_db',
        includeExamples: false,
      );
    });

    final table = TableSchemaSnapshot(
      className: 'User',
      tableName: 'users',
      columns: [
        ColumnSchemaSnapshot(
          dartName: 'id',
          name: 'id',
          dartType: 'int',
          nullable: true,
          primaryKey: true,
          autoIncrement: true,
          unique: false,
          defaultValue: null,
          type: 'INTEGER',
          isJsonField: false,
          hasConverter: false,
        ),
        ColumnSchemaSnapshot(
          dartName: 'name',
          name: 'name',
          dartType: 'String',
          nullable: false,
          primaryKey: false,
          autoIncrement: false,
          unique: false,
          defaultValue: null,
          type: 'TEXT',
          isJsonField: false,
          hasConverter: false,
        ),
        ColumnSchemaSnapshot(
          dartName: 'email',
          name: 'email',
          dartType: 'String',
          nullable: true,
          primaryKey: false,
          autoIncrement: false,
          unique: true,
          defaultValue: null,
          type: 'TEXT',
          isJsonField: false,
          hasConverter: false,
        ),
      ],
      indexes: [],
      version: 1,
      hash: 'abc',
    );

    test('generateSchema generates correct Swift enum', () {
      final code = generator.generateSchema(table);
      // Check imports
      expect(code, contains('import Foundation'));

      // Check enum and table name
      expect(code, contains('public enum UserSchema {'));
      expect(code, contains('public static let tableName = "users"'));

      // Check column constants
      expect(code, contains('public static let id = "id"'));
      expect(code, contains('public static let name = "name"'));
      expect(code, contains('public static let email = "email"'));

      // Check CREATE TABLE SQL
      expect(code, contains('CREATE TABLE users ('));
      expect(code, contains('id INTEGER PRIMARY KEY AUTOINCREMENT'));
      expect(code, contains('name TEXT NOT NULL'));
      expect(code, contains('email TEXT UNIQUE'));
    });

    test('generateHelper generates correct helper struct and class', () {
      final code = generator.generateHelper(table);
      // Check Struct
      expect(code, contains('public struct User {'));
      expect(code, contains('public let id: Int?'));
      expect(code, contains('public let name: String'));
      expect(code, contains('public let email: String?'));

      // Check Helper Class
      expect(code, contains('public class UserHelper {'));
      expect(
        code,
        contains('public func insert(_ entity: User) throws -> Int {'),
      );
      expect(
        code,
        contains('public func findById(_ id: Int) throws -> User? {'),
      );
      expect(
        code,
        contains('public func update(_ entity: User) throws -> Int {'),
      );
      expect(code, contains('public func delete(id: Int) throws -> Int {'));
    });
  });
}
