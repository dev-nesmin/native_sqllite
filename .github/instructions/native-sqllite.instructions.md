---
applyTo: '**'
---

# Native SQLite Project - GitHub Copilot Instructions

## Project Overview

This is a Flutter plugin monorepo for Native SQLite with code generation. It provides type-safe SQLite database access across Android, iOS, and Web platforms with a real-time database inspector.

**Key characteristics:**
- Code-generation heavy project using build_runner
- Federated plugin architecture (platform-specific implementations)
- Sound null safety
- Flutter >=3.35.0, Dart >=3.9.0

## Project Structure

```
native_sqllite/
├── native_sqlite/                    # Main plugin (federated root)
├── native_sqlite_android/            # Android platform implementation
├── native_sqlite_ios/                # iOS platform implementation  
├── native_sqlite_web/                # Web platform implementation
├── native_sqlite_platform_interface/ # Platform interface contracts
├── native_sqlite_annotations/        # Annotations (@DbTable, @PrimaryKey, etc.)
├── native_sqlite_generator/          # build_runner code generator
├── native_sqlite_inspector/          # Web-based DevTools extension
└── example/                          # Comprehensive example app
```

## Critical Rules - ALWAYS Follow These

### 1. Code Generation Workflow (MANDATORY)

**Every time you modify a `@DbTable` class:**

1. Edit the Dart model with `@DbTable` annotation
2. Ensure `part 'filename.table.dart';` directive exists
3. Run: `flutter pub run build_runner build --delete-conflicting-outputs`
4. **NEVER** manually create or edit `.table.dart` files
5. Generated files contain `Schema` classes with SQL and CRUD methods

**Use these tools:**
- `dart_format` for formatting Dart code
- `run_in_terminal` for build_runner commands
- `mcp_dart_sdk_mcp__dart_format` when available

### 2. Database Model Pattern (REQUIRED FORMAT)

```dart
import 'package:native_sqlite/native_sqlite.dart';

part 'classname.table.dart'; // REQUIRED

@DbTable(
  name: 'table_name',
  indexes: [['column1'], ['column2', 'column3']], // Optional
  foreignKeys: [/* ... */], // Optional
)
class ClassName {
  @PrimaryKey(autoIncrement: true)
  final int? id; // MUST be nullable for auto-increment
  
  @DbColumn(nullable: false) // Always be explicit
  final String requiredField;
  
  @DbColumn(nullable: true)
  final String? optionalField;
  
  @DbColumn(nullable: false, defaultValue: '0')
  final int fieldWithDefault;
  
  @Ignore() // Not persisted to DB
  String? transientField;
  
  // Constructor
  ClassName({
    this.id,
    required this.requiredField,
    this.optionalField,
    this.fieldWithDefault = 0,
  });
  
  // ALWAYS include copyWith for updates
  ClassName copyWith({/* ... */}) => ClassName(/* ... */);
  
  // toString for debugging
  @override
  String toString() => 'ClassName{...}';
}
```

### 3. Foreign Keys Pattern

```dart
@DbTable(
  name: 'orders',
  foreignKeys: [
    ForeignKey(
      columns: ['userId'],
      referencedTable: 'users',
      referencedColumns: ['id'],
      onDelete: 'CASCADE', // or 'SET NULL', 'RESTRICT', 'NO ACTION'
      onUpdate: 'CASCADE',
    ),
  ],
)
```

### 4. Database Initialization (MANDATORY IN main())

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NativeSqlite.open(
    config: DatabaseConfig(
      name: 'database_name',
      version: 1,
      onCreate: [
        // Order matters! Parent tables before child tables
        UserSchema.createTableSql,
        CategorySchema.createTableSql,
        ProductSchema.createTableSql,
        OrderSchema.createTableSql,
        
        // Then indexes
        ...UserSchema.indexSql,
        ...ProductSchema.indexSql,
      ],
      onUpgrade: [
        // if (oldVersion < 2) 'ALTER TABLE users ADD COLUMN avatar TEXT',
      ],
      enableWAL: true,           // ALWAYS enable
      enableForeignKeys: true,   // ALWAYS enable if using FKs
    ),
  );
  
  runApp(MyApp());
}
```

### 5. CRUD Operations (Use Generated Methods)

```dart
// Insert
final id = await UserSchema.insert(user);

// Query all
final users = await UserSchema.queryAll();

// Query with filter
final results = await UserSchema.query(
  where: 'email LIKE ? AND age > ?',
  whereArgs: ['%@example.com', 18],
  orderBy: 'createdAt DESC',
  limit: 10,
);

// Query by ID
final user = await UserSchema.queryById(id);

// Update
await UserSchema.update(updatedUser);

// Delete
await UserSchema.delete(id);

