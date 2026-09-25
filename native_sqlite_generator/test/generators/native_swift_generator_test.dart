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
      sourcePath: 'lib/domain/person_record.dart',
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
        ColumnSchemaSnapshot(
          dartName: 'userID',
          name: 'user_id',
          dartType: 'String',
          nullable: false,
          primaryKey: false,
          autoIncrement: false,
          unique: false,
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
      expect(code, contains('Generated from: lib/domain/person_record.dart'));

      // Check column constants
      expect(code, contains('public static let id = "id"'));
      expect(code, contains('public static let name = "name"'));
      expect(code, contains('public static let email = "email"'));
      expect(code, contains('public static let userId = "user_id"'));

      // Check CREATE TABLE SQL
      expect(code, contains('CREATE TABLE \\"users\\" ('));
      expect(code, contains('\\"id\\" INTEGER PRIMARY KEY AUTOINCREMENT'));
      expect(code, contains('\\"name\\" TEXT NOT NULL'));
      expect(code, contains('\\"email\\" TEXT UNIQUE'));
    });

    test('generateHelper generates correct helper struct and class', () {
      final code = generator.generateHelper(table);
      // Check Struct
      expect(code, contains('public struct User {'));
      expect(code, contains('public let id: Int64?'));
      expect(code, contains('public let name: String'));
      expect(code, contains('public let email: String?'));

      // Check Helper Class
      expect(code, contains('public class UserHelper {'));
      expect(
        code,
        contains('public func insert(_ entity: User) throws -> Int64 {'),
      );
      expect(
        code,
        contains('public func findById(_ id: Int64) throws -> User? {'),
      );
      expect(
        code,
        contains('public func update(_ entity: User) throws -> Int {'),
      );
      expect(code, contains('public func delete(id: Int64) throws -> Int {'));
      expect(code, isNot(contains('getInstance(')));
      expect(code, isNot(contains('cleanupIsolate')));
      expect(code, isNot(contains('isolateInstances')));
    });

    test('generateSchema rejects reserved member collisions', () {
      final conflicting = table.copyWith(
        columns: [
          ...table.columns,
          const ColumnSchemaSnapshot(
            dartName: 'tableName',
            name: 'table_name',
            dartType: 'String',
            nullable: false,
            primaryKey: false,
            autoIncrement: false,
            unique: false,
            type: 'TEXT',
            isJsonField: false,
            hasConverter: false,
          ),
        ],
      );

      expect(
        () => generator.generateSchema(conflicting),
        throwsA(isA<StateError>()),
      );
    });

    test('generateHelper creates and returns UUID primary keys', () {
      final uuidTable = TableSchemaSnapshot.fromTableInfo(
        'Note',
        'notes',
        const [
          ColumnSchemaSnapshot(
            dartName: 'id',
            name: 'id',
            type: 'TEXT',
            nullable: true,
            primaryKey: true,
            autoIncrement: false,
            useLocalUuid: true,
            unique: false,
            isJsonField: false,
            hasConverter: false,
            dartType: 'String?',
          ),
          ColumnSchemaSnapshot(
            dartName: 'body',
            name: 'body',
            type: 'TEXT',
            nullable: false,
            primaryKey: false,
            autoIncrement: false,
            unique: false,
            isJsonField: false,
            hasConverter: false,
            dartType: 'String',
          ),
        ],
        const [],
        1,
      );

      final code = generator.generateHelper(uuidTable);
      expect(
        code,
        contains('public func insert(_ entity: Note) throws -> String {'),
      );
      expect(
        code,
        contains('let primaryKeyValue = entity.id ?? UUID().uuidString'),
      );
      expect(code, contains('NoteSchema.id: primaryKeyValue'));
      expect(code, contains('return primaryKeyValue'));
      expect(
        code,
        contains('func insertBatch(_ entities: [Note]) throws -> [String]'),
      );
    });

    test('generateHelper rejects a schema without exactly one primary key', () {
      const invalid = TableSchemaSnapshot(
        className: 'LogEntry',
        tableName: 'logs',
        columns: [
          ColumnSchemaSnapshot(
            dartName: 'message',
            name: 'message',
            type: 'TEXT',
            nullable: false,
            primaryKey: false,
            autoIncrement: false,
            unique: false,
            isJsonField: false,
            hasConverter: false,
            dartType: 'String',
          ),
        ],
        indexes: [],
        version: 1,
        hash: 'invalid',
      );

      expect(
        () => generator.generateHelper(invalid),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            contains('requires exactly one primary key; found 0'),
          ),
        ),
      );
    });
  });
}
