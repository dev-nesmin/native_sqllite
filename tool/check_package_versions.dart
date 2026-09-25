import 'dart:io';

void main() {
  const packagePubspec = 'native_sqlite/native_sqlite_ios/pubspec.yaml';
  const podspec =
      'native_sqlite/native_sqlite_ios/ios/native_sqlite_ios.podspec';

  final pubVersion = _firstMatch(
    packagePubspec,
    RegExp(r'^version:\s*([^\s]+)', multiLine: true),
  );
  final podVersion = _firstMatch(
    podspec,
    RegExp(r"s\.version\s*=\s*'([^']+)'"),
  );

  if (pubVersion != podVersion) {
    stderr.writeln(
      'Version mismatch: $packagePubspec is $pubVersion but $podspec is '
      '$podVersion.',
    );
    exitCode = 1;
  }
}

String _firstMatch(String path, RegExp pattern) {
  final match = pattern.firstMatch(File(path).readAsStringSync());
  if (match == null) {
    stderr.writeln('Could not read a version from $path.');
    exit(1);
  }
  return match.group(1)!;
}
