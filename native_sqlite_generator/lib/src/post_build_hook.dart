import 'dart:async';
import 'package:build/build.dart';

import 'config.dart';
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
    // migration must run before us.
    final schemaAsset = AssetId(
      buildStep.inputId.package,
      'lib/generated/native_sqlite_schema.json',
    );

    if (!await buildStep.canRead(schemaAsset)) {
      throw StateError(
        'native_sqlite_schema.json is missing; native code generation cannot '
        'safely guess the database schema or version.',
      );
    }

    // Read through the build system — this declares the dependency on migration
    // and gives us the content without any dart:io timing uncertainty.
    final schemaJson = await buildStep.readAsString(schemaAsset);

    log.info('');
    log.info('🔧 Running native code generation...');

    final generator = NativeCodeGenerator();
    // Pass the already-read schema content so the generator never touches
    // dart:io for reading (the file may not be flushed to disk yet during
    // a build session even though build_to:source is configured).
    await generator.generateFromSchemaContent(schemaJson);

    log.info('Native code generation completed');
    log.info('');

    await _writeStamp(buildStep, 'schema-fnv1a32:${_contentHash(schemaJson)}');
  }

  Future<void> _writeStamp(BuildStep buildStep, String content) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/generated/.native_sqlite_stamp'),
      content,
    );
  }

  String _contentHash(String content) {
    var hash = 0x811c9dc5;
    for (final codeUnit in content.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<bool> _shouldGenerateNativeCode() async {
    return (await NativeSqliteConfig.load())?.generateNative ?? false;
  }
}
