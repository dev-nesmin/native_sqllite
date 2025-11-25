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
/// Generates all schemas in a single pass to lib/generated/schemas/
class SchemaTrackingBuilder implements Builder {
  static final _tableChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotation/src/annotations.dart#Table',
  );

  final BuilderOptions options;
  bool _hasRun = false; // Only run once per build

  SchemaTrackingBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['generated/schemas/.schemas_generated'] // Marker file
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    // Only run once per build (like slang does)
    if (_hasRun) return;
    _hasRun = true;

    log.info('📁 Generating schema files...');

    final packageName = buildStep.inputId.package;
    final schemaDir = Directory('lib/generated/schemas');

    // Create directory if it doesn't exist
    if (!schemaDir.existsSync()) {
      schemaDir.createSync(recursive: true);
    }

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
        final tableInfo =
            analyzer.analyze(element, annotatedElement.annotation);
        final fileName = '${_toSnakeCase(tableInfo.dartName)}.schema.json';
        final filePath = 'lib/generated/schemas/$fileName';

        // Load previous schema to determine version
        final oldSchemaJson = await _loadOldSchema(filePath);
        final oldVersion = oldSchemaJson?['version'] as int? ?? 0;

        // Check if schema changed
        final newSnapshot =
            SchemaSnapshotHelper.createSnapshot(tableInfo, oldVersion);
        final oldHash = oldSchemaJson?['hash'] as String?;
        final schemaChanged = oldHash != newSnapshot.hash;

        final currentVersion = schemaChanged ? oldVersion + 1 : oldVersion;
        final snapshot =
            SchemaSnapshotHelper.createSnapshot(tableInfo, currentVersion);

        // Write directly to filesystem (like slang does)
        final jsonString =
            const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
        File(filePath).writeAsStringSync(jsonString);

        schemaCount++;

        if (schemaChanged) {
          log.info(
              '📝 Schema changed for ${tableInfo.dartName}: v$oldVersion → v$currentVersion (hash: ${snapshot.hash})');
        } else {
          log.fine(
              'Schema unchanged for ${tableInfo.dartName} (v$currentVersion)');
        }
      }
    }

    // Write marker file (required by buildExtensions)
    await buildStep.writeAsString(
      AssetId(packageName, 'lib/generated/schemas/.schemas_generated'),
      '// Schemas generated: $schemaCount files\n',
    );

    log.info('✅ Generated $schemaCount schema files in lib/generated/schemas/');
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
