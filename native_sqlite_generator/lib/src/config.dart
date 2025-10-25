import 'dart:io';
import 'package:yaml/yaml.dart';

/// Configuration for native code generation
class NativeSqliteConfig {
  final bool generateNative;
  final AndroidConfig android;
  final IosConfig ios;
  final List<String> models;
  final String databaseName;
  final bool includeExamples;

  const NativeSqliteConfig({
    required this.generateNative,
    required this.android,
    required this.ios,
    required this.models,
    required this.databaseName,
    required this.includeExamples,
  });

  /// Load configuration from pubspec.yaml or native_sqlite_config.yaml
  static Future<NativeSqliteConfig?> load() async {
    // Try loading from native_sqlite_config.yaml first
    var configFile = File('native_sqlite_config.yaml');

    if (!configFile.existsSync()) {
      // Try loading from pubspec.yaml
      configFile = File('pubspec.yaml');
      if (!configFile.existsSync()) {
        return null;
      }
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as Map;

    final nativeConfig = yaml['native_sqlite'];
    if (nativeConfig == null) {
      return null;
    }

    return NativeSqliteConfig(
      generateNative: nativeConfig['generate_native'] ?? false,
      android: AndroidConfig.fromYaml(nativeConfig['android']),
      ios: IosConfig.fromYaml(nativeConfig['ios']),
      models: (nativeConfig['models'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      databaseName: nativeConfig['database_name'] ?? 'app_db',
      includeExamples: nativeConfig['include_examples'] ?? true,
    );
  }
}

/// Android-specific configuration
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

  factory AndroidConfig.fromYaml(Map? yaml) {
    if (yaml == null) {
      return const AndroidConfig(
        enabled: false,
        outputPath: 'android/app/src/main/kotlin/generated',
        package: 'generated',
        generateHelpers: true,
      );
    }

    return AndroidConfig(
      enabled: yaml['enabled'] ?? true,
      outputPath: yaml['output_path'] ?? 'android/app/src/main/kotlin/generated',
      package: yaml['package'] ?? 'generated',
      generateHelpers: yaml['generate_helpers'] ?? true,
    );
  }
}

/// iOS-specific configuration
class IosConfig {
  final bool enabled;
  final String outputPath;
  final bool generateHelpers;

  const IosConfig({
    required this.enabled,
    required this.outputPath,
    required this.generateHelpers,
  });

  factory IosConfig.fromYaml(Map? yaml) {
    if (yaml == null) {
      return const IosConfig(
        enabled: false,
        outputPath: 'ios/Runner/Generated',
        generateHelpers: true,
      );
    }

    return IosConfig(
      enabled: yaml['enabled'] ?? true,
      outputPath: yaml['output_path'] ?? 'ios/Runner/Generated',
      generateHelpers: yaml['generate_helpers'] ?? true,
    );
  }
}
