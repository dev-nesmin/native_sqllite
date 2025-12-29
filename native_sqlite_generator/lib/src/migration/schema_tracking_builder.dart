import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
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
      r'$lib$': ['generated/native_sqlite_schema.json'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    log.info('📁 Collecting schemas...');

    // Load previous schema to detect changes and deletions
    final previousSchema = await _loadPreviousSchema();
    final previousTables = <String, Map<String, dynamic>>{};
    final previousVersion = previousSchema?['schemaVersion'] as int? ?? 0;

    if (previousSchema != null && previousSchema['schemas'] is List) {
      for (final schema in previousSchema['schemas'] as List) {
        final tableSchema = schema as Map<String, dynamic>;
        final tableName = tableSchema['tableName'] as String;
        previousTables[tableName] = tableSchema;
      }
    }

    final currentSchemas = <Map<String, dynamic>>[];
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

        currentSchemas.add(snapshot.toJson());

        if (schemaChanged && oldVersion > 0) {
          log.info('📝 ${tableInfo.dartName}: v$oldVersion → v$newVersion');
        }
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
        currentSchemas.any(
          (s) =>
              (previousTables[s['tableName']]?['version'] ?? 0) != s['version'],
        ) ||
        deletedTables.isNotEmpty;

    final newSchemaVersion = hasChanges ? previousVersion + 1 : previousVersion;

    // Write consolidated schemas file
    final output = {
      'version': '1.0.0',
      'schemaVersion': newSchemaVersion,
      'generatedAt': DateTime.now().toIso8601String(),
      'schemas': currentSchemas,
      'deletedTables': deletedTables,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(output);

    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        'lib/generated/native_sqlite_schema.json',
      ),
      jsonString,
    );

    log.info('✅ Tracked ${currentSchemas.length} schemas (v$newSchemaVersion)');
    if (deletedTables.isNotEmpty) {
      log.info('   🗑️  ${deletedTables.length} deleted table(s)');
    }
  }

  Future<Map<String, dynamic>?> _loadPreviousSchema() async {
    try {
      final file = File('lib/generated/native_sqlite_schema.json');
      if (!file.existsSync()) return null;

      final content = file.readAsStringSync();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      // If we can't read previous schema, start fresh
      return null;
    }
  }
}
