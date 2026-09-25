import 'dart:io';

import 'package:yaml/yaml.dart';

/// Configuration for native code generation and the shared database name.
class NativeSqliteConfig {
  final bool generateNative;
  final AndroidConfig android;
  final IosConfig ios;
  final String databaseName;
  final bool includeExamples;
  final String nativeTypePrefix;

  /// Database name used when `database_name` isn't configured, by both the
  /// generated Dart and native DatabaseManagers.
  static const defaultDatabaseName = 'app_database';

  const NativeSqliteConfig({
    required this.generateNative,
    required this.android,
    required this.ios,
    required this.databaseName,
    required this.includeExamples,
    this.nativeTypePrefix = '',
  });

  /// Loads `native_sqlite_config.yaml`, falling back to the exact top-level
  /// `native_sqlite` mapping in pubspec.yaml. Missing configuration returns
  /// null; malformed or unknown configuration fails with a useful message.
  static Future<NativeSqliteConfig?> load() async {
    var configFile = File('native_sqlite_config.yaml');
    final dedicatedConfig = configFile.existsSync();
    if (!dedicatedConfig) {
      configFile = File('pubspec.yaml');
      if (!configFile.existsSync()) return null;
    }

    return parse(
      await configFile.readAsString(),
      source: configFile.path,
      requireNativeSqlite: dedicatedConfig,
    );
  }

  /// Parses configuration content. Exposed for deterministic validation tests
  /// and tooling that already owns the file contents.
  static NativeSqliteConfig? parse(
    String content, {
    String source = 'configuration',
    bool requireNativeSqlite = false,
  }) {
    final document = loadYaml(content);
    if (document == null) {
      if (requireNativeSqlite) {
        throw FormatException('$source is empty.');
      }
      return null;
    }
    final root = _mapping(document, source);
    final rawConfig = root['native_sqlite'];
    if (rawConfig == null) {
      if (requireNativeSqlite) {
        throw FormatException('$source must contain a native_sqlite mapping.');
      }
      return null;
    }

    final config = _mapping(rawConfig, 'native_sqlite');
    _rejectUnknown(config, 'native_sqlite', const {
      'generate_native',
      'database_name',
      'include_examples',
      'native_type_prefix',
      'android',
      'ios',
    });

    final databaseName = _string(
      config,
      'database_name',
      defaultValue: defaultDatabaseName,
      allowEmpty: false,
    );
    final nativeTypePrefix = _string(
      config,
      'native_type_prefix',
      defaultValue: '',
    );
    if (nativeTypePrefix.isNotEmpty &&
        !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(nativeTypePrefix)) {
      throw FormatException(
        'native_sqlite.native_type_prefix must be a valid Kotlin/Swift '
        'identifier prefix; got "$nativeTypePrefix".',
      );
    }

    return NativeSqliteConfig(
      generateNative: _boolean(config, 'generate_native', defaultValue: false),
      android: AndroidConfig.fromYaml(config['android']),
      ios: IosConfig.fromYaml(config['ios']),
      databaseName: databaseName,
      includeExamples: _boolean(config, 'include_examples', defaultValue: true),
      nativeTypePrefix: nativeTypePrefix,
    );
  }
}

/// Android-specific configuration.
class AndroidConfig {
  final bool enabled;
  final String outputPath;
  final String package;
  final bool generateHelpers;

  const AndroidConfig({
    required this.enabled,
    required this.outputPath,
    required this.package,
    required this.generateHelpers,
  });

  factory AndroidConfig.fromYaml(Object? yaml) {
    if (yaml == null) {
      return const AndroidConfig(
        enabled: false,
        outputPath: 'android/app/src/main/kotlin/generated',
        package: 'generated',
        generateHelpers: true,
      );
    }

    final config = _mapping(yaml, 'native_sqlite.android');
    _rejectUnknown(config, 'native_sqlite.android', const {
      'enabled',
      'output_path',
      'package',
      'generate_helpers',
    });
    final package = _string(
      config,
      'package',
      defaultValue: 'generated',
      allowEmpty: false,
    );
    if (!RegExp(
      r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$',
    ).hasMatch(package)) {
      throw FormatException(
        'native_sqlite.android.package must be a valid Kotlin package; '
        'got "$package".',
      );
    }

    return AndroidConfig(
      enabled: _boolean(config, 'enabled', defaultValue: true),
      outputPath: _string(
        config,
        'output_path',
        defaultValue: 'android/app/src/main/kotlin/generated',
        allowEmpty: false,
      ),
      package: package,
      generateHelpers: _boolean(config, 'generate_helpers', defaultValue: true),
    );
  }
}

/// iOS-specific configuration.
class IosConfig {
  final bool enabled;
  final String outputPath;
  final bool generateHelpers;

  const IosConfig({
    required this.enabled,
    required this.outputPath,
    required this.generateHelpers,
  });

  factory IosConfig.fromYaml(Object? yaml) {
    if (yaml == null) {
      return const IosConfig(
        enabled: false,
        outputPath: 'ios/Runner/Generated',
        generateHelpers: true,
      );
    }

    final config = _mapping(yaml, 'native_sqlite.ios');
    _rejectUnknown(config, 'native_sqlite.ios', const {
      'enabled',
      'output_path',
      'generate_helpers',
    });
    return IosConfig(
      enabled: _boolean(config, 'enabled', defaultValue: true),
      outputPath: _string(
        config,
        'output_path',
        defaultValue: 'ios/Runner/Generated',
        allowEmpty: false,
      ),
      generateHelpers: _boolean(config, 'generate_helpers', defaultValue: true),
    );
  }
}

Map<String, dynamic> _mapping(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be a YAML mapping.');
  }
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _rejectUnknown(
  Map<String, dynamic> config,
  String path,
  Set<String> supported,
) {
  final unknown = config.keys.where((key) => !supported.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw FormatException(
      '$path contains unknown option(s): ${unknown.join(', ')}. '
      'Supported options: ${supported.join(', ')}.',
    );
  }
}

bool _boolean(
  Map<String, dynamic> config,
  String key, {
  required bool defaultValue,
}) {
  final value = config[key];
  if (value == null) return defaultValue;
  if (value is bool) return value;
  throw FormatException('$key must be a boolean; got $value.');
}

String _string(
  Map<String, dynamic> config,
  String key, {
  required String defaultValue,
  bool allowEmpty = true,
}) {
  final value = config[key];
  if (value == null) return defaultValue;
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    throw FormatException(
      '$key must be a${allowEmpty ? '' : ' non-empty'} string.',
    );
  }
  return value;
}