// Raw query (if needed)
final db = await NativeSqlite.database;
final results = await db.rawQuery('SELECT * FROM users WHERE ...');
```

## Common Mistakes - AVOID THESE

❌ **DON'T:**
- Create `.table.dart` files manually
- Edit generated files
- Forget to run build_runner after model changes
- Use `int` (non-nullable) for auto-increment primary keys
- Initialize database after `runApp()`
- Forget `enableWAL: true`
- Skip `enableForeignKeys: true` when using foreign keys
- Create child tables before parent tables in `onCreate`
- Use string interpolation in SQL queries (SQL injection risk)

✅ **DO:**
- Use `int?` for auto-increment primary keys
- Run build_runner after ANY model change
- Initialize database in `main()` BEFORE `runApp()`
- Enable WAL mode for concurrent access
- Order tables by dependencies (parent → child)
- Use `copyWith` methods for updates
- Add indexes for frequently queried columns
- Use transactions for bulk operations
- Use prepared statements (generated queries do this automatically)

## File Naming Conventions

- Models: `snake_case.dart` (e.g., `user.dart`, `order_item.dart`)
- Generated: `snake_case.table.dart` (auto-generated, never create manually)
- Screens: `snake_case_screen.dart` (e.g., `home_screen.dart`)
- Widgets: `snake_case_widget.dart` (e.g., `user_list_widget.dart`)
- Tests: `*_test.dart`

## Import Organization

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Package imports
import 'package:native_sqlite/native_sqlite.dart';

// 4. Relative imports
import '../models/user.dart';
import 'widgets/user_card.dart';

// 5. Part directives (LAST)
part 'user.table.dart';
```

## Performance Best Practices

```dart
// ✅ Use transactions for bulk operations
await NativeSqlite.transaction((txn) async {
  for (var user in users) {
    await UserSchema.insert(user, db: txn);
  }
});

// ✅ Add indexes for frequently queried columns
@DbTable(
  name: 'users',
  indexes: [['email'], ['createdAt']],
)

// ✅ Enable WAL mode
DatabaseConfig(enableWAL: true)

// ✅ Use prepared statements (generated queries do this)
await UserSchema.query(where: 'id = ?', whereArgs: [id]);
```

## Migration Strategy

When schema changes are needed:

```dart
DatabaseConfig(
  version: 2, // Increment version
  onUpgrade: [
    'ALTER TABLE users ADD COLUMN avatar TEXT',
    'CREATE INDEX idx_users_avatar ON users(avatar)',
  ],
)
```

## Dependency Management

```bash
# Install dependencies for all packages
./flutter_manager.sh get

# Or manually per package
cd native_sqlite && flutter pub get
```

## Platform-Specific Code

- **Android**: `native_sqlite_android/android/src/`
- **iOS**: `native_sqlite_ios/ios/Classes/`
- **Web**: `native_sqlite_web/lib/`
- **Interface**: `native_sqlite_platform_interface/` (update first)

**Never break the platform interface contract.**

## Testing Checklist

Before considering code complete:

- [ ] Run code generation successfully
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] Database initializes without errors
- [ ] CRUD operations work correctly
- [ ] Foreign keys validate (if used)
- [ ] Migrations tested (if schema changed)
- [ ] Example app demonstrates changes

## Typical Workflows

### Adding a New Model

1. Create `lib/models/new_model.dart` in example app
2. Add `@DbTable` annotation and fields
3. Add `part 'new_model.table.dart';`
4. Run: `cd example && flutter pub run build_runner build --delete-conflicting-outputs`
5. Add to database initialization in `main.dart`
6. Create demo UI in example app

### Modifying Existing Model

1. Edit model file
2. If adding/removing fields: increment version, add migration
3. Run: `flutter pub run build_runner build --delete-conflicting-outputs`
4. Test in example app

### Fixing Generator Issues

1. Check `native_sqlite_generator/lib/src/`
2. Modify generator code
3. Test: `cd native_sqlite_generator && flutter test`
4. Regenerate: `cd example && flutter pub run build_runner build --delete-conflicting-outputs`
5. Verify generated code

## Special Considerations

### Freezed Integration

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:native_sqlite/native_sqlite.dart';

part 'model.freezed.dart';
part 'model.table.dart';

@freezed
@DbTable(name: 'table_name')
class Model with _$Model {
  const factory Model({
    @PrimaryKey(autoIncrement: true) int? id,
    required String field,
  }) = _Model;
}
```

### DateTime Handling

- Stored as INTEGER (milliseconds since epoch)
- Automatically converted to/from `DateTime`
- Use `DateTime.now()` for defaults

### Null Safety

- Project uses sound null safety
- Be explicit: `nullable: true/false` in `@DbColumn`
- Auto-increment IDs MUST be nullable: `int?`

## When User Asks To...

### "Add a table/model"
1. Create model in `example/lib/models/`
2. Add annotations with `part` directive
3. Run build_runner
4. Update database initialization
5. Create demo UI

### "Fix database issue"
1. Check initialization order
2. Verify foreign key ordering
3. Check for migration issues
4. Enable debug logging
5. Test with fresh install

### "Update generator"
1. Edit `native_sqlite_generator/lib/src/`
2. Run generator tests
3. Test with example app
4. Verify all model types work

### "Add platform support"
1. Implement in platform package
2. Update platform interface if needed
3. Test on actual device
4. Update example app

### "Improve performance"
1. Add indexes to frequently queried columns
2. Use transactions for bulk operations
3. Ensure WAL mode enabled
4. Optimize query patterns

## Resources

- Example models: `example/lib/models/`
- Database init: `example/lib/main.dart`
- Generator: `native_sqlite_generator/lib/src/`
- Inspector: `native_sqlite_inspector/`
- Platform interface: `native_sqlite_platform_interface/`

## Helper Script Commands

```bash
./flutter_manager.sh get      # Get deps for all packages
./flutter_manager.sh build    # Run build_runner for all
./flutter_manager.sh watch    # Watch mode
./flutter_manager.sh clean    # Clean artifacts
./flutter_manager.sh run "cmd" # Run custom command
```

---

**Remember**: This is a code-generation-heavy project. Always look at existing models in `example/lib/models/` and follow the same patterns. Always run build_runner after model changes!