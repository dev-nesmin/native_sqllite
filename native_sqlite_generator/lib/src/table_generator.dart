import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:native_sqlite/native_sqlite.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/cache/build_cache.dart';
import 'package:native_sqlite_generator/src/code_gen/query_builder_generator.dart';
import 'package:native_sqlite_generator/src/code_gen/repository_generator.dart';
import 'package:native_sqlite_generator/src/code_gen/schema_generator.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/code_formatter.dart';
import 'package:native_sqlite_generator/src/helpers/error_handler.dart';
import 'package:native_sqlite_generator/src/helpers/imports_generator.dart';
import 'package:native_sqlite_generator/src/helpers/statistics_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Generator that creates table schemas and repository classes
/// from classes annotated with @DbTable or @Table (deprecated).
class TableGenerator extends GeneratorForAnnotation<DbTable> {
  final GeneratorOptions options;
  late final TableAnalyzer _analyzer;
  final SchemaGenerator _schemaGenerator = SchemaGenerator();
  final RepositoryGenerator _repositoryGenerator = RepositoryGenerator();
  final QueryBuilderGenerator _queryBuilderGenerator = QueryBuilderGenerator();
  late final CodeFormatter _formatter;
  BuildCache? _cache;

  TableGenerator(this.options) {
    _analyzer = TableAnalyzer(options);
    _formatter = CodeFormatter(enabled: options.format);

    // Initialize cache if enabled
    if (options.enableCachedBuilds) {
      _cache = BuildCache('.dart_tool/native_sqlite_generator');
      if (options.verbose) {
        print('✓ Build cache enabled');
      }
    }
  }

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

    // Check cache if enabled
    if (_cache != null && options.enableCachedBuilds) {
      try {
        final assetId = await buildStep.resolver.assetIdForElement(element);
        final sourceContent = await buildStep.readAsString(assetId);

        // Check if the output file exists
        final outputPath = assetId.path.replaceAll('.dart', '.table.dart');
        final outputId = AssetId(assetId.package, outputPath);
        final outputExists = await buildStep.canRead(outputId);

        // Only use cache if output file exists and source hasn't changed
        if (outputExists &&
            !_cache!.needsRegeneration(assetId.path, sourceContent)) {
          if (options.verbose) {
            print('  ⚡ Cache hit: ${assetId.path} (skipped)');
          }
          // Read and return existing file content
          final existingContent = await buildStep.readAsString(outputId);
          return existingContent;
        }

        if (options.verbose) {
          if (!outputExists) {
            print('  🔨 Output missing: ${assetId.path} (generating)');
          } else {
            print('  🔨 Cache miss: ${assetId.path} (generating)');
          }
        }
      } catch (e) {
        if (options.verbose) {
          print('  ⚠️  Cache check failed: $e');
        }
        // Continue with generation if cache check fails
      }
    }

    // Analyze the table
    final tableInfo = _analyzer.analyze(element, annotation);

    // Get the source file name for part-of directive
    final assetId = await buildStep.resolver.assetIdForElement(element);
    final libraryName = assetId.path.split('/').last;

    // Generate code
    final buffer = StringBuffer();

    // Add custom imports if configured
    final imports = ImportsGenerator.generate(options, libraryName, tableInfo);
    if (imports.isNotEmpty) {
      buffer.write(imports);
    }

    // Add statistics comment if enabled
    if (options.includeStatistics) {
      buffer.writeln(StatisticsGenerator.generate(tableInfo));
      buffer.writeln();
    }

    // Generate schema
    buffer.writeln(_schemaGenerator.generate(tableInfo));
    buffer.writeln();

    // Generate query builder
    buffer.writeln(_queryBuilderGenerator.generate(tableInfo));
    buffer.writeln();

    // Generate repository
    buffer.writeln(_repositoryGenerator.generate(tableInfo));

    // Format the generated code if enabled
    final code = buffer.toString();
    final formattedCode = options.format ? _formatter.format(code) : code;

    // Save cache after successful generation
    _cache?.save();

    return formattedCode;
  }
}
