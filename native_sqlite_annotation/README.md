# Native SQLite Annotation

Annotations for code generation with `native_sqlite_generator`.

## Usage

Add annotations to your model classes:

```dart
import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

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

  const User({
    this.id,
    required this.name,
    required this.email,
    this.age,
  });
}
```

Then run the code generator to create table schemas and repositories.

See `native_sqlite_generator` for code generation setup.
