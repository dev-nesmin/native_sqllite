import 'dart:io';

import '../testing/native_sqlite_ffi.dart';
import 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart';

/// Dart-only SQLite implementation for Windows and Linux Flutter apps.
///
/// It uses the same `package:sqlite3` FFI backend and conformance-tested
/// behavior as [NativeSqliteFfi], while storing databases in a persistent
/// per-user data directory instead of a temporary test directory.
final class NativeSqliteDesktop extends NativeSqliteFfi {
  /// Creates a desktop backend, optionally overriding its storage [directory].
  NativeSqliteDesktop({String? directory})
    : super(directory: directory ?? defaultDirectory.path);

  /// Default persistent directory used by the desktop implementation.
  static Directory get defaultDirectory {
    final environment = Platform.environment;
    if (Platform.isWindows) {
      final base =
          environment['APPDATA'] ??
          '${environment['USERPROFILE'] ?? Directory.current.path}'
              '${Platform.pathSeparator}AppData'
              '${Platform.pathSeparator}Roaming';
      return Directory('$base${Platform.pathSeparator}native_sqlite');
    }
    if (Platform.isLinux) {
      final home = environment['HOME'] ?? Directory.current.path;
      final base =
          environment['XDG_DATA_HOME'] ??
          '$home${Platform.pathSeparator}.local'
              '${Platform.pathSeparator}share';
      return Directory('$base${Platform.pathSeparator}native_sqlite');
    }
    return Directory(
      '${Directory.current.path}${Platform.pathSeparator}.native_sqlite',
    );
  }

  /// Registers this Dart-only desktop implementation with Flutter.
  static void registerWith() {
    NativeSqlitePlatform.instance = NativeSqliteDesktop();
  }
}
