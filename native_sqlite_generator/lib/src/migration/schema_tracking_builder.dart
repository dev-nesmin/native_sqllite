import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
import 'package:native_sqlite_generator/src/migration/migration_sql_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that tracks all schemas in a consolidated JSON file
class SchemaTrackingBuilder implements Builder {
  static final _tableChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/table.dart#DbTable',
  );

  final GeneratorOptions options;

  SchemaTrackingBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': [
        'generated/native_sqlite_schema.json',
        'generated/schemas/.gitkeep',
      ],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    log.info('📁 Collecting schemas...');

    // Load previous schema to detect changes and deletions
    final previousSchema = await _loadPreviousSchema(buildStep);
    final previousTables = <String, Map<String, dynamic>>{};
    final previousVersion = previousSchema?['schemaVersion'] as int? ?? 0;

    if (previousSchema != null && previousSchema['schemas'] is List) {
      for (final schema in previousSchema['schemas'] as List) {
        final tableSchema = schema as Map<String, dynamic>;
        final tableName = tableSchema['tableName'] as String;
        previousTables[tableName] = tableSchema;
      }
      log.info('📋 Loaded ${previousTables.length} previous table schemas');
    }

    // Use Map to deduplicate schemas by tableName (in case multiple models use same table name)
    final currentSchemas = <String, Map<String, dynamic>>{};
    final currentTableNames = <String>{};
    final dartFiles = Glob('lib/**.dart');
    final assets = await buildStep.findAssets(dartFiles).toList();
    final analyzer = TableAnalyzer();

    // Scan current tables
    for (final assetId in assets) {
      final resolver = buildStep.resolver;
      if (!await resolver.isLibrary(assetId)) continue;

      final library = await resolver.libraryFor(assetId);
      final reader = LibraryReader(library);
      final tableElements = reader.annotatedWith(_tableChecker);

      if (tableElements.isEmpty) continue;

      for (final annotatedElement in tableElements) {
        final element = annotatedElement.element;
        if (element is! ClassElement) continue;

        final tableInfo = analyzer.analyze(
          element,
          annotatedElement.annotation,
        );

        final tableName = tableInfo.sqlName;
        currentTableNames.add(tableName);

        // Check if schema changed
        final previousTable = previousTables[tableName];
        final oldVersion = previousTable?['version'] as int? ?? 0;
        final oldHash = previousTable?['hash'] as String?;

        final testSnapshot = SchemaSnapshotHelper.createSnapshot(
          tableInfo,
          oldVersion,
        );

        final schemaChanged = oldHash != testSnapshot.hash;
        final newVersion = schemaChanged ? oldVersion + 1 : oldVersion;

        final snapshot = SchemaSnapshotHelper.createSnapshot(
          tableInfo,
          newVersion,
        );

        final snapshotJson = snapshot.toJson();

        // Generate migration SQL if schema changed and we have a previous version to compare
        if (schemaChanged && previousTable != null) {
          log.info(
            '🔍 ${tableInfo.dartName}: Schema changed (v$oldVersion → v$newVersion)',
          );
          log.info('   Old hash: $oldHash, New hash: ${snapshot.hash}');

          // Only generate migration SQL if this is not the initial creation (oldVersion > 0)
          if (oldVersion > 0) {
            final migrationSql = MigrationSqlGenerator.generateMigrationSql(
              tableName: tableName,
              oldSchema: previousTable,
              newSchema: snapshotJson,
            );

            final migrationSummary =
                MigrationSqlGenerator.generateMigrationSummary(
                  tableName: tableName,
                  oldSchema: previousTable,
                  newSchema: snapshotJson,
                );

            // Add migration info to schema
            snapshotJson['migrations'] = {
              'fromVersion': oldVersion,
              'toVersion': newVersion,
              'sql': migrationSql,
              'summary': migrationSummary,
            };

            log.info('📝 Generated migration: $migrationSummary');
          } else {
            log.info('   ⏭️  Skipped migration (initial creation)');
          }
        }

        // Store in map (overwriting if duplicate table names exist)
        currentSchemas[tableName] = snapshotJson;
      }
    }

    // Detect deleted tables
    final deletedTables = <Map<String, dynamic>>[];
    for (final entry in previousTables.entries) {
      if (!currentTableNames.contains(entry.key)) {
        final deletedSchema = Map<String, dynamic>.from(entry.value);
        deletedSchema['deleted'] = true;
        deletedSchema['deletedAt'] = DateTime.now().toIso8601String();
        deletedTables.add(deletedSchema);
        log.warning('🗑️  Table deleted: ${entry.key}');
      }
    }

    // Increment overall schema version if anything changed
    final hasChanges =
        currentSchemas.values.any(
          (s) =>
              (previousTables[s['tableName']]?['version'] ?? 0) != s['version'],
        ) ||
        deletedTables.isNotEmpty;

    final newSchemaVersion = hasChanges ? previousVersion + 1 : previousVersion;

    // Collect all migrations for this schema version
    final migrations = <Map<String, dynamic>>[];
    for (final schema in currentSchemas.values) {
      if (schema['migrations'] != null) {
        migrations.add({
          'tableName': schema['tableName'],
          'className': schema['className'],
          ...schema['migrations'] as Map<String, dynamic>,
        });
      }
    }

    // Add DROP TABLE migrations for deleted tables
    for (final deleted in deletedTables) {
      migrations.add({
        'tableName': deleted['tableName'],
        'className': deleted['className'],
        'fromVersion': deleted['version'],
        'toVersion': -1,
        'sql': ['DROP TABLE IF EXISTS ${deleted['tableName']};'],
        'summary': 'Table deleted',
      });
    }

    // Write consolidated schemas file
    final output = {
      'version': '1.0.0',
      'schemaVersion': newSchemaVersion,
      'generatedAt': DateTime.now().toIso8601String(),
      'schemas': currentSchemas.values.toList(),
      'deletedTables': deletedTables,
      'migrations': migrations, // All migrations for current version
      'previousSchemas':
          previousSchema?['schemas'], // Keep previous for reference
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(output);

    // Write current schema file (for build_runner)
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        'lib/generated/native_sqlite_schema.json',
      ),
      jsonString,
    );

    // Write .gitkeep to ensure schemas directory exists
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/generated/schemas/.gitkeep'),
      '',
    );

    // Write versioned snapshot (persists across builds)
    // This file is NOT managed by build_runner, so it won't be deleted
    final schemasDir = Directory('lib/generated/schemas');
    if (!schemasDir.existsSync()) {
      schemasDir.createSync(recursive: true);
    }

    final versionedFile = File(
      'lib/generated/schemas/native_sqlite_schema_v$newSchemaVersion.json',
    );

    // Only write if this version doesn't exist yet
    if (!versionedFile.existsSync()) {
      versionedFile.writeAsStringSync(jsonString);
      log.info(
        '💾 Saved versioned snapshot: native_sqlite_schema_v$newSchemaVersion.json',
      );
    }

    log.info('✅ Tracked ${currentSchemas.length} schemas (v$newSchemaVersion)');
    if (deletedTables.isNotEmpty) {
      log.info('   🗑️  ${deletedTables.length} deleted table(s)');
    }
    if (migrations.isNotEmpty) {
      log.info('   🔄 ${migrations.length} migration(s) generated');
    }
  }

  Future<Map<String, dynamic>?> _loadPreviousSchema(BuildStep buildStep) async {
    try {
      final schemasDir = Directory('lib/generated/schemas');

      // If schemas directory doesn't exist, this is first run
      if (!schemasDir.existsSync()) {
        log.info('📋 No previous schema directory - starting fresh');
        return null;
      }

      // Find the latest versioned schema file
      final schemaFiles = schemasDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      if (schemaFiles.isEmpty) {
        log.info('📋 No previous schema files - starting fresh');
        return null;
      }

      // Sort by version number (extract from filename: native_sqlite_schema_v1.json)
      schemaFiles.sort((a, b) {
        final aMatch = RegExp(r'_v(\d+)\.json').firstMatch(a.path);
        final bMatch = RegExp(r'_v(\d+)\.json').firstMatch(b.path);
        final aVersion = aMatch != null ? int.parse(aMatch.group(1)!) : 0;
        final bVersion = bMatch != null ? int.parse(bMatch.group(1)!) : 0;
        return aVersion.compareTo(bVersion);
      });

      final latestFile = schemaFiles.last;
      log.info('📋 Loading previous schema from: ${latestFile.path}');

      final content = latestFile.readAsStringSync();
      final schema = jsonDecode(content) as Map<String, dynamic>;
      return schema;
    } catch (e) {
      // If we can't read previous schema, start fresh
      log.warning('⚠️  Failed to load previous schema: $e');
      return null;
    }
  }
}
