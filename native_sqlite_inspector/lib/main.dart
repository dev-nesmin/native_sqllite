// Portions adapted from Isar Community Inspector.
// Copyright 2022 Simon Leier. Licensed under Apache-2.0.
// See the package NOTICE and LICENSES/Apache-2.0.txt files.

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'screens/connection_screen.dart';

void main() {
  runApp(const NativeSqliteDevToolsExtension());
}

class NativeSqliteDevToolsExtension extends StatelessWidget {
  const NativeSqliteDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: SQLiteInspectorApp());
  }
}

class SQLiteInspectorApp extends StatelessWidget {
  const SQLiteInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'native_sqlite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0277BD),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(body: ConnectionScreen()),
    );
  }
}
