import 'package:build/build.dart';

/// Configuration options for the native_sqlite_generator.
///
/// These options can be configured in build.yaml:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       native_sqlite_generator:table:
///         options:
///           format: true
///           generate_helpers: true
///           table_name_case: snake
///           # ... more options
/// ```
class GeneratorOptions {
  /// Whether to format generated code using dart_style
  final bool format;

  /// Whether to generate helper methods (e.g., copyWith, toString)
  final bool generateHelpers;

  /// Whether to enable cached builds for improved performance
  final bool enableCachedBuilds;

  /// Custom output directory for generated files (relative to lib/)
  final String? outputDirectory;

  /// List of lint rules to ignore in generated files
  final List<String> ignoreForFile;

  /// Naming convention for table names: 'snake', 'camel', 'pascal'
  final String tableNameCase;

  /// Naming convention for column names: 'snake', 'camel', 'pascal'
  final String columnNameCase;

  /// Whether to include generation timestamp in file header
  final bool includeTimestamp;

  /// Whether to include statistics in generated file comments
  final bool includeStatistics;

  /// Visibility of generated classes: 'public' or 'private'
  final String classVisibility;

  /// Custom imports to add to all generated files
  final List<String> customImports;

  /// Whether to generate as part files (.g.dart) instead of separate libraries
  final bool generateAsPartFile;

  /// Whether to include verbose logging during generation
  final bool verbose;

  /// Default database name to use when not specified in @DbTable annotation
  final String? defaultDatabase;

  const GeneratorOptions({
    this.format = true,
    this.generateHelpers = true,
    this.enableCachedBuilds = true,
    this.outputDirectory,
    this.ignoreForFile = const [
      'type=lint',
      'prefer_single_quotes',
      'lines_longer_than_80_chars',
      'depend_on_referenced_packages',
      'unused_element',
      'unused_import',
    ],
    this.tableNameCase = 'snake',
    this.columnNameCase = 'snake',
    this.includeTimestamp = true,
    this.includeStatistics = false,
    this.classVisibility = 'public',
    this.customImports = const [],
    this.generateAsPartFile = false,
    this.verbose = false,
    this.defaultDatabase,
  });

  /// Creates a [GeneratorOptions] instance from [BuilderOptions].
  ///
  /// This parses the build.yaml configuration and provides sensible defaults.
  factory GeneratorOptions.fromOptions(BuilderOptions options) {
    final config = options.config;

    return GeneratorOptions(
      format: config['format'] as bool? ?? true,
      generateHelpers: config['generate_helpers'] as bool? ?? true,
      enableCachedBuilds: config['enable_cached_builds'] as bool? ?? true,
      outputDirectory: config['output_directory'] as String?,
      ignoreForFile:
          _parseStringList(config['ignore_for_file']) ??
          const [
            'type=lint',
            'prefer_single_quotes',
            'lines_longer_than_80_chars',
            'depend_on_referenced_packages',
            'unused_element',
            'unused_import',
          ],
      tableNameCase: config['table_name_case'] as String? ?? 'snake',
      columnNameCase: config['column_name_case'] as String? ?? 'snake',
      includeTimestamp: config['include_timestamp'] as bool? ?? true,
      includeStatistics: config['include_statistics'] as bool? ?? false,
      classVisibility: config['class_visibility'] as String? ?? 'public',
      customImports: _parseStringList(config['custom_imports']) ?? const [],
      generateAsPartFile: config['generate_as_part_file'] as bool? ?? false,
      verbose: config['verbose'] as bool? ?? false,
      defaultDatabase: config['default_database'] as String?,
    );
  }

  /// Helper to parse list of strings from config
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.cast<String>();
    }
    return null;
  }

  /// Converts options to JSON for debugging/logging
  Map<String, dynamic> toJson() => {
    'format': format,
    'generate_helpers': generateHelpers,
    'enable_cached_builds': enableCachedBuilds,
    'output_directory': outputDirectory,
    'ignore_for_file': ignoreForFile,
    'table_name_case': tableNameCase,
    'column_name_case': columnNameCase,
    'include_timestamp': includeTimestamp,
    'include_statistics': includeStatistics,
    'class_visibility': classVisibility,
    'custom_imports': customImports,
    'generate_as_part_file': generateAsPartFile,
    'verbose': verbose,
    'default_database': defaultDatabase,
  };

  @override
  String toString() => 'GeneratorOptions${toJson()}';
}
