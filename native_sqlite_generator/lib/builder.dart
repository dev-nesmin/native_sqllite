/// Build-runner entrypoints for native_sqlite schema and repository code.
library;

import 'package:build/build.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/generators/schema_registry_builder.dart';
import 'package:native_sqlite_generator/src/migration/schema_tracking_builder.dart';
import 'package:native_sqlite_generator/src/post_build_hook.dart';
import 'package:native_sqlite_generator/src/table_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Generates typed Row API classes from @DbTable annotations
Builder tableBuilder(BuilderOptions options) {
  final generatorOptions = GeneratorOptions.fromOptions(options);

  return LibraryBuilder(
    TableGenerator(generatorOptions),
    generatedExtension: '.table.dart',
    header: _buildHeader(generatorOptions),
  );
}

/// Builds the file header with code generation warnings and lint ignores
String _buildHeader(GeneratorOptions options) {
  final lines = <String>[
    '// coverage:ignore-file',
    '// GENERATED CODE - DO NOT MODIFY BY HAND',
  ];

  if (options.includeTimestamp) {
    lines.add('// Generated on: ${DateTime.now().toIso8601String()}');
  }

  lines.addAll([
    '',
    '// ignore_for_file: ${options.ignoreForFile.join(', ')}',
    '',
  ]);

  return lines.join('\n');
}

/// Tracks all managed tables in one schema snapshot and migration history.
Builder migrationBuilder(BuilderOptions options) {
  final generatorOptions = GeneratorOptions.fromOptions(options);
  return SchemaTrackingBuilder(generatorOptions);
}

/// Generates the package's DatabaseManager from all managed tables.
Builder schemaRegistryBuilder(BuilderOptions options) {
  final generatorOptions = GeneratorOptions.fromOptions(options);
  return SchemaRegistryBuilder(generatorOptions);
}

/// Generates native Android/iOS code when generate_native: true.
/// Runs after the migration builder so the schema JSON is available.
Builder nativeCodeBuilder(BuilderOptions options) => NativeCodeBuilder();
