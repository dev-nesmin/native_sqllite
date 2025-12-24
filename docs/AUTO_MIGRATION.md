# Automatic Database Creation and Migration

This guide explains how Native SQLite's built-in automatic table creation and migration system works.

## Overview

The **native_sqlite** plugin automatically:
- Creates all tables from `@DbTable` annotated classes
- Detects schema changes via version hashing
- Migrates database when schema changes
- Handles table dependencies (foreign keys)
- Provides hooks for custom migration logic

## How It Works

### 1. Database Manager Generation

The `SchemaRegistryGenerator` (from native_sqlite_generator) scans your project for all `@DbTable` annotated classes and generates:

- **`DatabaseManager`**: Central manager for all database operations
- **`schemaVersion`**: Hash-based version number
- **`onCreateStatements`**: Ordered list of CREATE TABLE SQL
- **`tableNames`**: List of all table names
- **Lifecycle methods**: `init()`, `close()`, `createTables()`, etc.

**Note**: The generated file `database_schema.database_manager.g.dart` is in `.gitignore` - users should not edit it.

### 2. Dependency Ordering

Tables are automatically ordered by foreign key dependencies using topological sorting:
- Parent tables are created before child tables
- Prevents foreign key constraint errors

### 3. Schema Versioning

Schema version is calculated from:
- All table names
- Column definitions
- Foreign keys
- Indexes

When you modify a model:
1. Run `flutter pub run build_runner build --delete-conflicting-outputs`
2. Schema version automatically changes
3. Next app launch triggers migration

### 4. Automatic Migration

The `DatabaseManager` handles migration automatically:

```dart
await DatabaseManager.init(
  name: 'my_database',
  enableWAL: true,
  enableForeignKeys: true,
  dropRemovedTables: false,
  onCustomMigrate: (databaseName, oldVersion, newVersion) async {
    // Custom migration logic here
  },
);
```

Migration process:
1. Detects version change
2. Opens database
3. Compares existing tables vs schema registry
4. Creates new tables
5. Optionally drops removed tables
6. Calls custom migration callback
7. Records migration in history

## Usage Examples

### Basic Setup (main.dart)

```dart
import 'package:flutter/material.dart';
import 'database_schema.database_manager.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database - everything handled automatically!
  await DatabaseManager.init();
  
  runApp(MyApp());
}
```

### With Custom Settings

```dart
await DatabaseManager.init(
  name: 'my_database',  // Default: 'app_database'
  enableWAL: true,       // Write-Ahead Logging
  enableForeignKeys: true,
  dropRemovedTables: false,  // Set true to auto-drop removed tables
);
```

### With Custom Migration

```dart
await DatabaseManager.init(
  name: 'my_database',
  onCustomMigrate: (databaseName, oldVersion, newVersion) async {
    // Add custom migration logic based on version
    if (oldVersion < 123456 && newVersion >= 123456) {
        // Migration for specific schema change
        await NativeSqlite.execute(
          databaseName,
          'ALTER TABLE users ADD COLUMN avatar TEXT',
        );
      }
    },
  ),
);
```

### Drop Removed Tables

```dart
await NativeSqlite.open(
  config: DatabaseSchemaRegistry.createAutoMigratedConfig(
    name: 'my_database',
    dropRemovedTables: true, // ⚠️ Use with caution
  ),
);
```

## Adding a New Table

1. Create your model:

```dart
// lib/models/tag.dart
import 'package:native_sqlite/native_sqlite.dart';

part 'tag.table.dart';

@DbTable(name: 'tags')
class Tag {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @DbColumn(nullable: false)
  final String name;
  
  Tag({this.id, required this.name});
}
```

2. Run code generation:

