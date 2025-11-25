import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_sqlite/native_sqlite.dart';

import 'models/category.dart';
import 'models/order.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'screens/home_screen.dart';

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

          // Create indexes (only UserSchema has indexes defined)
          ...UserSchema.indexSql,
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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
