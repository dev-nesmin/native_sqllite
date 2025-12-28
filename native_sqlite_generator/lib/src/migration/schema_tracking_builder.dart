import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
import 'package:source_gen/source_gen.dart';

/// Builder that tracks all schemas in a single database file at project root
class SchemaTrackingBuilder implements Builder {
  static final _tableChecker = TypeChecker.fromUrl(
    'package:native_sqlite_annotations/src/table.dart#DbTable',
  );

  final GeneratorOptions options;
  bool _hasRun = false;

  SchemaTrackingBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['.schemas_marker'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    if (_hasRun) return;
    _hasRun = true;

    log.info('📁 Collecting schemas...');

    final allSchemas = <Map<String, dynamic>>[];
    final dartFiles = Glob('lib/**.dart');
    final assets = await buildStep.findAssets(dartFiles).toList();
    final analyzer = TableAnalyzer();

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

        final snapshot = SchemaSnapshotHelper.createSnapshot(tableInfo, 1);
        allSchemas.add(snapshot.toJson());
      }
    }

    if (allSchemas.isNotEmpty) {
      final version = allSchemas.length;

      // Just write the marker file - schema tracking happens elsewhere
      await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/.schemas_marker'),
        '// Schema version: $version\n// Tables: ${allSchemas.length}\n',
      );

      log.info('✅ Tracked ${allSchemas.length} schemas');
    }
  }
}
