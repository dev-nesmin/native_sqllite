import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_sqlite_generator/database_manager.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database - everything is handled automatically!
  // Tables are created, migrations run, indexes added, etc.
  await DatabaseManager.init(
    name: 'example_app',
    enableWAL: true,
    enableForeignKeys: true,
    dropRemovedTables: false, // Set to true to auto-drop removed tables
    onCustomMigrate: (databaseName, oldVersion, newVersion) async {
      // Optional: Add custom migration logic here
      // Example:
      // if (oldVersion < 123456) {
      //   await NativeSqlite.execute(
      //     databaseName,
      //     'ALTER TABLE users ADD COLUMN avatar TEXT',
      //   );
      // }
      debugPrint('Custom migration: v$oldVersion → v$newVersion');
    },
  );

  runApp(const MyApp());
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
