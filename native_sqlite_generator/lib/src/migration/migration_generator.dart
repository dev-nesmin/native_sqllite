import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/helpers/error_handler.dart';
import 'package:native_sqlite_generator/src/helpers/schema_persistence.dart';
import 'package:native_sqlite_generator/src/helpers/schema_snapshot_helper.dart';
import 'package:native_sqlite_generator/src/migration/schema_comparator.dart';
import 'package:source_gen/source_gen.dart';

/// Generator that tracks schema changes and generates migration information
class MigrationGenerator extends GeneratorForAnnotation<DbTable> {
  final TableAnalyzer _analyzer = TableAnalyzer();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Validate that it's a class
    if (element is! ClassElement) {
      GeneratorError.throwError(
        '@DbTable can only be applied to classes.',
        element,
      );
    }

    // Analyze the table
    final tableInfo = _analyzer.analyze(element, annotation);

    // Get the output path for the schema file
    final outputPath = buildStep.inputId.changeExtension('.schema.json').path;

    // Load previous schema if it exists
    final oldSchema = await SchemaPersistence.loadSnapshot(outputPath);

    // Create current schema snapshot (version 1 for now, will implement versioning later)
    final currentVersion = oldSchema != null ? oldSchema.version + 1 : 1;
    final newSchema = SchemaSnapshotHelper.createSnapshot(
      tableInfo,
      currentVersion,
    );

    // Save the new schema
    await SchemaPersistence.saveSnapshot(outputPath, newSchema);

    // Detect changes
    final changes = SchemaComparator.compareSchemas(oldSchema, newSchema);

    // Generate migration information as a comment in the generated code
    if (changes.isEmpty) {
      return '// No schema changes detected for ${tableInfo.dartName}\n';
    }

    final buffer = StringBuffer();
    buffer.writeln('// Schema changes detected for ${tableInfo.dartName}:');
    buffer.writeln('// Version: ${oldSchema?.version ?? 0} -> $currentVersion');
    for (final change in changes) {
      buffer.writeln('// - $change');
    }

    if (SchemaComparator.requiresTableRecreation(changes)) {
      buffer.writeln('// ⚠️  WARNING: These changes require table recreation!');
    }

    buffer.writeln();

    return buffer.toString();
  }
}
