import 'dart:io';

/// The production annotation package, exposed as in-memory assets for
/// `build_test`.
///
/// Keeping the fixtures tied to the real source prevents generator tests from
/// silently accepting an annotation API that users cannot actually compile.
final Map<String, Object> realAnnotationsPackage = _readAnnotationSources();

Map<String, Object> _readAnnotationSources() {
  final packageDirectory = Directory('../native_sqlite_annotations/lib');
  if (!packageDirectory.existsSync()) {
    throw StateError(
      'Run generator tests from the native_sqlite_generator package root; '
      '${packageDirectory.absolute.path} does not exist.',
    );
  }

  final files =
      packageDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  return {
    for (final file in files)
      'native_sqlite_annotations|lib/'
          '${file.path.substring(packageDirectory.path.length + 1)}': file
          .readAsStringSync()
          .replaceAll("import 'package:meta/meta_meta.dart';\n", '')
          .replaceAll('@Target({TargetKind.classType})\n', ''),
  };
}
