import 'package:build/build.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/migration/migration_builder.dart';
import 'package:native_sqlite_generator/src/table_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Generates typed Row API classes from @DbTable annotations
Builder tableBuilder(BuilderOptions options) {
  final generatorOptions = GeneratorOptions.fromOptions(options);

  // Use .g.dart extension if generateAsPartFile is true, otherwise .table.dart
  final extension = generatorOptions.generateAsPartFile
      ? '.g.dart'
      : '.table.dart';

  return LibraryBuilder(
    TableGenerator(generatorOptions),
    generatedExtension: extension,
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

/// Tracks schema changes by generating .schema.json files
/// All schemas are generated in lib/generated/schemas/ directory
Builder migrationBuilder(BuilderOptions options) =>
    SchemaTrackingBuilder(options);
