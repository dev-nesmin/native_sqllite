import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that tracks schema changes by generating .schema.json files
/// Generates all schemas using build_runner's asset system
class SchemaTrackingBuilder implements Builder {
  static final _tableChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/table.dart#DbTable',
  );

  final BuilderOptions options;

  SchemaTrackingBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    // Generate single consolidated schemas file
    return const {
      r'$lib$': ['generated/schemas/all_schemas.json'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    print('🔵 MIGRATION BUILDER STARTING');
    log.info('📁 Collecting schemas...');

    final allSchemas = <Map<String, dynamic>>[];

    // Find all Dart files in lib/
    final dartFiles = Glob('lib/**.dart');
    final assets = await buildStep.findAssets(dartFiles).toList();

    final analyzer = TableAnalyzer();
    int schemaCount = 0;

    for (final assetId in assets) {
      final resolver = buildStep.resolver;
      if (!await resolver.isLibrary(assetId)) continue;

      final library = await resolver.libraryFor(assetId);
      final reader = LibraryReader(library);

      // Find all @Table annotated classes
      final tableElements = reader.annotatedWith(_tableChecker);
      if (tableElements.isEmpty) continue;

      for (final annotatedElement in tableElements) {
        final element = annotatedElement.element;
        if (element is! ClassElement) continue;

        // Analyze the table
        final tableInfo = analyzer.analyze(
          element,
          annotatedElement.annotation,
        );

        // Load previous schema to check for changes
        final fileName = '${_toSnakeCase(tableInfo.dartName)}.schema.json';
        final filePath = 'lib/generated/schemas/$fileName';
        final oldSchemaJson = await _loadOldSchema(filePath);
        final oldVersion = oldSchemaJson?['version'] as int? ?? 0;

        // Check if schema changed
        final testSnapshot = SchemaSnapshotHelper.createSnapshot(
          tableInfo,
          oldVersion,
        );
        final oldHash = oldSchemaJson?['hash'] as String?;
        final schemaChanged = oldHash != testSnapshot.hash;

        final currentVersion = schemaChanged ? oldVersion + 1 : oldVersion;
        final snapshot = SchemaSnapshotHelper.createSnapshot(
          tableInfo,
          currentVersion,
        );

        // Add to all schemas
        allSchemas.add(snapshot.toJson());

        if (schemaChanged) {
          log.info('📝 ${tableInfo.dartName}: v$oldVersion → v$currentVersion');
        }
      }
    }

    // Write consolidated schemas file
    final output = {
      'version': '1.0.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'schemas': allSchemas,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(output);

    final outputAsset = AssetId(
      buildStep.inputId.package,
      'lib/generated/schemas/all_schemas.json',
    );

    log.info(
      'Writing to ${outputAsset.path} in package ${outputAsset.package}',
    );

    await buildStep.writeAsString(outputAsset, jsonString);

    log.info('✅ Tracked ${allSchemas.length} schemas');
  }

  Future<Map<String, dynamic>?> _loadOldSchema(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // If we can't read it, treat as no previous schema
    }
    return null;
  }

  /// Converts PascalCase to snake_case
  String _toSnakeCase(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}
