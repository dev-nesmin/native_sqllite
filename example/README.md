# Native SQLite Example

This example demonstrates how to use the native_sqlite package with code generation.

## Features Demonstrated

1. **Table Generation**: Automatic table schema generation from annotated classes
2. **Repository Pattern**: Type-safe CRUD operations using generated repositories
3. **Foreign Keys**: Relationships between tables (User → Post)
4. **Indexes**: Creating indexes for better query performance
5. **Type Safety**: Full type safety with null safety support
6. **CRUD Operations**: Insert, read, update, and delete operations

## Running the Example

1. **Generate code**:
   ```bash
   cd example
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

## Models

### User Model (`lib/models/user.dart`)
- Primary key with auto-increment
- Unique email constraint
- Boolean field (stored as INTEGER)
- DateTime fields (stored as INTEGER milliseconds)
- Nullable fields support

### Post Model (`lib/models/post.dart`)
- Foreign key relationship to User
- Composite index on (userId, createdAt)
- Default value for viewCount
- CASCADE delete when user is deleted

## Generated Files

After running `build_runner`, you'll see:

**Dart Files:**
- `lib/models/user.table.g.dart` - UserSchema and UserRepository
- `lib/models/post.table.g.dart` - PostSchema and PostRepository

**Native Files (Auto-generated):**
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/UserSchema.kt`
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/UserHelper.kt`
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/PostSchema.kt`
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/PostHelper.kt`
- `ios/Runner/Generated/UserSchema.swift`
- `ios/Runner/Generated/UserHelper.swift`
- `ios/Runner/Generated/PostSchema.swift`
- `ios/Runner/Generated/PostHelper.swift`

**Automatic Native Generation:**
Native code (Kotlin for Android, Swift for iOS) is automatically generated when you run `build_runner build`. This is configured in `pubspec.yaml` with `generate_native: true`.

## Usage Pattern

```dart
// 1. Open database with generated schemas
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_db',
    version: 1,
    onCreate: [
      UserSchema.createTableSql,
      PostSchema.createTableSql,
    ],
    enableForeignKeys: true,
  ),
);

// 2. Create repositories
final userRepo = UserRepository('my_db');
final postRepo = PostRepository('my_db');

// 3. Use type-safe operations
final userId = await userRepo.insert(User(...));
final user = await userRepo.findById(userId);
final allUsers = await userRepo.findAll();
```

## Tips

### Code Generation
- Always run `build_runner` after modifying model classes
- Use `--delete-conflicting-outputs` flag to avoid conflicts
- Check the generated `.table.g.dart` files to understand the SQL
- Native code (Kotlin/Swift) is automatically generated with `build_runner build`

### Native Code
- For iOS: Add generated files to Xcode project once (Right-click Runner → Add Files)
- Native files stay in sync with your Dart models automatically
- Use generated native helpers for platform-specific SQLite operations
- Check `AUTOMATED_GENERATION.md` for full native code generation docs

### Database
- Foreign keys require `enableForeignKeys: true` in DatabaseConfig
- Use watch mode for continuous development: `dart run build_runner watch`
