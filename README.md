# Native SQLite - Cross-Platform SQLite Plugin

A powerful SQLite plugin for Flutter that provides **true cross-platform database access** from both **Flutter/Dart** and **native code** (Android Kotlin, iOS Swift, Web) with **automatic code generation** and **native schema synchronization**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6%2B-blue.svg)](https://dart.dev)

## 🌟 Key Features

- ✅ **Cross-Platform**: Android, iOS, Web (with identical API)
- ✅ **Native Access**: Use SQLite from Kotlin/Swift background tasks
- ✅ **Code Generation**: Type-safe repositories from annotated classes
- ✅ **Automatic Sync**: Generated native schemas stay in perfect sync
- ✅ **WAL Mode**: Concurrent read/write access
- ✅ **Type Safety**: Full null-safety and compile-time checking
- ✅ **Zero Boilerplate**: One command generates everything
- ✅ **Background Tasks**: Works in WorkManager, Background App Refresh, etc.

## 🚀 Quick Start

### 1. Add Dependencies

```yaml
# pubspec.yaml
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

### 2. Define Your Model

```dart
// lib/models/user.dart
import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'user.table.g.dart';

@Table(name: 'users')
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String name;

  @Column(name: 'email_address', unique: true)
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

### 3. Generate Code

```bash
# One command generates everything!
dart run build_runner build --delete-conflicting-outputs
```

This automatically generates:
- ✅ **Dart repositories** with type-safe CRUD operations
- ✅ **Schema constants** for perfect Flutter/native sync
- ✅ **SQL CREATE TABLE** statements

### 4. Use in Flutter

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
        UserSchema.createTableSql, // Generated automatically!
      ],
      enableWAL: true,
    ),
  );

  // Use type-safe repository
  final userRepo = UserRepository('my_app');

  // Insert
  final userId = await userRepo.insert(User(
    name: 'John Doe',
    email: 'john@example.com',
    createdAt: DateTime.now(),
  ));

  // Query
  final user = await userRepo.findById(userId);
  final allUsers = await userRepo.findAll();

  // Update
  await userRepo.update(user!.copyWith(name: 'Jane Doe'));

  // Delete
  await userRepo.delete(userId);
}
```

## 🔥 Automatic Native Code Generation

Like `flutter_launcher_icons`, but for database schemas! Generate native Kotlin and Swift code automatically.

### Configuration

Add to `pubspec.yaml`:

```yaml
native_sqlite:
  generate_native: true

  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/com/example/generated"
    package: "com.example.generated"

  ios:
    enabled: true
    output_path: "ios/Runner/Generated"

  models:
    - lib/models/**/*.dart
```

### Generate Everything

```bash
# Option 1: Integrated with build_runner (Recommended)
dart run build_runner build

# Option 2: Standalone native generator
dart run native_sqlite_generator
```

**What gets generated:**

✅ **Dart** (`lib/models/user.table.g.dart`):
```dart
abstract class UserSchema {
  static const String tableName = 'users';
  static const String createTableSql = '''...''';
  static const String ID = 'id';
  static const String NAME = 'name';
  static const String EMAIL = 'email_address';
}

class UserRepository { /* CRUD methods */ }
```

✅ **Kotlin** (`android/.../UserSchema.kt`):
```kotlin
object UserSchema {
    const val TABLE_NAME = "users"
    const val ID = "id"
    const val NAME = "name"
    const val EMAIL = "email_address"
}
```

✅ **Swift** (`ios/.../UserSchema.swift`):
```swift
enum UserSchema {
    static let tableName = "users"
    static let id = "id"
    static let name = "name"
    static let email = "email_address"
}
```

## 📱 Native Code Usage

### Android (Kotlin)

Perfect for WorkManager, Services, and background tasks:

```kotlin
import com.example.generated.UserSchema
import dev.nesmin.native_sqlite.NativeSqliteManager

class LocationWorker : Worker() {
    override fun doWork(): Result {
        // Use generated constants - no typos possible!
        val userId = NativeSqliteManager.insert(
            "my_app",
            UserSchema.TABLE_NAME,
            mapOf(
                UserSchema.NAME to "Background User",
                UserSchema.EMAIL to "bg@example.com"
            )
        )

        val users = NativeSqliteManager.query(
            "my_app",
            "SELECT * FROM ${UserSchema.TABLE_NAME} WHERE ${UserSchema.EMAIL} = ?",
            listOf("bg@example.com")
        )

        return Result.success()
    }
}
```

### iOS (Swift)

Perfect for Background App Refresh and app extensions:

```swift
import Foundation

