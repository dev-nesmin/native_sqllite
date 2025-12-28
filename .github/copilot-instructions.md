# Native SQLite - AI Agent Instructions

## Project Overview

Native SQLite is a code-generation based Flutter/Dart SQLite plugin with multi-platform support (Android, iOS, Web). It uses build_runner to generate type-safe schemas, repositories, and query builders from annotated model classes, plus native Kotlin/Swift schemas for platform-side database access.

**Packages:**
- `native_sqlite` - Main plugin (exports annotations & platform interface)
- `native_sqlite_annotations` - Annotations (`@DbTable`, `@PrimaryKey`, `@DbColumn`, etc.)
- `native_sqlite_generator` - Build_runner code generator (generates `.table.dart` + `DatabaseManager`)
- `native_sqlite_platform_interface` - Platform channel interface
- `native_sqlite_android/ios/web` - Platform implementations
- `native_sqlite_inspector` - DevTools-style database inspector web app
- `example` - Example app demonstrating all features

## Critical Rules

### DO NOT
- ❌ **Manually create/edit `.table.dart` files** - These are auto-generated
- ❌ **Edit any generated files** (files with "GENERATED CODE - DO NOT MODIFY")
- ❌ **Create markdown documentation files after each change** unless explicitly requested
- ❌ **Create backwards compatibility code/methods** - Keep APIs clean

### DO
- ✅ Use `snake_case.dart` for model filenames (e.g., `user.dart`, `advanced_user.dart`)
- ✅ Run `dart run build_runner build --delete-conflicting-outputs` after model changes
- ✅ Use `flutter_manager.sh` script for batch operations across multiple packages
- ✅ Check generated `lib/generated/database_manager.dart` for auto-managed tables

## Essential Workflows

### 1. Creating a New Table Model

```dart
// lib/models/user.dart
import 'package:native_sqlite/native_sqlite.dart';

part 'user.table.dart';  // Generated file

@DbTable(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @DbColumn()
  final String name;
  
  @DbColumn(name: 'email_address', unique: true)
  final String email;
  
  const User({this.id, required this.name, required this.email});
}
```

Then run: `dart run build_runner build --delete-conflicting-outputs`

**Generated outputs:**
- `lib/models/user.table.dart` - Schema, QueryBuilder, Repository classes
- `lib/generated/schemas/user.schema.json` - Schema snapshot for migrations
- `lib/generated/database_manager.dart` - Auto-updated with new table

### 2. Build System Architecture

**Build phases (controlled by `build.yaml`):**
1. **`schema_registry` builder** - Scans all models, generates `DatabaseManager` (runs first)
2. **`migration` builder** - Creates schema snapshots in `lib/generated/schemas/`
3. **`table` builder** - Generates `.table.dart` files for each `@DbTable` model

**Post-build:** `native_code` runs after build_runner to generate Kotlin/Swift schemas

### 3. DatabaseManager Auto-Initialization

```dart
// App startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseManager.init(
    name: 'app_database',
    enableWAL: true,
    enableForeignKeys: true,
  );
  runApp(MyApp());
}
```

`DatabaseManager` is **automatically generated** from all `@DbTable(auto: true)` models. No manual registration needed.

### 4. Native Code Generation

Configure in `native_sqlite_config.yaml` (at project root):
```yaml
native_sqlite:
  generate_native: true
  database_name: 'example_app'
  
  android:
    enabled: true
    output_path: '../native_sqlite_android/android/src/main/kotlin/generated'
    package: 'dev.nesmin.native_sqlite.generated'
  
  ios:
    enabled: true
    output_path: '../native_sqlite_ios/ios/Classes/Generated'
```

Run: `dart run native_sqlite_generator`

Generates Kotlin `*Schema.kt` and Swift `*Schema.swift` files for native platform code.

## Key Patterns

### Annotations
- `@DbTable(name: 'table_name', database: 'db_name', auto: true)` - Mark class as table
- `@PrimaryKey(autoIncrement: true)` - Primary key field
- `@DbColumn(name: 'col_name', unique: true, defaultValue: '1')` - Column definition
- `@ForeignKey('referenced_table', 'referenced_column')` - Foreign key constraint
- `@EnumField(type: EnumType.name)` - Control enum storage (ordinal/name)
- `@Ignore()` - Skip field from schema

### Generated Classes (per table)
- `UserSchema` - SQL constants (`createTableSql`, `indexSql`, column names)
- `UserQueryBuilder` - Fluent query builder (`.nameContains()`, `.ageGreaterThan()`)
- `UserRepository` - CRUD operations (`.insert()`, `.findById()`, `.update()`)

### Testing
Use `MockNativeSqlitePlatform` to mock platform interactions:
```dart
class MockNativeSqlitePlatform extends NativeSqlitePlatform 
    with MockPlatformInterfaceMixin {
  // Override insert, query, update, delete
}
```

## Common Commands

```bash
# Run build_runner (from example/ or project root)
dart run build_runner build --delete-conflicting-outputs

# Generate native Kotlin/Swift schemas
dart run native_sqlite_generator

# Batch operations across all packages
./flutter_manager.sh --pub-get --build-runner

# Analyze schemas
dart run native_sqlite_generator analyze

# Generate migration SQL
dart run native_sqlite_generator migrate --from old.json --to new.json

# Organize schema files
dart run native_sqlite_generator:organize_schemas
```

## File Organization

```
lib/
├── models/                    # User-defined models
│   ├── user.dart             # Source model
│   └── user.table.dart       # Generated (DO NOT EDIT)
└── generated/
    ├── database_manager.dart # Auto-generated manager (DO NOT EDIT)
    └── schemas/              # Schema snapshots for migrations
        └── user.schema.json  # Generated snapshot
```

## Migration Strategy

Schema changes are tracked via JSON snapshots. When `@DbTable` structure changes:
1. Build runner detects changes, updates `.schema.json`
2. `DatabaseManager` auto-increments `schemaVersion`
3. Handle migrations via `DatabaseManager.init(onCustomMigrate: ...)`

## Dependencies & Build Configuration

Key dependencies in `pubspec.yaml`:
```yaml
dependencies:
  native_sqlite: ^x.x.x
  native_sqlite_annotations: ^x.x.x

dev_dependencies:
  build_runner: ^2.10.1
  native_sqlite_generator: ^x.x.x
```

`build.yaml` controls generator behavior (table name case, column name case, verbosity).

## Debugging

- Generated code issues → Check model annotations match expected patterns
- Build failures → Run with `--verbose` flag or check `logs/` directory
- Platform errors → Verify `native_sqlite_config.yaml` paths are correct
- Missing tables in `DatabaseManager` → Ensure `@DbTable(auto: true)` is set
