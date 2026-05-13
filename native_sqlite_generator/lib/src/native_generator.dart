import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import 'config.dart';
import 'migration_generator.dart';
import 'models/schema_snapshot.dart';
import 'native_kotlin_generator.dart';
import 'native_swift_generator.dart';
import 'utils/logger.dart';

/// Generates native code files for Android and iOS
class NativeCodeGenerator {
  Future<void> generate({bool runBuildRunner = true}) async {
    // Check if build_runner should run
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

    // Load configuration
    logger.info('📋 Loading configuration...');
    final config = await NativeSqliteConfig.load();

    if (config == null) {
      logger.warning('⚠️  No native_sqlite configuration found.');
      logger.warning(
        '   Add configuration to pubspec.yaml or create native_sqlite_config.yaml',
      );
      logger.warning('   See native_sqlite_config.example.yaml for reference.');
      return;
    }

    if (!config.generateNative) {
      logger.info(
        'ℹ️  Native code generation is disabled (generate_native: false)',
      );
      return;
    }

    logger.info('✓ Configuration loaded\n');

    // Find Schema files
    logger.info('🔍 Finding schema files...');
    final schemaFiles = await _findSchemaFiles();

    if (schemaFiles.isEmpty) {
      logger.warning('⚠️  No schema files found in lib/generated/schemas/');
      logger.warning(
        '   Make sure you have run build_runner to generate schemas.',
      );
      return;
    }

    logger.info('✓ Found ${schemaFiles.length} schema file(s)\n');

    final schemas = await _loadSchemas(schemaFiles);

    if (schemas.isEmpty) {
      logger.warning('⚠️  No valid schemas loaded.');
      return;
    }

    logger.info(
      '   Loaded schemas for: ${schemas.map((s) => s.className).join(", ")}',
    );

    final generatedFiles = <String>[];

    // Generate Android code
    if (config.android.enabled) {
      final androidFiles = await _generateAndroid(
        schemas,
        config.android,
        config.databaseName,
        config.schemaVersion,
        config.includeExamples,
      );
      generatedFiles.addAll(androidFiles);
    }

    // Generate iOS code
    if (config.ios.enabled) {
      final iosFiles = await _generateIos(
        schemas,
        config.ios,
        config.databaseName,
        config.schemaVersion,
        config.includeExamples,
      );
      generatedFiles.addAll(iosFiles);
    }

    // Summary
    logger.info('\n📊 Generation Summary');
    logger.info('   Files generated: ${generatedFiles.length}');

    if (config.android.enabled) {
      final androidFiles = generatedFiles
          .where((f) => f.endsWith('.kt'))
          .length;
      logger.info('   - Android (Kotlin): $androidFiles file(s)');
    }

    if (config.ios.enabled) {
      final iosFiles = generatedFiles.where((f) => f.endsWith('.swift')).length;
      logger.info('   - iOS (Swift): $iosFiles file(s)');
    }

    logger.info('\n💡 Next steps:');
    if (config.android.enabled) {
      logger.info(
        '   • Rebuild your Android app to include the generated files',
      );
    }
    if (config.ios.enabled) {
      logger.info('   • Add generated Swift files to your Xcode project');
      logger.info('   • Right-click on Runner folder → Add Files to "Runner"');
    }
  }

  Future<List<File>> _findSchemaFiles() async {
    // Check for schema file in lib/generated/ (same location as database_manager.dart)
    final schemaFile = File('lib/generated/native_sqlite_schema.json');
    if (await schemaFile.exists()) {
      return [schemaFile];
    }

    // Fall back to old location for backwards compatibility
    final oldFile = File('lib/generated/schemas/all_schemas.json');
    if (await oldFile.exists()) {
      return [oldFile];
    }

    // Fall back to individual schema files (legacy format)
    final glob = Glob('lib/generated/schemas/*.schema.json');
    final files = <File>[];
    await for (final entity in glob.list()) {
      if (await FileSystemEntity.isFile(entity.path)) {
        files.add(File(entity.path));
      }
    }
    return files;
  }

