# Code Generation Guide for Native SQLite

This guide explains how to use the code generation features of native_sqlite to automatically create table schemas and repository classes from annotated Dart classes.

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Quick Start](#quick-start)
- [Annotations Reference](#annotations-reference)
- [Generated Code](#generated-code)
- [Advanced Usage](#advanced-usage)
- [Best Practices](#best-practices)
- [Migration Guide](#migration-guide)

## Overview

The native_sqlite code generation system consists of three packages:

1. **native_sqlite_annotation**: Provides annotations like `@Table`, `@Column`, `@PrimaryKey`
2. **native_sqlite_generator**: The build_runner generator that processes annotations
3. **native_sqlite**: The main package with the runtime API

### Benefits

- **Type Safety**: Compile-time checking of your database schema
- **Reduced Boilerplate**: Auto-generate CRUD operations
- **Easy Refactoring**: Rename fields and let the generator update SQL
- **Better Documentation**: Schema is defined in code, not SQL strings
- **IDE Support**: Full autocomplete and navigation

## Setup

### 1. Add Dependencies

In your `pubspec.yaml`:

```yaml
dependencies:
  native_sqlite:
    path: ../native_sqlite
  native_sqlite_annotation:
    path: ../native_sqlite_annotation

dev_dependencies:
  build_runner: ^2.4.13
  native_sqlite_generator:
    path: ../native_sqlite_generator
```

### 2. Create Build Configuration (Optional)

Create `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      native_sqlite_generator|table:
        enabled: true
        generate_for:
          - lib/models/*.dart
```

## Quick Start

### Step 1: Define Your Model

Create a model class with annotations:

```dart
// lib/models/user.dart
import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'user.table.g.dart';  // This file will be generated

@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(unique: true)
  final String email;

  @Column()
  final DateTime createdAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
}
```

### Step 2: Generate Code

Run the build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs

# Or use watch mode during development:
dart run build_runner watch --delete-conflicting-outputs
```

### Step 3: Use Generated Code

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'models/user.dart';

Future<void> main() async {
  // Open database with generated schema
  await NativeSqlite.open(
    config: DatabaseConfig(
      name: 'my_app',
      version: 1,
      onCreate: [
        UserSchema.createTableSql,  // Generated constant
      ],
    ),
  );

  // Create repository
  final userRepo = UserRepository('my_app');

  // Insert
  final userId = await userRepo.insert(User(
    name: 'John Doe',
    email: 'john@example.com',
    createdAt: DateTime.now(),
  ));

  // Query
  final user = await userRepo.findById(userId);
  print('User: ${user?.name}');

  // Find all
  final users = await userRepo.findAll();
  print('Total users: ${users.length}');

  // Update
  if (user != null) {
    await userRepo.update(user.copyWith(name: 'Jane Doe'));
  }

  // Delete
  await userRepo.delete(userId);
}
```

## Annotations Reference

### @Table

Marks a class as a database table.

```dart
@Table(
  name: 'custom_table_name',  // Optional: defaults to snake_case class name
  indexes: [
    ['column1'],           // Single column index
    ['col1', 'col2'],     // Composite index
  ],
)
class MyModel { }
```

**Parameters:**
- `name` (String?): Custom table name. Defaults to snake_case of class name.
- `indexes` (List<List<String>>?): List of indexes to create.

### @PrimaryKey

Marks a field as the primary key.

```dart
@PrimaryKey(autoIncrement: true)  // or false
final int? id;
```

**Parameters:**
- `autoIncrement` (bool): Whether the key should auto-increment. Default: false.

**Best Practices:**
- Use `int?` type for auto-increment primary keys
- Use `int` or other non-nullable type for manual primary keys

### @Column

Marks a field as a database column.

```dart
@Column(
  name: 'custom_column_name',
  nullable: true,
  unique: true,
  defaultValue: '0',
  type: 'TEXT',
)
final String? field;
```

**Parameters:**
- `name` (String?): Custom column name. Defaults to field name.
- `nullable` (bool?): Whether the column is nullable. Inferred from Dart type if not specified.
- `unique` (bool): Whether to add UNIQUE constraint. Default: false.
- `defaultValue` (String?): SQL default value expression.
- `type` (String?): Explicit SQLite type. Inferred from Dart type if not specified.

### @ForeignKey

Defines a foreign key relationship.

```dart
@Column()
@ForeignKey(
  table: 'users',
  column: 'id',
  onDelete: 'CASCADE',
  onUpdate: 'CASCADE',
)
final int userId;
```

**Parameters:**
- `table` (String): Referenced table name.
- `column` (String): Referenced column name.
- `onDelete` (String?): Action on delete. Options: 'CASCADE', 'SET NULL', 'RESTRICT', 'NO ACTION'.
- `onUpdate` (String?): Action on update. Same options as onDelete.

### @Index

Creates an index on specific columns (class-level annotation).

```dart
@Table()
@Index(
  name: 'idx_custom',
  columns: ['email', 'createdAt'],
  unique: true,
)
class User { }
```

**Parameters:**
- `name` (String?): Index name. Auto-generated if not provided.
- `columns` (List<String>): Columns to include in the index.
- `unique` (bool): Whether the index enforces uniqueness. Default: false.

### @Ignore

Excludes a field from code generation.

```dart
@Ignore()
final String computedValue;  // Not stored in database
```

## Generated Code

For each `@Table` annotated class, two artifacts are generated:

### 1. Schema Class

Contains the table definition and column constants:

```dart
abstract class UserSchema {
  // Table name constant
  static const String tableName = 'users';

  // CREATE TABLE SQL
  static const String createTableSql = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL
    )
  ''';

  // Index SQL (if any)
  static const List<String> indexSql = [
    'CREATE INDEX idx_users_email ON users (email)',
  ];

  // Column name constants
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email';
  static const String CREATED_AT = 'created_at';
}
```

### 2. Repository Class

Type-safe CRUD operations:

```dart
class UserRepository {
  final String databaseName;

  const UserRepository(this.databaseName);

  /// Insert a new user
  Future<int> insert(User entity);

  /// Find user by ID
  Future<User?> findById(int id);

  /// Find all users
  Future<List<User>> findAll();

  /// Update existing user
  Future<int> update(User entity);

  /// Delete user by ID
  Future<int> delete(int id);

  /// Delete all users
  Future<int> deleteAll();

  /// Count total users
  Future<int> count();

  /// Custom query
  Future<List<User>> query(String sql, [List<Object?>? arguments]);
}
```

## Advanced Usage

### Multiple Tables with Relationships

```dart
// User model
@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  const User({this.id, required this.name});
}

// Post model with foreign key
@Table(name: 'posts')
class Post {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String title;

  @Column()
  @ForeignKey(table: 'users', column: 'id', onDelete: 'CASCADE')
  final int userId;

  const Post({this.id, required this.title, required this.userId});
}

// Usage
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'app_db',
    version: 1,
    onCreate: [
      UserSchema.createTableSql,
      PostSchema.createTableSql,
    ],
    enableForeignKeys: true,  // Required for foreign keys!
  ),
);
```

### Composite Indexes

```dart
@Table(name: 'products')
@Index(columns: ['category', 'price'])
@Index(columns: ['sku'], unique: true)
class Product {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String category;

  @Column()
  final double price;

  @Column(unique: true)
  final String sku;

  const Product({
    this.id,
    required this.category,
    required this.price,
    required this.sku,
  });
}
```

### Custom Queries

```dart
// Using the repository's query method
final expensiveProducts = await productRepo.query(
  'SELECT * FROM ${ProductSchema.tableName} WHERE ${ProductSchema.PRICE} > ? ORDER BY ${ProductSchema.PRICE} DESC',
  [100.0],
);

// Using raw NativeSqlite API
final result = await NativeSqlite.query(
  'app_db',
  'SELECT category, COUNT(*) as count FROM products GROUP BY category',
);
```

### Type Conversions

The generator automatically handles type conversions:

| Dart Type | SQLite Type | Conversion |
|-----------|-------------|------------|
| `int` | INTEGER | Direct |
| `double` | REAL | Direct |
| `String` | TEXT | Direct |
| `bool` | INTEGER | true → 1, false → 0 |
| `DateTime` | INTEGER | Milliseconds since epoch |
| `Uint8List` | BLOB | Direct |

Example with DateTime:

```dart
@Table()
class Event {
  @Column()
  final DateTime startTime;  // Stored as INTEGER milliseconds

  @Column(nullable: true)
  final DateTime? endTime;   // Nullable DateTime
}

// The generated code handles conversion:
// INSERT: entity.startTime.millisecondsSinceEpoch
// SELECT: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int)
```

## Best Practices

### 1. Use Part Files

Always use the `part` directive:

```dart
part 'user.table.g.dart';
```

This makes the generated code part of your model file.

### 2. Const Constructors

Use `const` constructors when possible:

```dart
const User({required this.name, required this.email});
```

This improves performance and allows compile-time constants.

### 3. CopyWith Pattern

Implement `copyWith` for easier updates:

```dart
User copyWith({String? name, String? email}) {
  return User(
    id: this.id,
    name: name ?? this.name,
    email: email ?? this.email,
  );
}

// Usage
final updatedUser = user.copyWith(name: 'New Name');
await userRepo.update(updatedUser);
```

### 4. Nullable Primary Keys

Use nullable types for auto-increment primary keys:

```dart
@PrimaryKey(autoIncrement: true)
final int? id;  // Nullable because it's auto-generated
```

### 5. Schema Versioning

When changing the schema:

```dart
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'app_db',
    version: 2,  // Increment version
    onCreate: [
      UserSchema.createTableSql,
    ],
    onUpgrade: [
      'ALTER TABLE users ADD COLUMN phone TEXT',
    ],
  ),
);
```

### 6. Separate Model Files

Keep one model per file for better organization:

```
lib/
  models/
    user.dart
    user.table.g.dart
    post.dart
    post.table.g.dart
    comment.dart
    comment.table.g.dart
```

## Migration Guide

### From Manual SQL to Code Generation

**Before:**

```dart
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'db',
    version: 1,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE
      )
      ''',
    ],
  ),
);

final id = await NativeSqlite.insert('db', 'users', {
  'name': 'John',
  'email': 'john@example.com',
});

final result = await NativeSqlite.query('db', 'SELECT * FROM users WHERE id = ?', [id]);
final user = result.toMapList().first;
```

**After:**

```dart
// 1. Create model
@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(unique: true)
  final String email;

  const User({this.id, required this.name, required this.email});
}

// 2. Generate code
// dart run build_runner build

// 3. Use type-safe API
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'db',
    version: 1,
    onCreate: [UserSchema.createTableSql],
  ),
);

final userRepo = UserRepository('db');
final id = await userRepo.insert(User(name: 'John', email: 'john@example.com'));
final user = await userRepo.findById(id);
```

## Troubleshooting

### Build Runner Issues

**Problem**: Generated files not updating

```bash
# Clean and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Problem**: Conflicts with existing files

```bash
# Use --delete-conflicting-outputs flag
dart run build_runner build --delete-conflicting-outputs
```

### Type Errors

**Problem**: "The argument type 'X' can't be assigned to 'Y'"

Make sure your model class constructor parameters match the field types and nullability.

### Import Errors

**Problem**: "Undefined name 'NativeSqlite'"

The generator automatically adds the import. Make sure you've run `build_runner`.

## Summary

Code generation in native_sqlite provides:

1. **Type safety** at compile time
2. **Less boilerplate** code
3. **Better refactoring** support
4. **Consistent APIs** across your app
5. **Self-documenting** schema

Start with simple models, run the generator, and let it handle the tedious SQL generation!

For more examples, see the [example](example/) directory.
