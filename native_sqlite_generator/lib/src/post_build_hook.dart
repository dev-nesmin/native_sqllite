import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';

import 'native_generator.dart';

/// A whole-library builder that generates native Android/iOS code after
/// the schema JSON has been written by the migration builder.
///
/// Reads native_sqlite_schema.json through the build system so the
/// dependency is declared correctly — guaranteeing migration runs first
/// even on the very first build.
class NativeCodeBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['generated/.native_sqlite_stamp'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    // Check config before doing any work.
    if (!await _shouldGenerateNativeCode()) {
      await _writeStamp(buildStep, 'disabled');
      return;
    }

    // Declare a dependency on the schema JSON so the build system knows
    // migration must run before us. If the file doesn't exist yet we bail
    // gracefully — next build it will be there.
    final schemaAsset = AssetId(
      buildStep.inputId.package,
      'lib/generated/native_sqlite_schema.json',
    );

    if (!await buildStep.canRead(schemaAsset)) {
      log.info('ℹ️  native_sqlite_schema.json not ready yet — '
          'native code will be generated on the next build.');
      await _writeStamp(buildStep, 'pending');
      return;
    }

    // Read through the build system — this declares the dependency on migration
    // and gives us the content without any dart:io timing uncertainty.
    final schemaJson = await buildStep.readAsString(schemaAsset);

    log.info('');
    log.info('🔧 Running native code generation...');

    try {
      final generator = NativeCodeGenerator();
      // Pass the already-read schema content so the generator never touches
      // dart:io for reading (the file may not be flushed to disk yet during
      // a build session even though build_to:source is configured).
      await generator.generateFromSchemaContent(schemaJson);

      log.info('✓ Native code generation completed');
      log.info('');

      await _writeStamp(buildStep, DateTime.now().toIso8601String());
    } catch (e, stack) {
      log.warning('⚠️  Native code generation failed: $e\n$stack');
      await _writeStamp(buildStep, 'error: $e');
    }
  }

  Future<void> _writeStamp(BuildStep buildStep, String content) async {
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        'lib/generated/.native_sqlite_stamp',
      ),
      content,
    );
  }

  Future<bool> _shouldGenerateNativeCode() async {
    // Prefer native_sqlite_config.yaml, fall back to pubspec.yaml.
    final configFile = File('native_sqlite_config.yaml');
    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      return content.contains('generate_native: true');
    }

    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) return false;
    final content = await pubspecFile.readAsString();
    return content.contains('native_sqlite:') &&
        content.contains('generate_native: true');
  }
}

Builder nativeCodeBuilder(BuilderOptions options) => NativeCodeBuilder();
