# Native SQLite Example App

A comprehensive Flutter example app demonstrating all features of the **native_sqlite** plugin.

## Overview

This example showcases:
- ✅ Code generation with annotations
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Type-safe database operations
- ✅ Foreign key relationships
- ✅ Indexes for performance
- ✅ Transactions
- ✅ Complex queries (JOIN, aggregation)
- ✅ Native code access (Kotlin/Swift)
- ✅ Cross-platform support (Android, iOS, Web)
- ✅ Manual API usage

## Features Demonstrated

### 1. CRUD Operations Screen
- User, Category, and Product management
- Insert, update, delete operations
- Generated repository pattern
- Form validation
- Real-time updates

### 2. Advanced Features Screen
- **Transactions**: Atomic operations with rollback support
- **Foreign Keys**: Referential integrity constraints
- **Indexes**: Performance optimization demonstrations
- **Complex Queries**: JOIN, GROUP BY, aggregation
- **Custom Queries**: Using repository query methods
- **Batch Operations**: Efficient bulk inserts
- **Data Types**: String, int, bool, DateTime, nullable types

### 3. Manual API Screen
- Direct SQLite API usage without code generation
- Manual insert, update, delete operations
- Custom queries
- Flexibility demonstration

### 4. Native Integration Screen
- **Android (Kotlin)**: Access database from native Android code
- **iOS (Swift)**: Access database from native iOS code
- Using generated schema constants
- Independent of Flutter layer

### 5. Database Statistics Screen
- View database information
- Table counts
- Schema visualization
- Sample data generation
- Clear all data

## Models

### User Model
```dart
@Table(name: 'users', indexes: [['email'], ['createdAt']])
class User {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column(nullable: false)
  final String name;

  @Column(unique: true, nullable: false)
  final String email;

  // ... other fields
}
```

### Category Model
```dart
@Table(name: 'categories')
class Category {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column(unique: true, nullable: false)
  final String name;

  // ... other fields
}
```

### Product Model
```dart
@Table(name: 'products', indexes: [['categoryId', 'price'], ['name']])
class Product {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @ForeignKey(table: 'categories', column: 'id', onDelete: 'CASCADE')
  @Column(nullable: false)
  final int categoryId;

  // ... other fields
}
```

### Order Model
```dart
@Table(name: 'orders', indexes: [['userId', 'createdAt'], ['status']])
class Order {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @ForeignKey(table: 'users', column: 'id', onDelete: 'CASCADE')
  @Column(nullable: false)
  final int userId;

  @ForeignKey(table: 'products', column: 'id', onDelete: 'CASCADE')
  @Column(nullable: false)
  final int productId;

  // ... other fields
}
```

## Setup & Installation

### 1. Get Dependencies

```bash
flutter pub get
```

### 2. Run Code Generation

This will generate:
- Dart repository classes (`.g.dart` files)
- Native Kotlin schema files (Android)
- Native Swift schema files (iOS)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or for continuous generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. Run the App

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## Generated Code

After running code generation, you'll find:

### Dart Files
- `lib/models/user.g.dart`
- `lib/models/category.g.dart`
- `lib/models/product.g.dart`
- `lib/models/order.g.dart`

Each contains:
- `UserSchema` class with table/column constants
- `UserRepository` class with CRUD methods

### Android (Kotlin)
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/UserSchema.kt`
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/CategorySchema.kt`
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/ProductSchema.kt`
- `android/app/src/main/kotlin/com/example/native_sqlite_example/generated/OrderSchema.kt`

### iOS (Swift)
- `ios/Runner/Generated/UserSchema.swift`
- `ios/Runner/Generated/CategorySchema.swift`
- `ios/Runner/Generated/ProductSchema.swift`
- `ios/Runner/Generated/OrderSchema.swift`

## Usage Examples

### Using Generated Repository

```dart
final userRepository = UserRepository('example_app');

// Insert
final userId = await userRepository.insert(User(
  name: 'John Doe',
  email: 'john@example.com',
  age: 30,
));

// Find by ID
final user = await userRepository.findById(userId);

// Find all
final allUsers = await userRepository.findAll();

// Update
await userRepository.update(user!.copyWith(name: 'Jane Doe'));

// Delete
await userRepository.delete(userId);

// Count
final count = await userRepository.count();

// Custom query
final results = await userRepository.query(
  'SELECT * FROM users WHERE age > ?',
  [25],
);
```

### Using Manual API

```dart
// Insert
final id = await NativeSqlite.insert('example_app', 'users', {
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
  'isActive': 1,
  'createdAt': DateTime.now().millisecondsSinceEpoch,
});