class LocationBackgroundTask {
    func saveLocation() {
        let manager = NativeSqliteManager.shared

        // Use generated constants
        let userId = try! manager.insert(
            name: "my_app",
            table: UserSchema.tableName,
            values: [
                UserSchema.name: "Background User",
                UserSchema.email: "bg@example.com"
            ]
        )

        let users = try! manager.query(
            name: "my_app",
            sql: "SELECT * FROM \(UserSchema.tableName) WHERE \(UserSchema.email) = ?",
            arguments: ["bg@example.com"]
        )
    }
}
```

## 📚 Comprehensive Annotations

### @Table
```dart
@Table(
  name: 'custom_table_name',
  indexes: [
    ['email'],           // Single column index
    ['category', 'price'] // Composite index
  ],
)
class Product { }
```

### @PrimaryKey
```dart
@PrimaryKey(autoIncrement: true)
final int? id; // Use int? for auto-increment
```

### @Column
```dart
@Column(
  name: 'custom_column_name',
  unique: true,
  nullable: true,
  defaultValue: "'default'",
  type: 'TEXT',
)
final String? field;
```

### @ForeignKey
```dart
@ForeignKey(
  table: 'users',
  column: 'id',
  onDelete: 'CASCADE',
  onUpdate: 'CASCADE',
)
final int userId;
```

### @Index (Class-level)
```dart
@Index(
  name: 'idx_email_created',
  columns: ['email', 'createdAt'],
  unique: true,
)
class User { }
```

### @Ignore
```dart
@Ignore()
final String computedValue; // Not stored in database
```

## 🌐 Web Support

**Identical API** works on web using SQLite WASM:

```dart
// Same code works on Android, iOS, AND Web!
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'my_app',
    version: 1,
    onCreate: [UserSchema.createTableSql],
  ),
);

final userRepo = UserRepository('my_app');
await userRepo.insert(User(name: 'Web User', email: 'web@example.com'));
```

### Web Characteristics
- **First Load**: ~200-300ms initialization (one-time, then cached)
- **Storage**: Data stored in IndexedDB
- **Performance**: Near-native speed after initialization
- **Compatibility**: Modern browsers with WASM support

## 🏗️ Architecture

This plugin follows a federated plugin architecture:

```
native_sqlite/                          # Main plugin (platform interface)
├── lib/native_sqlite.dart             # Public API
├── pubspec.yaml

native_sqlite_platform_interface/       # Platform interface
├── lib/src/models/
│   ├── database_config.dart           # Configuration model
│   └── query_result.dart              # Query result model
└── pubspec.yaml

native_sqlite_android/                  # Android implementation
├── android/src/main/kotlin/
│   └── NativeSqlitePlugin.kt          # Android platform code
└── lib/native_sqlite_android.dart

native_sqlite_ios/                      # iOS implementation
├── ios/Classes/
│   └── NativeSqlitePlugin.swift       # iOS platform code
└── lib/native_sqlite_ios.dart

native_sqlite_web/                      # Web implementation
├── lib/native_sqlite_web.dart         # Web SQLite WASM
└── README.md

native_sqlite_annotation/               # Annotations
├── lib/src/annotations.dart           # @Table, @Column, etc.
└── pubspec.yaml

