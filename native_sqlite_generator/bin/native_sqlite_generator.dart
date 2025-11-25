#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:native_sqlite_generator/src/cache/build_cache.dart';
import 'package:native_sqlite_generator/src/cli/analyze_command.dart';
import 'package:native_sqlite_generator/src/cli/export_command.dart';
import 'package:native_sqlite_generator/src/cli/migrate_command.dart';
import 'package:native_sqlite_generator/src/cli/stats_command.dart';
import 'package:native_sqlite_generator/src/native_generator.dart';

/// Main entry point for native code generation and utilities
///
/// Usage:
///   dart run native_sqlite_generator              # Generate native code
///   dart run native_sqlite_generator analyze      # Analyze table definitions
///   dart run native_sqlite_generator stats        # Show statistics
///   dart run native_sqlite_generator migrate      # Generate migration SQL
///   dart run native_sqlite_generator export       # Export schemas to JSON
///   dart run native_sqlite_generator clean-cache  # Clear build cache
///   dart run native_sqlite_generator cache-stats  # Show cache info
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output');

  parser.addCommand('clean-cache');
  parser.addCommand('cache-stats');
  parser.addCommand('analyze');
  parser.addCommand('stats');

  final migrateParser = parser.addCommand('migrate');
  migrateParser
    ..addOption('from',
        help: 'Path to the old schema JSON file', mandatory: true)
    ..addOption('to', help: 'Path to the new schema JSON file', mandatory: true)
    ..addOption('output',
        abbr: 'o', help: 'Output path for migration SQL file');

  final exportParser = parser.addCommand('export');
  exportParser
    ..addOption('output',
        abbr: 'o',
        help: 'Output path for schema JSON/YAML file',
        mandatory: true)
    ..addOption('format',
        help: 'Output format: json or yaml', defaultsTo: 'json');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }

    final verbose = results['verbose'] as bool;

    // Handle commands
    switch (results.command?.name) {
      case 'clean-cache':
        await _cleanCache(verbose);
        break;
      case 'cache-stats':
        await _cacheStats(verbose);
        break;
      case 'analyze':
        await _analyze(verbose);
        break;
      case 'stats':
        await _stats(verbose);
        break;
      case 'migrate':
        await _migrate(verbose, results.command!);
        break;
      case 'export':
        await _export(verbose, results.command!);
        break;
      case null:
        // Default: run native code generation
        await _generateNativeCode(arguments);
        break;
      default:
        print('Unknown command: ${results.command?.name}');
        _printUsage(parser);
        exit(1);
    }
  } catch (e, stackTrace) {
    print('');
    print('✗ Error: $e');
    print('');
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      print('Stack trace:');
      print(stackTrace);
      print('');
    }
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('''
Native SQLite Generator - Code generation and utilities

USAGE:
  dart run native_sqlite_generator [command] [options]

COMMANDS:
  (default)     Generate native SQLite code for Android (Kotlin) and iOS (Swift)
  analyze       Analyze table definitions for issues
  stats         Show project statistics
  migrate       Generate SQL migrations between schema versions
  export        Export table schemas to JSON/YAML
  clean-cache   Clear the build cache
  cache-stats   Show cache statistics

OPTIONS:
  -h, --help      Show this help message
  -v, --verbose   Enable verbose output

EXAMPLES:
  # Generate native code
  dart run native_sqlite_generator

  # Analyze tables for issues
  dart run native_sqlite_generator analyze

  # Show project stats
  dart run native_sqlite_generator stats

  # Generate migration SQL
  dart run native_sqlite_generator migrate --from schema_v1.json --to schema_v2.json --output migration.sql

  # Export schema to JSON
  dart run native_sqlite_generator export --output docs/schema.json

  # Export schema to YAML
  dart run native_sqlite_generator export --output docs/schema.yaml --format yaml

  # Clear cache
  dart run native_sqlite_generator clean-cache --verbose

For more information, visit: https://github.com/your_repo/native_sqlite
''');
}

Future<void> _analyze(bool verbose) async {
  final command = AnalyzeCommand(verbose);
  await command.execute();
}

Future<void> _stats(bool verbose) async {
  final command = StatsCommand(verbose);
  await command.execute();
}

Future<void> _migrate(bool verbose, ArgResults commandResults) async {
  final fromPath = commandResults['from'] as String;
  final toPath = commandResults['to'] as String;
  final outputPath = commandResults['output'] as String?;

  final command = MigrateCommand(verbose);
  final args = [
    '--from',
    fromPath,
    '--to',
    toPath,
    if (outputPath != null) ...['--output', outputPath],
  ];
  await command.execute(args);
}

Future<void> _export(bool verbose, ArgResults commandResults) async {
  final outputPath = commandResults['output'] as String;
  final format = commandResults['format'] as String? ?? 'json';

  final command = ExportCommand(verbose);
  final args = [
    '--output',
    outputPath,
    '--format',
    format,
  ];
  await command.execute(args);
}

Future<void> _generateNativeCode(List<String> arguments) async {
  print('');
  print('════════════════════════════════════════════');
  print('  Native SQLite Code Generator');
  print('════════════════════════════════════════════');
  print('');

  final generator = NativeCodeGenerator();
  await generator.generate();

  print('');
  print('✓ Native code generation completed successfully!');
  print('');
}

Future<void> _cleanCache(bool verbose) async {
  print('🧹 Cleaning build cache...\n');

  final cache = BuildCache('.dart_tool/native_sqlite_generator');
  final stats = cache.getStats();

  if (verbose) {
    print('Cache location: ${stats.cacheFile}');
    print('Entries before: ${stats.totalEntries}');
    print('Size before: ${stats.size} bytes');
    print('');
  }

  cache.clear();
  cache.save();

  print('✅ Cache cleared successfully!');

  if (verbose) {
    print('');
    print('Next build will regenerate all files.');
  }
}

Future<void> _cacheStats(bool verbose) async {
  print('📊 Build Cache Statistics\n');

  final cache = BuildCache('.dart_tool/native_sqlite_generator');
  final stats = cache.getStats();

  print(stats);

  if (verbose && stats.totalEntries > 0) {
    print('Cached files:');
    final files = cache.getCachedFiles();
    for (int i = 0; i < files.length; i++) {
      print('  ${i + 1}. ${files[i]}');
    }
    print('');
  }

  if (stats.totalEntries == 0) {
    print('💡 Tip: Run "dart run build_runner build" to populate the cache.');
  }
}
