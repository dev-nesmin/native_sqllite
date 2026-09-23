import 'dart:io';

import 'package:path/path.dart' as path;

import 'config.dart';
import 'native/native_column.dart';
import 'native/native_database_spec.dart';
import 'native_kotlin_generator.dart';
import 'native_swift_generator.dart';
import 'utils/logger.dart';

/// Generates native code files for Android and iOS
class NativeCodeGenerator {
  static const _schemaPath = 'lib/generated/native_sqlite_schema.json';

  /// CLI entry point: optionally runs build_runner (which also generates
  /// native code through the `native_code` builder), then generates from
  /// the schema snapshot on disk.
  Future<void> generate({bool runBuildRunner = true}) async {
    if (runBuildRunner) {
      logger.info('📦 Running build_runner first...\n');
      final result = await Process.run('dart', [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]);

      if (result.exitCode != 0) {
        throw Exception('build_runner failed:\n${result.stderr}');
      }

      logger.info('✓ build_runner completed\n');
    }

    final schemaFile = File(_schemaPath);
    if (!schemaFile.existsSync()) {
      logger.warning('⚠️  $_schemaPath not found.');
      logger.warning('   Run build_runner to generate the schema snapshot.');
      return;
    }
    await generateFromSchemaContent(await schemaFile.readAsString());
  }

  /// Called from within build_runner (via NativeCodeBuilder).
  /// Accepts the schema JSON content that the build system already read so we
  /// never touch dart:io for reading — the file may not be on disk yet during
  /// a build session even though build_to:source is set.
  Future<void> generateFromSchemaContent(String schemaJson) async {
    final config = await NativeSqliteConfig.load();

    if (config == null) {
      logger.warning('⚠️  No native_sqlite configuration found.');
      logger.warning(
        '   Add configuration to pubspec.yaml or create native_sqlite_config.yaml',
      );
      return;
    }

    if (!config.generateNative) {
      logger.info(
        'ℹ️  Native code generation is disabled (generate_native: false)',
      );
      return;
    }

    final NativeDatabaseSpec spec;
    try {
      spec = NativeDatabaseSpec.fromSchemaJson(
        schemaJson,
        databaseName: config.databaseName,
      );
    } on FormatException catch (e) {
      logger.warning('⚠️  Failed to parse schema JSON: $e');
      return;
    }

    if (spec.tables.isEmpty) {
      logger.warning('⚠️  No valid schemas found in schema JSON.');
      return;
    }

    logger.info(
      '   Loaded ${spec.tables.length} schema(s): '
      '${spec.tables.map((s) => s.className).join(", ")}',
    );

    final generatedFiles = <String>[];

    if (config.android.enabled) {
      generatedFiles.addAll(
        await _generateAndroid(spec, config.android, config.includeExamples),
      );
    }

    if (config.ios.enabled) {
      generatedFiles.addAll(
        await _generateIos(spec, config.ios, config.includeExamples),
      );
    }

    logger.info('📊 Generated ${generatedFiles.length} native file(s)');
  }

  Future<List<String>> _generateAndroid(
    NativeDatabaseSpec spec,
    AndroidConfig config,
    bool includeExamples,
  ) async {
    final generator = NativeKotlinGenerator(
      packageName: config.package,
      databaseName: spec.databaseName,
      includeExamples: includeExamples,
    );
    final files = <String, String>{
      for (final nativeEnum in NativeEnum.collect(spec.tables))
        '${nativeEnum.name}.kt': generator.generateEnum(nativeEnum),
      for (final schema in spec.tables) ...{
        '${schema.className}Schema.kt': generator.generateSchema(schema),
        if (config.generateHelpers)
          '${schema.className}Helper.kt': generator.generateHelper(schema),
      },
      if (config.generateHelpers)
        'DatabaseManager.kt': generator.generateDatabaseManager(spec),
    };

    _removeObsolete(config.outputPath, [
      path.join('migrations', 'SchemaVersionManager.kt'),
    ]);
    return _writeAll(config.outputPath, files);
  }

  Future<List<String>> _generateIos(
    NativeDatabaseSpec spec,
    IosConfig config,
    bool includeExamples,
  ) async {
    final generator = NativeSwiftGenerator(
      databaseName: spec.databaseName,
      includeExamples: includeExamples,
    );
    final files = <String, String>{
      'NativeSqliteGeneratedSupport.swift': generator.generateSupport(),
      for (final nativeEnum in NativeEnum.collect(spec.tables))
        '${nativeEnum.name}.swift': generator.generateEnum(nativeEnum),
      for (final schema in spec.tables) ...{
        '${schema.className}Schema.swift': generator.generateSchema(schema),
        if (config.generateHelpers)
          '${schema.className}Helper.swift': generator.generateHelper(schema),
      },
      if (config.generateHelpers)
        'DatabaseManager.swift': generator.generateDatabaseManager(spec),
    };

    _removeObsolete(config.outputPath, ['SchemaVersionManager.swift']);
    return _writeAll(config.outputPath, files);
  }

  Future<List<String>> _writeAll(
    String outputPath,
    Map<String, String> files,
  ) async {
    final outputDir = Directory(outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
      logger.info('   📁 Created directory: $outputPath');
    }
    final written = <String>[];
    for (final MapEntry(key: name, value: code) in files.entries) {
      final file = File(path.join(outputPath, name));
      await file.writeAsString(code);
      written.add(file.path);
      logger.info('   ✓ Generated $name');
    }
    return written;
  }

  /// Deletes files that earlier generator versions produced and that are no
  /// longer generated. Only files carrying the AUTO-GENERATED marker are
  /// removed, never hand-written code.
  void _removeObsolete(String outputPath, List<String> relativePaths) {
    for (final relative in relativePaths) {
      final file = File(path.join(outputPath, relative));
      if (file.existsSync() &&
          file.readAsStringSync().contains('AUTO-GENERATED')) {
        file.deleteSync();
        logger.info('   🗑️  Removed obsolete $relative');
      }
    }
  }
}