  Future<List<TableSchemaSnapshot>> _loadSchemas(List<File> files) async {
    final schemas = <TableSchemaSnapshot>[];

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final jsonData = json.decode(content) as Map<String, dynamic>;

        // Check if it's the consolidated format
        if (jsonData.containsKey('schemas')) {
          final schemasList = jsonData['schemas'] as List;
          for (final schemaJson in schemasList) {
            schemas.add(
              TableSchemaSnapshot.fromJson(schemaJson as Map<String, dynamic>),
            );
          }
          logger.info(
            '   Loaded ${schemasList.length} schemas from consolidated file',
          );
        } else {
          // Individual schema file
          schemas.add(TableSchemaSnapshot.fromJson(jsonData));
        }
      } catch (e) {
        logger.warning(
          '   ❌ Failed to load schema from ${path.basename(file.path)}: $e',
        );
      }
    }
    return schemas;
  }

  Future<List<String>> _generateAndroid(
    List<TableSchemaSnapshot> schemas,
    AndroidConfig config,
    String databaseName,
    int schemaVersion,
    bool includeExamples,
  ) async {
    final generator = NativeKotlinGenerator(
      packageName: config.package,
      databaseName: databaseName,
      includeExamples: includeExamples,
    );

    final generatedFiles = <String>[];
    final outputDir = Directory(config.outputPath);

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      logger.info('   📁 Created directory: ${config.outputPath}');
    }

    for (final schema in schemas) {
      final schemaCode = generator.generateSchema(schema);
      final schemaFile = File(
        path.join(config.outputPath, '${schema.className}Schema.kt'),
      );
      await schemaFile.writeAsString(schemaCode);
      generatedFiles.add(schemaFile.path);
      logger.info('   ✓ Generated ${path.basename(schemaFile.path)}');

      if (config.generateHelpers) {
        final helperCode = generator.generateHelper(schema);
        final helperFile = File(
          path.join(config.outputPath, '${schema.className}Helper.kt'),
        );
        await helperFile.writeAsString(helperCode);
        generatedFiles.add(helperFile.path);
        logger.info('   ✓ Generated ${path.basename(helperFile.path)}');
      }
    }

    if (config.generateHelpers) {
      final dbManagerCode = generator.generateDatabaseManager(
        schemas,
        schemaVersion,
      );
      final dbManagerFile = File(
        path.join(config.outputPath, 'DatabaseManager.kt'),
      );
      await dbManagerFile.writeAsString(dbManagerCode);
      generatedFiles.add(dbManagerFile.path);
      logger.info('   ✓ Generated DatabaseManager.kt');
    }

    final migrationGen = MigrationGenerator();
    final migrationsDir = Directory(path.join(config.outputPath, 'migrations'));

    if (!await migrationsDir.exists()) {
      await migrationsDir.create(recursive: true);
    }

    final versionManagerCode = migrationGen.generateKotlinVersionManager(
      packageName: config.package,
      databaseName: databaseName,
      currentVersion: schemaVersion,
    );

    final versionManagerFile = File(
      path.join(migrationsDir.path, 'SchemaVersionManager.kt'),
    );
    await versionManagerFile.writeAsString(versionManagerCode);
    generatedFiles.add(versionManagerFile.path);
    logger.info('   ✓ Generated ${path.basename(versionManagerFile.path)}');

    if (schemaVersion > 1) {
      for (var i = 1; i < schemaVersion; i++) {
        final fromVersion = i;
        final toVersion = i + 1;
        final migrationFileName = 'Migration_${fromVersion}_$toVersion.kt';
        final migrationFile = File(
          path.join(migrationsDir.path, migrationFileName),
        );

        if (!await migrationFile.exists()) {
          final migrationCode = migrationGen.generateKotlinMigration(
            packageName: config.package,
            databaseName: databaseName,
            tables: schemas,
            fromVersion: fromVersion,
            toVersion: toVersion,
          );
          await migrationFile.writeAsString(migrationCode);
          generatedFiles.add(migrationFile.path);
          logger.info(
            '   ✓ Generated stub ${path.basename(migrationFile.path)}',
          );
        }
      }
    }

    return generatedFiles;
  }

  Future<List<String>> _generateIos(
    List<TableSchemaSnapshot> schemas,
    IosConfig config,
    String databaseName,
    int schemaVersion,
    bool includeExamples,
  ) async {
    final generator = NativeSwiftGenerator(
      databaseName: databaseName,
      includeExamples: includeExamples,
    );

    final generatedFiles = <String>[];
    final outputDir = Directory(config.outputPath);

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      logger.info('   📁 Created directory: ${config.outputPath}');
    }

    for (final schema in schemas) {
      final schemaCode = generator.generateSchema(schema);
      final schemaFile = File(
        path.join(config.outputPath, '${schema.className}Schema.swift'),
      );
      await schemaFile.writeAsString(schemaCode);
      generatedFiles.add(schemaFile.path);
      logger.info('   ✓ Generated ${path.basename(schemaFile.path)}');

      if (config.generateHelpers) {
        final helperCode = generator.generateHelper(schema);
        final helperFile = File(
          path.join(config.outputPath, '${schema.className}Helper.swift'),
        );
        await helperFile.writeAsString(helperCode);
        generatedFiles.add(helperFile.path);
        logger.info('   ✓ Generated ${path.basename(helperFile.path)}');
      }
    }

    if (config.generateHelpers) {
      final dbManagerCode = generator.generateDatabaseManager(
        schemas,
        schemaVersion,
      );
      final dbManagerFile = File(
        path.join(config.outputPath, 'DatabaseManager.swift'),
      );
      await dbManagerFile.writeAsString(dbManagerCode);
      generatedFiles.add(dbManagerFile.path);
      logger.info('   ✓ Generated DatabaseManager.swift');
    }

    final migrationGen = MigrationGenerator();

    final versionManagerCode = migrationGen.generateSwiftVersionManager(
      databaseName: databaseName,
      currentVersion: schemaVersion,
    );

    final versionManagerFile = File(
      path.join(config.outputPath, 'SchemaVersionManager.swift'),
    );
    await versionManagerFile.writeAsString(versionManagerCode);
    generatedFiles.add(versionManagerFile.path);
    logger.info('   ✓ Generated ${path.basename(versionManagerFile.path)}');

    if (schemaVersion > 1) {
      for (var i = 1; i < schemaVersion; i++) {
        final fromVersion = i;
        final toVersion = i + 1;
        final migrationFileName = 'Migration_${fromVersion}_$toVersion.swift';
        final migrationFile = File(
          path.join(config.outputPath, migrationFileName),
        );

        if (!await migrationFile.exists()) {
          final migrationCode = migrationGen.generateSwiftMigration(
            databaseName: databaseName,
            tables: schemas,
            fromVersion: fromVersion,
            toVersion: toVersion,
          );
          await migrationFile.writeAsString(migrationCode);
          generatedFiles.add(migrationFile.path);
          logger.info(
            '   ✓ Generated stub ${path.basename(migrationFile.path)}',
          );
        }
      }
    }

    return generatedFiles;
  }
}
