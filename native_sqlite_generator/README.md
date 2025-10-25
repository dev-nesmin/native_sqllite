# Native SQLite Generator

Code generator for `native_sqlite` that creates table schemas and repository classes from annotated Dart classes.

## Features

- **Automatic Table Generation**: Generate SQLite table schemas from Dart classes
- **Type-Safe Repositories**: Auto-generated repository classes with CRUD operations
- **Type Conversion**: Automatic conversion between Dart types and SQLite types
- **Null Safety**: Full null-safety support
- **Foreign Keys**: Support for foreign key relationships
- **Indexes**: Support for creating indexes
- **Custom Queries**: Execute custom SQL queries with type-safe results

## Installation

Add to your `pubspec.yaml`:

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

## Usage

### 1. Annotate your model classes

```dart
import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'user.table.g.dart'; // Generated file

@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(name: 'email_address', unique: true)
  final String email;

  @Column(nullable: true)
  final int? age;

  @Column()
  final DateTime createdAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    this.age,
    required this.createdAt,
  });
}
```

### 2. Run the code generator

```bash
dart run build_runner build
# or for watch mode
dart run build_runner watch
```

### 3. Use the generated code

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'user.dart';

Future<void> example() async {
  // Open database with generated schema
  await NativeSqlite.open(
    config: DatabaseConfig(
      name: 'my_app',
      version: 1,
      onCreate: [
        UserSchema.createTableSql,
        // Add other table schemas here
      ],
    ),
  );

  // Create a repository
  final userRepo = UserRepository('my_app');

  // Insert a user
  final userId = await userRepo.insert(User(
    name: 'John Doe',
    email: 'john@example.com',
    age: 30,
    createdAt: DateTime.now(),
  ));

  // Find by ID
  final user = await userRepo.findById(userId);
  print('Found user: ${user?.name}');

  // Find all users
  final allUsers = await userRepo.findAll();
  print('Total users: ${allUsers.length}');

  // Update user
  if (user != null) {
    final updatedUser = User(
      id: user.id,
      name: 'Jane Doe',
      email: user.email,
      age: user.age,
      createdAt: user.createdAt,
    );
    await userRepo.update(updatedUser);
  }

  // Custom query
  final adults = await userRepo.query(
    'SELECT * FROM ${UserSchema.tableName} WHERE age >= ?',
    [18],
  );

  // Delete user
  await userRepo.delete(userId);

  // Count users
  final count = await userRepo.count();
  print('Users remaining: $count');
}
```

## Annotations

### @Table

Marks a class as a database table.

```dart
@Table(
  name: 'custom_table_name', // Optional: defaults to snake_case of class name
  indexes: [
    ['column1', 'column2'], // Composite index
  ],
)
class MyTable { }
```

### @PrimaryKey

Marks a field as the primary key.

```dart
@PrimaryKey(autoIncrement: true) // autoIncrement is optional (default: false)
final int? id;
```

### @Column

Marks a field as a database column.

```dart
@Column(
  name: 'custom_column_name', // Optional: defaults to field name
  nullable: true, // Optional: inferred from Dart type
  unique: true, // Optional: adds UNIQUE constraint
  defaultValue: '0', // Optional: SQL default value
  type: 'TEXT', // Optional: explicit SQLite type
)
final String? field;
```

### @ForeignKey

Defines a foreign key relationship.

```dart
@Column()
@ForeignKey(
  table: 'users',
  column: 'id',
  onDelete: 'CASCADE', // Optional
  onUpdate: 'CASCADE', // Optional
)
final int userId;
```

### @Index

Creates an index on the table (use at class level).

```dart
@Table()
@Index(
  name: 'idx_custom', // Optional: auto-generated if not provided
  columns: ['email', 'createdAt'],
  unique: true, // Optional: default false
)
class User { }
```

### @Ignore

Ignores a field during code generation.

```dart
@Ignore()
final String temporaryData; // Won't be stored in database
```

## Type Mapping

| Dart Type | SQLite Type | Notes |
|-----------|-------------|-------|
| `int` | `INTEGER` | |
| `double` | `REAL` | |
| `String` | `TEXT` | |
| `bool` | `INTEGER` | Stored as 0 or 1 |
| `DateTime` | `INTEGER` | Stored as milliseconds since epoch |
| `Uint8List` | `BLOB` | |
| Custom types | `TEXT` | Requires manual serialization |

## Generated Code

For each `@Table` annotated class, the generator creates:

### 1. Schema Class

```dart
abstract class UserSchema {
  static const String tableName = 'users';
  static const String createTableSql = '''...''';

  // Column name constants
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email';
}
```

### 2. Repository Class

```dart
class UserRepository {
  final String databaseName;

  // CRUD methods
  Future<int> insert(User entity);
  Future<User?> findById(int id);
  Future<List<User>> findAll();
  Future<int> update(User entity);
  Future<int> delete(int id);
  Future<int> deleteAll();
  Future<int> count();
  Future<List<User>> query(String sql, [List<Object?>? arguments]);
}
```

## Advanced Examples

### Multiple Tables with Relationships

```dart
@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  const User({this.id, required this.name});
}

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
    name: 'blog_db',
    version: 1,
    onCreate: [
      UserSchema.createTableSql,
      PostSchema.createTableSql,
    ],
    enableForeignKeys: true,
  ),
);
```

### Custom Indexes

```dart
@Table(name: 'products')
@Index(columns: ['category', 'price'])
@Index(name: 'idx_sku', columns: ['sku'], unique: true)
class Product {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column()
  final String category;

  @Column()
  final double price;

  @Column(unique: true)
  final String sku;

  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.sku,
  });
}
```

## Tips

1. **Always use `part` directive**: Include `part 'filename.table.g.dart';` in your model file
2. **Nullable primary keys**: Use `int?` for auto-increment primary keys
3. **Const constructors**: Use `const` constructors when possible for better performance
4. **Run build_runner**: Remember to run `dart run build_runner build` after changing annotations
5. **Database migrations**: Increment the version number and provide `onUpgrade` SQL when schema changes

## License

Part of the native_sqlite package.
