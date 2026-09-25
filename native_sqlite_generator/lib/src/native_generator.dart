import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import 'config.dart';
import 'native/native_column.dart';
import 'native/native_database_spec.dart';
import 'native_kotlin_generator.dart';
import 'native_swift_generator.dart';

/// Generates native code files for Android and iOS
class NativeCodeGenerator {
  static const _schemaPath = 'lib/generated/native_sqlite_schema.json';
  static const _manifestName = '.native_sqlite_generated.json';

  /// CLI entry point: optionally runs build_runner (which also generates
  /// native code through the `native_code` builder), then generates from
  /// the schema snapshot on disk.
  Future<void> generate({bool runBuildRunner = true}) async {
    if (runBuildRunner) {
      log.info('Running build_runner first...\n');
      final result = await Process.run('flutter', [
        'pub',
        'run',
        'build_runner',
        'build',
      ]);

      if (result.exitCode != 0) {
        throw Exception('build_runner failed:\n${result.stderr}');
      }

      log.info('build_runner completed\n');
    }

    final schemaFile = File(_schemaPath);
    if (!schemaFile.existsSync()) {
      throw StateError(
        '$_schemaPath not found. Run build_runner to generate the schema '
        'snapshot before native code generation.',
      );
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
      throw StateError(
        'No native_sqlite configuration found. Add configuration to '
        'pubspec.yaml or create native_sqlite_config.yaml.',
      );
    }

    if (!config.generateNative) {
      log.info('Native code generation is disabled (generate_native: false)');
      return;
    }

    final spec = NativeDatabaseSpec.fromSchemaJson(
      schemaJson,
      databaseName: config.databaseName,
    ).withNativeTypePrefix(config.nativeTypePrefix);

    if (spec.tables.isEmpty) {
      throw StateError('No valid table schemas found in the schema JSON.');
    }

    log.fine(
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

    log.info('Generated ${generatedFiles.length} native file(s)');
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
    return writeGeneratedFiles(config.outputPath, files);
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
    return writeGeneratedFiles(config.outputPath, files);
  }

  /// Writes one platform's generated files and removes files tracked by the
  /// previous manifest that are no longer part of the output.
  Future<List<String>> writeGeneratedFiles(
    String outputPath,
    Map<String, String> files,
  ) async {
    final outputDir = Directory(outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
      log.fine('Created directory: $outputPath');
    }

    final manifestFile = File(path.join(outputPath, _manifestName));
    final previousFiles = await _readManifest(manifestFile);
    final currentFiles = files.keys.toSet();
    for (final relative in previousFiles.difference(currentFiles)) {
      if (!_isSafeRelativePath(relative)) {
        log.warning('Ignoring unsafe generated-file path: $relative');
        continue;
      }
      final stale = File(path.join(outputPath, relative));
      if (!stale.existsSync()) continue;
      final content = await stale.readAsString();
      if (!content.contains('AUTO-GENERATED')) {
        log.warning(
          'Kept $relative because it no longer has the '
          'AUTO-GENERATED marker',
        );
        continue;
      }
      await stale.delete();
      log.info('Removed stale generated file $relative');
    }

    final written = <String>[];
    for (final MapEntry(key: name, value: code) in files.entries) {
      final file = File(path.join(outputPath, name));
      if (file.existsSync() && await file.readAsString() == code) {
        written.add(file.path);
        log.fine('   = Up to date $name');
        continue;
      }
      await file.writeAsString(code);
      written.add(file.path);
      log.fine('Generated $name');
    }

    final sortedNames = currentFiles.toList()..sort();
    final manifest = const JsonEncoder.withIndent(
      '  ',
    ).convert({'version': 1, 'files': sortedNames});
    final manifestContent = '$manifest\n';
    if (!manifestFile.existsSync() ||
        await manifestFile.readAsString() != manifestContent) {
      await manifestFile.writeAsString(manifestContent);
    }
    return written;
  }

  Future<Set<String>> _readManifest(File file) async {
    if (!file.existsSync()) return <String>{};
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (json['files'] as List).cast<String>().toSet();
    } on Object catch (error) {
      log.warning(
        'Could not read ${file.path}; stale generated files will be '
        'kept this run: $error',
      );
      return <String>{};
    }
  }

  bool _isSafeRelativePath(String value) {
    if (path.isAbsolute(value)) return false;
    final normalized = path.normalize(value);
    return normalized != '..' && !normalized.startsWith('../');
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
        log.info('Removed obsolete generated file $relative');
      }
    }
  }
}
