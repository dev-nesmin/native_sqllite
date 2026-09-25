import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/native_kotlin_generator.dart';
import 'package:test/test.dart';

void main() {
  group('NativeKotlinGenerator', () {
    late NativeKotlinGenerator generator;

    setUp(() {
      generator = NativeKotlinGenerator(
        packageName: 'com.example.app',
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

    test('generateSchema generates correct Kotlin object', () {
      final code = generator.generateSchema(table);
      // Check package and object definition
      expect(code, contains('package com.example.app'));
      expect(code, contains('object UserSchema {'));
      expect(code, contains('const val TABLE_NAME = "users"'));
      expect(code, contains('Generated from: lib/domain/person_record.dart'));

      // Check column constants
      expect(code, contains('const val ID = "id"'));
      expect(code, contains('const val NAME = "name"'));
      expect(code, contains('const val EMAIL = "email"'));
      expect(code, contains('const val USER_ID = "user_id"'));

      // Check CREATE TABLE SQL
      expect(code, contains('CREATE TABLE \\"users\\" ('));
      expect(code, contains('\\"id\\" INTEGER PRIMARY KEY AUTOINCREMENT'));
      expect(code, contains('\\"name\\" TEXT NOT NULL'));
      expect(code, contains('\\"email\\" TEXT UNIQUE'));
    });

    test('generateHelper generates correct helper class', () {
      final code = generator.generateHelper(table);
      // Check imports
      expect(code, contains('package com.example.app'));
      expect(
        code,
        contains('import dev.nesmin.native_sqlite.NativeSqliteManager'),
      );

      // Check Data Class
      expect(code, contains('data class User('));
      expect(code, contains('val id: Long? = null'));
      expect(code, contains('val name: String'));
      expect(code, contains('val email: String?'));

      // Check Helper Class
      expect(
        code,
        contains('class UserHelper(private val databaseName: String) {'),
      );
      expect(code, contains('fun insert(entity: User): Long {'));
      expect(code, contains('fun findById(id: Long): User? {'));
      expect(code, contains('fun update(entity: User): Int {'));
      expect(code, contains('fun delete(id: Long): Int {'));
      expect(code, isNot(contains('getInstance(')));
      expect(code, isNot(contains('cleanupIsolate')));
      expect(code, isNot(contains('ConcurrentHashMap')));
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
      expect(code, contains('import java.util.UUID'));
      expect(code, contains('fun insert(entity: Note): String {'));
      expect(
        code,
        contains(
          'val primaryKeyValue = entity.id ?: UUID.randomUUID().toString()',
        ),
      );
      expect(code, contains('NoteSchema.ID to primaryKeyValue'));
      expect(code, contains('return primaryKeyValue'));
      expect(
        code,
        contains('fun insertBatch(entities: List<Note>): List<String>'),
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