```bash
cd example
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Restart app - table is automatically created!

## Modifying Existing Tables

### Adding a Column

Since SQLite has limited ALTER TABLE support, handle this in custom migration:

```dart
await DatabaseInitializer.initialize(
  onMigrate: (databaseName, oldVersion, newVersion) async {
    if (oldVersion < 654321) {
      await NativeSqlite.execute(
        databaseName,
        'ALTER TABLE users ADD COLUMN avatar TEXT',
      );
    }
  },
);
```

### Renaming/Restructuring Columns

For complex changes, use the table recreation pattern:

```dart
if (oldVersion < 789012) {
  await NativeSqlite.transaction('example_app', [
    // 1. Create new table with updated schema
    'CREATE TABLE users_new (id INTEGER PRIMARY KEY, name TEXT, email TEXT UNIQUE)',
    
    // 2. Copy data from old table
    'INSERT INTO users_new (id, name, email) SELECT id, name, email FROM users',
    
    // 3. Drop old table
    'DROP TABLE users',
    
    // 4. Rename new table
    'ALTER TABLE users_new RENAME TO users',
  ]);
}
```

## Schema Registry API

### Properties

- **`schemaVersion`**: `int` - Current schema version hash
- **`tables`**: `Map<String, String>` - Table name → CREATE SQL
- **`tableNames`**: `List<String>` - All table names
- **`onCreateStatements`**: `List<String>` - Full creation SQL

### Methods

- **`migrate()`**: Auto-migrate database
  ```dart
  await DatabaseSchemaRegistry.migrate(
    db: database,
    oldVersion: oldVersion,
    newVersion: newVersion,
    dropRemovedTables: false,
  );
  ```

## Migration Tracking

The system creates a `__schema_version__` table:

| Column      | Type    | Description                    |
|-------------|---------|--------------------------------|
| id          | INTEGER | Auto-increment primary key     |
| version     | INTEGER | Schema version                 |
| created_at  | INTEGER | Migration timestamp (epoch ms) |

Each migration is recorded with timestamp for audit trail.

## Best Practices

### ✅ DO

- Run build_runner after every model change
- Use version checks in custom migrations
- Test migrations with old database files
- Keep migration history in version control
- Use transactions for complex migrations

### ❌ DON'T

- Manually edit `.table.dart` or `.schema_registry.g.dart`
- Remove models without handling data migration
- Rely only on DROP/CREATE for live databases
- Skip testing migrations on production-like data

## Troubleshooting

### Schema Version Not Changing

- Ensure you ran build_runner
- Check that model changes are saved
- Verify `@DbTable` annotation is present

### Migration Not Running

- Check old version was stored correctly
- Verify database exists before migration
- Look for errors in `onMigrate` callback

### Foreign Key Errors

- Ensure `enableForeignKeys: true`
- Check parent tables are created first
- Verify foreign key references exist

### Tables Not Created

- Check for build_runner errors
- Verify table is in `DatabaseSchemaRegistry.tableNames`
- Ensure `onCreate` statements are valid SQL

## Testing Migrations

```dart
// test/migration_test.dart
void main() {
  test('Migration from v1 to v2', () async {
    // Create v1 database
    await NativeSqlite.open(
      config: DatabaseConfig(
        name: 'test_db',
        version: 1,
        onCreate: [/* old schema */],
      ),
    );
    
    // Insert test data
    await NativeSqlite.insert('test_db', 'users', {...});
    
    await NativeSqlite.close('test_db');
    
    // Migrate to v2
    await DatabaseInitializer.initialize();
    
    // Verify data preserved and new tables exist
    final result = await NativeSqlite.query('test_db', 'SELECT * FROM users');
    expect(result.toMapList(), isNotEmpty);
  });
}
```

## Advanced: Manual Schema Version

Override schema version calculation:

```dart
// In your generator options (build.yaml)
targets:
  $default:
    builders:
      native_sqlite_generator:table:
        options:
          schema_version: 2  # Manual version
```

Then increment manually when needed.

## Summary

The automatic creation and migration system:
- 🚀 Saves time - no manual SQL writing
- 🔒 Type-safe - all schemas from code
- 📊 Tracked - complete migration history
- 🔄 Flexible - custom migration hooks
- ⚡ Fast - optimized dependency ordering

Just run build_runner, and your database stays in sync! 🎉
