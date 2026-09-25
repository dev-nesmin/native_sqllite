import 'dart:io';

void main(List<String> arguments) {
  final path =
      arguments.singleOrNull ??
      'native_sqlite/native_sqlite/extension/devtools/build/'
          'flutter_bootstrap.js';
  final file = File(path);
  final source = file.readAsStringSync();
  final normalized = source.replaceFirst(
    RegExp(r'serviceWorkerVersion: "[^"]+"'),
    'serviceWorkerVersion: "native-sqlite-v1"',
  );
  if (identical(source, normalized) || source == normalized) {
    if (!source.contains('serviceWorkerVersion: "native-sqlite-v1"')) {
      stderr.writeln('Could not find the Flutter service-worker build token.');
      exitCode = 1;
    }
    return;
  }
  file.writeAsStringSync(normalized);
}
