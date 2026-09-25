import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:native_sqlite_annotations/native_sqlite_annotations.dart';
import 'package:native_sqlite_generator/src/analyzer/table_analyzer.dart';
import 'package:native_sqlite_generator/src/code_gen/query_builder_generator.dart';
import 'package:native_sqlite_generator/src/code_gen/repository_generator.dart';
import 'package:native_sqlite_generator/src/code_gen/row_mapper_generator.dart';
import 'package:native_sqlite_generator/src/code_gen/schema_generator.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/helpers/error_handler.dart';
import 'package:native_sqlite_generator/src/helpers/imports_generator.dart';
import 'package:native_sqlite_generator/src/helpers/statistics_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Generator that creates table schemas and repository classes
/// from classes annotated with @DbTable.
class TableGenerator extends GeneratorForAnnotation<DbTable> {
  final GeneratorOptions options;
  late final TableAnalyzer _analyzer;
  final SchemaGenerator _schemaGenerator = SchemaGenerator();
  final RepositoryGenerator _repositoryGenerator = RepositoryGenerator();
  final QueryBuilderGenerator _queryBuilderGenerator = QueryBuilderGenerator();
  final RowMapperGenerator _rowMapperGenerator = RowMapperGenerator();

  TableGenerator(this.options) {
    _analyzer = TableAnalyzer(options);
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

    // Generate one row mapper shared by the query builder and repository.
    buffer.writeln(_rowMapperGenerator.generate(tableInfo));
    buffer.writeln();

    // Generate query builder
    buffer.writeln(_queryBuilderGenerator.generate(tableInfo));
    buffer.writeln();

    // Generate repository
    buffer.writeln(_repositoryGenerator.generate(tableInfo));

    // LibraryBuilder/source_gen formats the complete generated part.
    return buffer.toString();
  }
}
