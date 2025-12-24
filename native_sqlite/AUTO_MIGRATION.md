# Auto Migration Feature

The Native SQLite plugin includes built-in automatic database creation and migration support.

## Quick Start

1. **Add `@DbTable` annotations to your models:**

```dart
import 'package:native_sqlite/native_sqlite.dart';

part 'user.table.dart';

@DbTable(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @DbColumn(nullable: false)
  final String name;
  
  User({this.id, required this.name});
}
```

2. **Create a trigger file** `lib/database_schema.dart`:

```dart
// This file triggers the schema registry generator.
// Do not delete this file!
```

3. **Run code generation:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Use auto-migration in your app:**

```dart
import 'package:native_sqlite/native_sqlite.dart';
import 'database_schema.schema_registry.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NativeSqlite.open(
    config: DatabaseSchemaRegistry.createAutoMigratedConfig(
      name: 'my_database',
    ),
  );
  
  runApp(MyApp());
}
```

## Features

- ✅ **Automatic table creation** from annotated models
- ✅ **Schema version tracking** via content hashing
- ✅ **Auto-migration** when schema changes
- ✅ **Foreign key dependency ordering**
- ✅ **Custom migration hooks**
- ✅ **Optional table cleanup** (drop removed tables)

## Generated Registry

The generator creates a `DatabaseSchemaRegistry` with:

- `schemaVersion`: Hash-based version number
- `tables`: Map of table names to CREATE SQL
- `tableNames`: List of all tables
- `onCreateStatements`: Ordered creation SQL (respects dependencies)
- `createAutoMigratedConfig()`: Helper to create config with auto-migration

## Custom Migrations

Add custom logic for specific schema changes:

```dart
await NativeSqlite.open(
  config: DatabaseSchemaRegistry.createAutoMigratedConfig(
    name: 'my_database',
    onCustomMigrate: (databaseName, oldVersion, newVersion) async {
      if (oldVersion < 456789) {
        await NativeSqlite.execute(
          databaseName,
          'ALTER TABLE users ADD COLUMN avatar TEXT',
        );
      }
    },
  ),
);
```

## How It Works

1. Generator scans for `@DbTable` classes
2. Calculates schema version from table definitions
3. Orders tables by foreign key dependencies
4. Generates `DatabaseSchemaRegistry`
5. Plugin's `AutoMigration` class handles:
   - Initial creation (onCreate)
   - Schema detection (version changes)
   - Table creation/updates (onUpgrade)
   - Custom migrations (callbacks)

## Documentation

See [AUTO_MIGRATION.md](../docs/AUTO_MIGRATION.md) for complete guide.

## Plugin Architecture

- **native_sqlite**: Core plugin with `AutoMigration` utility
- **native_sqlite_generator**: Generates schema registries
- **native_sqlite_platform_interface**: Platform-agnostic interfaces
- **Example app**: Demonstrates usage

All auto-migration logic is in the plugin - no need for app-level helpers!
