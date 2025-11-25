#!/usr/bin/env dart

/// CLI tool to organize schema files into a custom directory structure.
///
/// This tool moves all .schema.json files from their source locations
/// to a centralized directory while maintaining a mapping file for reference.
///
/// Usage:
///   dart run native_sqlite_generator:organize_schemas [options]
///
/// Options:
///   --output=<path>    Output directory for schemas (default: lib/generated/schemas)
///   --dry-run          Show what would be done without making changes
///   --help             Show this help message

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output',
        abbr: 'o',
        defaultsTo: 'lib/generated/schemas',
        help: 'Output directory for schema files')
    ..addFlag('dry-run',
        abbr: 'n',
        negatable: false,
        help: 'Show what would be done without making changes')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show this help message');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final outputDir = results['output'] as String;
  final dryRun = results['dry-run'] as bool;

  print('Schema File Organizer');
  print('====================\n');

  if (dryRun) {
    print('🔍 DRY RUN MODE - No changes will be made\n');
  }

  // Find all .schema.json files in lib/
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Error: lib/ directory not found');
    print('   Make sure you run this from your project root');
    exit(1);
  }

  final schemaFiles = await _findSchemaFiles(libDir);

  if (schemaFiles.isEmpty) {
    print('ℹ️  No schema files found');
    print('   Run: flutter pub run build_runner build');
    return;
  }

  print('Found ${schemaFiles.length} schema file(s):\n');
  for (final file in schemaFiles) {
    print('  📄 ${path.relative(file.path)}');
  }

  print('\n📁 Target directory: $outputDir\n');

  if (!dryRun) {
    // Create output directory
    final targetDir = Directory(outputDir);
    if (!targetDir.existsSync()) {
      print('Creating directory: $outputDir');
      targetDir.createSync(recursive: true);
    }

    // Move files
    var movedCount = 0;
    for (final file in schemaFiles) {
      final fileName = path.basename(file.path);
      final targetPath = path.join(outputDir, fileName);

      // Skip if already in target location
      if (path.normalize(file.path) == path.normalize(targetPath)) {
        print('⏭️  Skipped: $fileName (already in target location)');
        continue;
      }

      // Copy file
      await file.copy(targetPath);

      // Delete original
      await file.delete();

      print('✅ Moved: $fileName → $outputDir/');
      movedCount++;
    }

    if (movedCount == 0) {
      print('\nℹ️  No files needed to be moved');
    } else {
      print('\n✨ Successfully organized $movedCount schema file(s)');
    }
  } else {
    print('Would move ${schemaFiles.length} file(s) to $outputDir/');
  }
}

Future<List<File>> _findSchemaFiles(Directory dir) async {
  final schemaFiles = <File>[];

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.schema.json')) {
      schemaFiles.add(entity);
    }
  }

  return schemaFiles;
}

void _printUsage(ArgParser parser) {
  print('Usage: dart run native_sqlite_generator:organize_schemas [options]\n');
  print('Organizes .schema.json files into a custom directory structure.\n');
  print('Options:');
  print(parser.usage);
  print('\nExamples:');
  print('  # Move schemas to lib/generated/schemas (default)');
  print('  dart run native_sqlite_generator:organize_schemas');
  print('');
  print('  # Move schemas to custom directory');
  print(
      '  dart run native_sqlite_generator:organize_schemas --output=lib/schemas');
  print('');
  print('  # Preview changes without applying them');
  print('  dart run native_sqlite_generator:organize_schemas --dry-run');
}
