#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:native_sqlite_generator/src/cli/analyze_command.dart';
import 'package:native_sqlite_generator/src/cli/export_command.dart';
import 'package:native_sqlite_generator/src/cli/migrate_command.dart';
import 'package:native_sqlite_generator/src/cli/stats_command.dart';
import 'package:native_sqlite_generator/src/native_generator.dart';
import 'package:native_sqlite_generator/src/utils/logger.dart';

/// Main entry point for native code generation and utilities
///
/// Usage:
///   dart run native_sqlite_generator              # Generate native code
///   dart run native_sqlite_generator analyze      # Analyze table definitions
///   dart run native_sqlite_generator stats        # Show statistics
///   dart run native_sqlite_generator migrate      # Generate migration SQL
///   dart run native_sqlite_generator export       # Export schemas to JSON
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage')
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose output');

  parser.addCommand('analyze');
  parser.addCommand('stats');

  final migrateParser = parser.addCommand('migrate');
  migrateParser
    ..addOption(
      'from',
      help: 'Path to the old schema JSON file',
      mandatory: true,
    )
    ..addOption('to', help: 'Path to the new schema JSON file', mandatory: true)
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output path for migration SQL file',
    );

  final exportParser = parser.addCommand('export');
  exportParser
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output path for schema JSON/YAML file',
      mandatory: true,
    )
    ..addOption(
      'format',
      help: 'Output format: json or yaml',
      defaultsTo: 'json',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }

    final verbose = results['verbose'] as bool;
    setupLogger(verbose: verbose);

    // Handle commands
    switch (results.command?.name) {
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
        logger.severe('Unknown command: ${results.command?.name}');
        _printUsage(parser);
        exit(1);
    }
  } catch (e, stackTrace) {
    logger.severe('');
    logger.severe('Error: $e');
    logger.severe('');
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      logger.severe('Stack trace:');
      logger.severe(stackTrace);
      logger.severe('');
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
  final args = ['--output', outputPath, '--format', format];
  await command.execute(args);
}

Future<void> _generateNativeCode(List<String> arguments) async {
  logger.info('');
  logger.info('════════════════════════════════════════════');
  logger.info('  Native SQLite Code Generator');
  logger.info('════════════════════════════════════════════');
  logger.info('');

  final generator = NativeCodeGenerator();
  await generator.generate();

  logger.info('');
  logger.info('Native code generation completed successfully!');
  logger.info('');
}
