import 'dart:io';

import 'package:crypto/crypto.dart';

const _knownDigests = <String, String>{
  '2.9.4': '922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117',
};

void main() {
  final lockfile = File('pubspec.lock');
  final wasm = File('example/web/sqlite3.wasm');
  if (!lockfile.existsSync() || !wasm.existsSync()) {
    stderr.writeln('Run this command from the repository root after pub get.');
    exitCode = 1;
    return;
  }

  final match = RegExp(
    r'^  sqlite3:\n(?:(?:    ).*\n)*?    version: "([^"]+)"$',
    multiLine: true,
  ).firstMatch(lockfile.readAsStringSync());
  if (match == null) {
    stderr.writeln('Could not find sqlite3 in pubspec.lock.');
    exitCode = 1;
    return;
  }

  final version = match.group(1)!;
  final expected = _knownDigests[version];
  if (expected == null) {
    stderr.writeln(
      'No approved sqlite3.wasm digest is recorded for sqlite3 $version.\n'
      'Download the matching release asset, verify it, and update '
      'tool/check_web_wasm.dart.',
    );
    exitCode = 1;
    return;
  }

  final actual = sha256.convert(wasm.readAsBytesSync()).toString();
  if (actual != expected) {
    stderr.writeln(
      'example/web/sqlite3.wasm does not match sqlite3 $version.\n'
      'Expected: $expected\n'
      'Actual:   $actual\n'
      'Source: https://github.com/simolus3/sqlite3.dart/releases/download/'
      'sqlite3-$version/sqlite3.wasm',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('sqlite3.wasm matches sqlite3 $version ($actual).');
}
