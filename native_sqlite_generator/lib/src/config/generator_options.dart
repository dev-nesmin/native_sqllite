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
///           table_name_case: snake
///           # ... more options
/// ```
class GeneratorOptions {
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

  /// Whether to include verbose logging during generation
  final bool verbose;

  const GeneratorOptions({
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
    this.includeTimestamp = false,
    this.includeStatistics = false,
    this.verbose = false,
  });

  /// Creates a [GeneratorOptions] instance from [BuilderOptions].
  ///
  /// This parses the build.yaml configuration and provides sensible defaults.
  factory GeneratorOptions.fromOptions(BuilderOptions options) {
    final config = options.config;
    const supported = {
      'ignore_for_file',
      'table_name_case',
      'column_name_case',
      'include_timestamp',
      'include_statistics',
      'verbose',
    };
    final unknown = config.keys.where((key) => !supported.contains(key));
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Unknown native_sqlite_generator option(s): ${unknown.join(', ')}. '
        'Supported options: ${supported.join(', ')}.',
      );
    }

    final tableNameCase = _string(
      config,
      'table_name_case',
      defaultValue: 'snake',
    );
    final columnNameCase = _string(
      config,
      'column_name_case',
      defaultValue: 'snake',
    );
    const namingCases = {'snake', 'camel', 'pascal', 'none'};
    if (!namingCases.contains(tableNameCase)) {
      throw ArgumentError.value(
        tableNameCase,
        'table_name_case',
        'must be one of ${namingCases.join(', ')}',
      );
    }
    if (!namingCases.contains(columnNameCase)) {
      throw ArgumentError.value(
        columnNameCase,
        'column_name_case',
        'must be one of ${namingCases.join(', ')}',
      );
    }

    return GeneratorOptions(
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
      tableNameCase: tableNameCase,
      columnNameCase: columnNameCase,
      includeTimestamp: _boolean(
        config,
        'include_timestamp',
        defaultValue: false,
      ),
      includeStatistics: _boolean(
        config,
        'include_statistics',
        defaultValue: false,
      ),
      verbose: _boolean(config, 'verbose', defaultValue: false),
    );
  }

  /// Helper to parse list of strings from config
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>();
    }
    throw ArgumentError.value(
      value,
      'ignore_for_file',
      'must be a list of strings',
    );
  }

  static bool _boolean(
    Map<String, dynamic> config,
    String key, {
    required bool defaultValue,
  }) {
    final value = config[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    throw ArgumentError.value(value, key, 'must be a boolean');
  }

  static String _string(
    Map<String, dynamic> config,
    String key, {
    required String defaultValue,
  }) {
    final value = config[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    throw ArgumentError.value(value, key, 'must be a string');
  }

  /// Converts options to JSON for debugging/logging
  Map<String, dynamic> toJson() => {
    'ignore_for_file': ignoreForFile,
    'table_name_case': tableNameCase,
    'column_name_case': columnNameCase,
    'include_timestamp': includeTimestamp,
    'include_statistics': includeStatistics,
    'verbose': verbose,
  };

  @override
  String toString() => 'GeneratorOptions${toJson()}';
}
