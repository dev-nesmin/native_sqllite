import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/migration/legacy_snapshot_correction.dart';
import 'package:native_sqlite_generator/src/migration/migration_sql_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Version of the `migrations` format in schema snapshots. Snapshots without
/// it were written by generator versions whose migrations were never applied
/// at runtime, so their SQL is not trusted.
const migrationFormat = 2;

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
    // Keys of [previousTables] that matched a current table.
    final matchedPreviousTables = <String>{};
    var correctedLegacyNames = false;
    final dartFiles = Glob('lib/**.dart');
    final assets = await buildStep.findAssets(dartFiles).toList();
    final analyzer = TableAnalyzer(options);
    final legacyCorrection = LegacySnapshotCorrection(options);
    final tableMigrations = <Map<String, dynamic>>[];
    var anyTableChanged = false;

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
        final currentProbe = SchemaSnapshotHelper.createSnapshot(tableInfo, 0);

        // Find the previous snapshot of this table, correcting names written
        // by older generator versions that skipped the naming convention.
        var previousKey = tableName;
        if (!previousTables.containsKey(previousKey)) {
          previousKey =
              legacyCorrection.findLegacyTableKey(previousTables, currentProbe) ??
              '';
        }
        Map<String, dynamic>? previousTable;
        if (previousTables.containsKey(previousKey)) {
          matchedPreviousTables.add(previousKey);
          final corrected = legacyCorrection.correct(
            previousTables[previousKey]!,
            currentProbe,
          );
          previousTable = corrected.schema;
          if (corrected.changed) {
            correctedLegacyNames = true;
            log.info(
              '🩹 ${tableInfo.dartName}: corrected legacy snapshot names '
              '(no schema change)',
            );
          }
        }

        final oldVersion = previousTable?['version'] as int? ?? 0;

        // Compare structurally: both hashes are computed now with the same
        // algorithm, so the stored hash string never causes a false change.
        final schemaChanged =
            previousTable == null ||
            _hashOf(TableSchemaSnapshot.fromJson(previousTable)) !=
                currentProbe.hash;
        final newVersion = schemaChanged ? oldVersion + 1 : oldVersion;

        final snapshot = SchemaSnapshotHelper.createSnapshot(
          tableInfo,
          newVersion,
        );

        final snapshotJson = snapshot.toJson();

        // The step to this version is only needed for databases created at an
        // earlier version, i.e. when a previous schema exists at all.
        if (schemaChanged && previousSchema != null) {
          anyTableChanged = true;
          final migration = previousTable == null
              ? MigrationSqlGenerator.createTable(snapshot)
              : MigrationSqlGenerator.changeTable(
                  TableSchemaSnapshot.fromJson(previousTable),
                  snapshot,
                );
          tableMigrations.add({
            'tableName': tableName,
            'className': tableInfo.dartName,
            ...migration.toJson(),
          });
          log.info('📝 ${tableInfo.dartName}: ${migration.summary}');
          for (final warning in migration.warnings) {
            log.warning('⚠️  $warning');
          }
        } else if (schemaChanged) {
          anyTableChanged = true;
        }

        // Store in map (overwriting if duplicate table names exist)
        currentSchemas[tableName] = snapshotJson;
      }
    }

    // Tables of removed models are kept (with their data); drop them in a
    // custom migration if that's intended.
    final deletedTables = <Map<String, dynamic>>[];
    for (final entry in previousTables.entries) {
      if (!matchedPreviousTables.contains(entry.key)) {
        final deletedSchema = Map<String, dynamic>.from(entry.value);
        deletedSchema['deleted'] = true;
        deletedSchema['deletedAt'] = DateTime.now().toIso8601String();
        deletedTables.add(deletedSchema);
        log.warning(
          '🗑️  Model for table "${entry.key}" was removed; the table and its '
          'data stay in existing databases.',
        );
      }
    }

    final hasChanges = anyTableChanged || deletedTables.isNotEmpty;
    final newSchemaVersion = hasChanges ? previousVersion + 1 : previousVersion;

    // `migrations` is the step from the previous version to schemaVersion.
    // When nothing changed the version stays the same, so keep its step.
    final migrations = hasChanges
        ? tableMigrations
        : previousSchema?['migrationFormat'] == migrationFormat
        ? (previousSchema?['migrations'] as List? ?? const [])
        : const [];

    // Write consolidated schemas file
    final output = {
      'version': '1.0.0',
      'schemaVersion': newSchemaVersion,
      'generatedAt': DateTime.now().toIso8601String(),
      'schemas': currentSchemas.values.toList(),
      'deletedTables': deletedTables,
      'migrationFormat': migrationFormat,
      'migrations': migrations,
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

    // Only write if this version doesn't exist yet — unless the snapshot of
    // this same version was just corrected, in which case it must be fixed
    // so later builds diff against the real column names.
    if (!versionedFile.existsSync() || (correctedLegacyNames && !hasChanges)) {
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

  String _hashOf(TableSchemaSnapshot s) =>
      TableSchemaSnapshot.computeHash(s.tableName, s.columns, s.indexes);

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
