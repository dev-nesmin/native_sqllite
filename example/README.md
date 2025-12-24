# native_sqlite_example

Example app demonstrating the Native SQLite plugin with automatic database management.

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App

```bash
flutter run
```

## Database Initialization

The app uses the auto-generated `DatabaseManager` to handle all database operations:

```dart
import 'database_schema.database_manager.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database - everything handled automatically!
  await DatabaseManager.init();
  
  runApp(MyApp());
}
```

The `database_schema.database_manager.g.dart` file is automatically generated and handles:
- Table creation in dependency order
- Schema versioning and migrations
- Foreign key setup
- Index creation
- Database lifecycle management

**Note**: This file is in `.gitignore` and regenerated on each build_runner run.

## Features Demonstrated

- **Multiple table relationships** (users, products, orders, categories)
- **Foreign keys** with cascade operations
- **Indexes** for query optimization
- **Custom type converters** (enums, JSON, DateTime)
- **Freezed integration** for immutable models
- **Auto-migration** when schema changes

## Project Structure

```
lib/
├── models/              # Database models with @DbTable annotations
│   ├── user.dart
│   ├── product.dart
│   ├── order.dart
│   └── ...
├── screens/             # UI screens
├── widgets/             # Reusable widgets
├── database_schema.dart # Trigger file for code generation
└── main.dart           # App entry point with DatabaseManager.init()
```

## Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Native SQLite Documentation](../README.md)
