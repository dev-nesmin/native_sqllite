import 'dart:async';
import 'dart:io';
import 'package:build/build.dart';
import 'native_generator.dart';

/// Post-process builder that runs after all other builders
/// to automatically generate native code
class NativeCodePostProcessBuilder implements PostProcessBuilder {
  // Completer to ensure only one execution per build session
  // Using timestamp to allow execution in new build sessions (e.g., watch mode)
  static Completer<void>? _generationCompleter;
  static DateTime? _lastRunTime;

  @override
  final inputExtensions = const ['.table.dart'];

  @override
  FutureOr<void> build(PostProcessBuildStep buildStep) async {
    // Only trigger on generated table files
    if (!buildStep.inputId.path.endsWith('.table.dart')) {
      return;
    }

    // Reset state if it's been more than 5 seconds since last run
    // (indicates a new build session, e.g., in watch mode)
    if (_lastRunTime != null &&
        DateTime.now().difference(_lastRunTime!) > Duration(seconds: 5)) {
      _generationCompleter = null;
      _lastRunTime = null;
    }

    // If already running in this build session, wait for completion
    if (_generationCompleter != null) {
      return _generationCompleter!.future;
    }

    // Mark as running
    _generationCompleter = Completer<void>();
    _lastRunTime = DateTime.now();

    try {
      // Check if we should run native generation
      final shouldGenerate = await _shouldGenerateNativeCode();
      if (!shouldGenerate) {
        _generationCompleter!.complete();
        return;
      }

      log.info('');
      log.info('🔧 Running native code generation after build...');

      final generator = NativeCodeGenerator();
      // IMPORTANT: Pass runBuildRunner: false to avoid recursion
      // since we're already inside a build_runner run
      await generator.generate(runBuildRunner: false);

      log.info('✓ Native code generation completed');
      log.info('');

      _generationCompleter!.complete();
    } catch (e) {
      log.warning('⚠️  Native code generation failed: $e');
      _generationCompleter!.completeError(e);
    }
  }

  Future<bool> _shouldGenerateNativeCode() async {
    // Prefer native_sqlite_config.yaml, fall back to pubspec.yaml
    final configFile = File('native_sqlite_config.yaml');
    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      return content.contains('generate_native:') &&
          content.contains('generate_native: true');
    }

    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      return false;
    }
    final content = await pubspecFile.readAsString();
    return content.contains('native_sqlite:') &&
        content.contains('generate_native: true');
  }
}

/// Builder for the post-process hook
PostProcessBuilder nativeCodePostBuilder(BuilderOptions options) {
  return NativeCodePostProcessBuilder();
}