native_sqlite_generator/                # Code generator
├── lib/src/table_generator.dart       # Main generator logic
├── build.yaml                         # Builder configuration
└── pubspec.yaml
```

## 🔧 Manual API (No Code Generation)

You can also use the plugin without code generation:

```dart
// Manual approach - also supported
await NativeSqlite.open(
  config: DatabaseConfig(
    name: 'manual_db',
    version: 1,
    onCreate: [
      '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
      )
      '''
    ],
  ),
);

// Manual CRUD
final id = await NativeSqlite.insert('manual_db', 'users', {
  'name': 'John Doe',
  'email': 'john@example.com',
});

final results = await NativeSqlite.query(
  'manual_db',
  'SELECT * FROM users WHERE id = ?',
  [id],
);
```

## ⚡ Performance Features

- **WAL Mode**: Enables concurrent reading while writing
- **Connection Pooling**: Reuses connections efficiently
- **Batch Operations**: Transaction support for bulk operations
- **Indexes**: Automatic and custom index generation
- **Prepared Statements**: Prevents SQL injection, improves performance

## 🧪 Testing

The plugin includes comprehensive testing tools:

```bash
# Test all packages
./flutter_manager.sh

# Test individual packages
cd native_sqlite && flutter test
cd native_sqlite_generator && dart test
```

## 🔄 Migration from Other Solutions

### From sqflite

```dart
// Before (sqflite)
final db = await openDatabase('my_db.db', version: 1);
await db.insert('users', {'name': 'John'});

// After (native_sqlite with code generation)
await NativeSqlite.open(config: DatabaseConfig(name: 'my_db', version: 1));
await userRepo.insert(User(name: 'John'));
```

### From drift

```dart
// Before (drift) - complex setup with generated files
@DataClass('User')
class Users extends Table { /* complex setup */ }

// After (native_sqlite) - simple annotations
@Table()
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @Column()
  final String name;
}
```

## 📖 Complete Documentation

- **[CODEGEN.md](CODEGEN.md)** - Complete code generation guide
- **[AUTOMATED_GENERATION.md](AUTOMATED_GENERATION.md)** - Native code generation
- **[NATIVE_USAGE.md](NATIVE_USAGE.md)** - Using from Kotlin/Swift
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - All features and improvements
- **[native_sqlite_web/README.md](native_sqlite_web/README.md)** - Web-specific docs

## 🎯 Use Cases

### Perfect for:
- **Background Location Plugins** - Store GPS data from native background tasks
- **Offline-First Apps** - Reliable local storage with sync capabilities
- **Cross-Platform Data** - Same database accessible from Flutter and native
- **Plugin Development** - Add persistent storage to your Flutter plugins
- **Enterprise Apps** - Type-safe database layer with full native integration

### Example: Background Location Plugin

```dart
// Flutter side
@Table(name: 'location_logs')
class LocationLog {
  @PrimaryKey(autoIncrement: true)
  final int? id;
  
  @Column()
  final double latitude;
  
  @Column()
  final double longitude;
  
  @Column()
  final DateTime timestamp;
}

// Android WorkManager
class LocationWorker : Worker() {
    override fun doWork(): Result {
        val locationId = NativeSqliteManager.insert(
            "location_db",
            LocationLogSchema.TABLE_NAME,
            mapOf(
                LocationLogSchema.LATITUDE to location.latitude,
                LocationLogSchema.LONGITUDE to location.longitude,
                LocationLogSchema.TIMESTAMP to System.currentTimeMillis()
            )
        )
        return Result.success()
    }
}
```

## 🛠️ Development Tools

### Project Manager Script

Use the included `flutter_manager.sh` for managing all packages:

```bash
./flutter_manager.sh
# Interactive menu to:
# 1. Run pub get on all packages
# 2. Run build_runner on packages that need it
# 3. Clean and rebuild everything
# 4. Full clean + pub get + build_runner
```

### Watch Mode

For continuous development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

This watches for model changes and regenerates code automatically.

## 🚀 CI/CD Integration

```yaml
# .github/workflows/build.yml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.27.0'

- name: Install dependencies
  run: flutter pub get

- name: Generate code
  run: dart run build_runner build --delete-conflicting-outputs

- name: Run tests
  run: flutter test
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Run `./flutter_manager.sh` to set up all packages
3. Make your changes
4. Test with `flutter test` in relevant packages
5. Generate code with `dart run build_runner build`

## 🔧 Troubleshooting

### Build Runner Issues

```bash
# Clean and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Database Locked Errors

- Enable WAL mode: `enableWAL: true`
- Check for long-running transactions
- Ensure proper connection cleanup

### Native Code Not Generating

- Ensure `generate_native: true` in config
- Check that `enabled: true` for android/ios
- Verify model files have `@Table` annotations

### Web Issues

- Ensure modern browser with WASM support
- Check network connectivity for WASM file loading
- Clear browser cache if experiencing issues

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Why Choose Native SQLite?

| Feature | native_sqlite | sqflite | drift | others |
|---------|---------------|---------|-------|--------|
| **Native Access** | ✅ Full | ❌ | ❌ | ❌ |
| **Code Generation** | ✅ Simple | ❌ | ✅ Complex | ❌ |
| **Web Support** | ✅ Identical API | ❌ | ✅ Different | ❌ |
| **Type Safety** | ✅ Full | ❌ | ✅ | ❌ |
| **Background Tasks** | ✅ Perfect | ❌ | ❌ | ❌ |
| **Cross-Platform Sync** | ✅ Automatic | ❌ | ❌ | ❌ |
| **Setup Complexity** | 🟢 Simple | 🟢 Simple | 🔴 Complex | 🟡 Medium |

**Choose native_sqlite when you need:**
- Database access from both Flutter and native code
- Type-safe database operations
- Automatic code generation
- Perfect cross-platform synchronization
- Background task database operations
- Web support with identical API

**🎉 Get started in 5 minutes and enjoy the most powerful SQLite solution for Flutter!**