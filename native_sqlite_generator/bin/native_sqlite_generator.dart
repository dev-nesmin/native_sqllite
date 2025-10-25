#!/usr/bin/env dart

import 'dart:io';
import 'package:native_sqlite_generator/src/native_generator.dart';

/// Main entry point for native code generation
///
/// Usage (just like flutter_launcher_icons):
///   dart run native_sqlite_generator
///
/// Or:
///   flutter pub run native_sqlite_generator
Future<void> main(List<String> arguments) async {
  print('');
  print('════════════════════════════════════════════');
  print('  Native SQLite Code Generator');
  print('════════════════════════════════════════════');
  print('');

  try {
    final generator = NativeCodeGenerator();
    await generator.generate();

    print('');
    print('✓ Native code generation completed successfully!');
    print('');
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('✗ Error generating native code:');
    print('  $e');
    print('');
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      print('Stack trace:');
      print(stackTrace);
      print('');
    }
    exit(1);
  }
}
