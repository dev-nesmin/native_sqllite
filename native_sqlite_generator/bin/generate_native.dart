#!/usr/bin/env dart

import 'dart:io';
import 'package:native_sqlite_generator/src/native_generator.dart';

/// Main entry point for native code generation
///
/// Usage:
///   dart run native_sqlite_generator:generate_native
///
/// Or add to pubspec.yaml scripts and run:
///   flutter pub run native_sqlite_generator:generate_native
Future<void> main(List<String> arguments) async {
  print('🔧 Native SQLite Code Generator');
  print('================================\n');

  try {
    final generator = NativeCodeGenerator();
    await generator.generate();

    print('\n✅ Native code generation completed successfully!');
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ Error generating native code:');
    print(e);
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      print('\nStack trace:');
      print(stackTrace);
    }
    exit(1);
  }
}