// Query
final result = await NativeSqlite.query(
  'example_app',
  'SELECT * FROM users WHERE age > ?',
  [25],
);
final users = result.toMapList();

// Update
await NativeSqlite.update(
  'example_app',
  'users',
  {'name': 'Updated Name'},
  where: 'id = ?',
  whereArgs: [id],
);

// Delete
await NativeSqlite.delete(
  'example_app',
  'users',
  where: 'id = ?',
  whereArgs: [id],
);
```

### Native Android Code (Kotlin)

```kotlin
// Using generated schema constants
val userId = NativeSqliteManager.insert(
    "example_app",
    UserSchema.TABLE_NAME,
    mapOf(
        UserSchema.NAME to "Native User",
        UserSchema.EMAIL to "native@example.com",
        UserSchema.AGE to 25,
        UserSchema.IS_ACTIVE to 1,
        UserSchema.CREATED_AT to System.currentTimeMillis()
    )
)

val users = NativeSqliteManager.query(
    "example_app",
    "SELECT * FROM ${UserSchema.TABLE_NAME}",
    emptyList()
)
```

### Native iOS Code (Swift)

```swift
let manager = NativeSqliteManager.shared

let userId = try! manager.insert(
    name: "example_app",
    table: UserSchema.tableName,
    values: [
        UserSchema.name: "Native User",
        UserSchema.email: "native@example.com",
        UserSchema.age: 25,
        UserSchema.isActive: 1,
        UserSchema.createdAt: Int(Date().timeIntervalSince1970 * 1000)
    ]
)

let result = try! manager.query(
    name: "example_app",
    sql: "SELECT * FROM \(UserSchema.tableName)",
    args: []
)
```

## Database Schema

### Tables

#### users
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT NOT NULL)
- `email` (TEXT UNIQUE NOT NULL)
- `phoneNumber` (TEXT)
- `address` (TEXT)
- `age` (INTEGER DEFAULT 1)
- `isActive` (INTEGER DEFAULT 1)
- `createdAt` (INTEGER NOT NULL)
- `updatedAt` (INTEGER)

**Indexes:**
- `email`
- `createdAt`

#### categories
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT UNIQUE NOT NULL)
- `description` (TEXT)
- `createdAt` (INTEGER NOT NULL)

#### products
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT NOT NULL)
- `description` (TEXT)
- `price` (REAL NOT NULL)
- `stock` (INTEGER DEFAULT 0)
- `isAvailable` (INTEGER DEFAULT 1)
- `categoryId` (INTEGER NOT NULL, FK → categories.id)
- `imageUrl` (TEXT)
- `createdAt` (INTEGER NOT NULL)
- `updatedAt` (INTEGER)

**Indexes:**
- `categoryId, price` (composite)
- `name`

**Foreign Keys:**
- `categoryId` → `categories(id)` ON DELETE CASCADE

#### orders
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `userId` (INTEGER NOT NULL, FK → users.id)
- `productId` (INTEGER NOT NULL, FK → products.id)
- `quantity` (INTEGER NOT NULL)
- `totalPrice` (REAL NOT NULL)
- `status` (TEXT DEFAULT 'pending')
- `notes` (TEXT)
- `createdAt` (INTEGER NOT NULL)
- `updatedAt` (INTEGER)
- `deliveredAt` (INTEGER)

**Indexes:**
- `userId, createdAt` (composite)
- `status`

**Foreign Keys:**
- `userId` → `users(id)` ON DELETE CASCADE
- `productId` → `products(id)` ON DELETE CASCADE

## Configuration

The code generation is configured in `pubspec.yaml`:

```yaml
native_sqlite:
  generate_native: true

  android:
    enabled: true
    output_path: "android/app/src/main/kotlin/com/example/native_sqlite_example/generated"
    package: "com.example.native_sqlite_example.generated"

  ios:
    enabled: true
    output_path: "ios/Runner/Generated"

  models:
    - lib/models/**/*.dart
```

## Troubleshooting

### Code Generation Issues

If code generation fails:

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Native Code Not Found

Make sure you've run code generation to create the native schema files before building for Android/iOS.

### Database Errors

If you encounter database errors:
1. Uninstall the app completely
2. Reinstall to recreate the database
3. Or use the "Clear All Data" button in Statistics screen

## Learn More

- [Native SQLite Plugin Documentation](../README.md)
- [Flutter Documentation](https://docs.flutter.dev/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)

## License

This example app is part of the native_sqlite plugin project.
