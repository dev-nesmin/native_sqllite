import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'screens/home_screen.dart';
import 'models/user.dart';
import 'models/category.dart';
import 'models/product.dart';
import 'models/order.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  await initializeDatabase();

  runApp(const MyApp());
}

/// Initialize database with all tables
Future<void> initializeDatabase() async {
  try {
    await NativeSqlite.open(
      config: DatabaseConfig(
        name: 'example_app',
        version: 1,
        onCreate: [
          // Create tables in correct order (tables with no dependencies first)
          UserSchema.createTableSql,
          CategorySchema.createTableSql,
          ProductSchema.createTableSql,
          OrderSchema.createTableSql,

          // Create indexes
          ...UserSchema.indexSql,
          ...CategorySchema.indexSql,
          ...ProductSchema.indexSql,
          ...OrderSchema.indexSql,
        ],
        onUpgrade: [
          // Add migration logic here when upgrading database version
          // Example:
          // if (oldVersion < 2) {
          //   'ALTER TABLE users ADD COLUMN avatar TEXT'
          // }
        ],
        enableWAL: true, // Enable Write-Ahead Logging for better performance
        enableForeignKeys: true, // Enable foreign key constraints
      ),
    );

    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Error initializing database: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native SQLite Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
