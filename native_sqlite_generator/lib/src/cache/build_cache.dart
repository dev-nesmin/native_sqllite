import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Manages build cache to enable incremental builds.
///
/// This class stores hashes of source files to detect changes
/// and skip regeneration when files haven't changed.
class BuildCache {
  final String cacheDir;
  late final File _cacheFile;
  late Map<String, String> _cache;
  bool _modified = false;

  /// Creates a new build cache.
  ///
  /// [cacheDir] - Directory to store cache file (e.g., '.dart_tool/native_sqlite_generator')
  BuildCache(this.cacheDir) {
    _cacheFile = File(path.join(cacheDir, 'build_cache.json'));
    _loadCache();
  }

  /// Loads the cache from disk.
  void _loadCache() {
    if (_cacheFile.existsSync()) {
      try {
        final json = jsonDecode(_cacheFile.readAsStringSync());
        _cache = Map<String, String>.from(json);
      } catch (e) {
        print('⚠️  Failed to load cache: $e');
        _cache = {};
      }
    } else {
      _cache = {};
    }
  }

  /// Saves the cache to disk if it has been modified.
  void save() {
    if (!_modified) return;

    try {
      _cacheFile.parent.createSync(recursive: true);
      _cacheFile.writeAsStringSync(jsonEncode(_cache));
      _modified = false;
    } catch (e) {
      print('⚠️  Failed to save cache: $e');
    }
  }

  /// Checks if a file needs regeneration based on its content.
  ///
  /// Returns `true` if the file has changed or is new.
  /// Returns `false` if the file is unchanged and can be skipped.
  bool needsRegeneration(String sourceFile, String sourceContent) {
    final hash = _hashContent(sourceContent);
    final previousHash = _cache[sourceFile];

    if (previousHash == null || previousHash != hash) {
      _cache[sourceFile] = hash;
      _modified = true;
      return true;
    }

    return false;
  }

  /// Generates a hash of the source content.
  ///
  /// Normalizes the content by removing comments and excess whitespace
  /// to avoid unnecessary regeneration for cosmetic changes.
  String _hashContent(String content) {
    final normalized = _normalizeSource(content);
    return md5.convert(utf8.encode(normalized)).toString();
  }

  /// Normalizes source code for hashing.
  ///
  /// Removes:
  /// - Single-line comments (//)
  /// - Multi-line comments (/* */)
  /// - Excess whitespace
  ///
  /// This ensures only semantic changes trigger regeneration.
  String _normalizeSource(String source) {
    return source
        // Remove single-line comments
        .replaceAll(RegExp(r'//.*$', multiLine: true), '')
        // Remove multi-line comments
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Invalidates a specific file in the cache.
  ///
  /// Use this to force regeneration of a specific file.
  void invalidate(String sourceFile) {
    if (_cache.remove(sourceFile) != null) {
      _modified = true;
    }
  }

  /// Clears the entire cache.
  ///
  /// This forces all files to be regenerated on the next build.
  void clear() {
    _cache.clear();
    _modified = true;

    if (_cacheFile.existsSync()) {
      try {
        _cacheFile.deleteSync();
      } catch (e) {
        print('⚠️  Failed to delete cache file: $e');
      }
    }
  }

  /// Gets cache statistics.
  CacheStats getStats() {
    return CacheStats(
      totalEntries: _cache.length,
      cacheFile: _cacheFile.path,
      exists: _cacheFile.existsSync(),
      size: _cacheFile.existsSync() ? _cacheFile.lengthSync() : 0,
    );
  }

  /// Returns a list of cached files.
  List<String> getCachedFiles() {
    return _cache.keys.toList();
  }
}

/// Statistics about the build cache.
class CacheStats {
  final int totalEntries;
  final String cacheFile;
  final bool exists;
  final int size;

  CacheStats({
    required this.totalEntries,
    required this.cacheFile,
    required this.exists,
    required this.size,
  });

  @override
  String toString() {
    return '''
Cache Statistics:
  Total entries: $totalEntries
  Cache file: $cacheFile
  Exists: $exists
  Size: ${_formatBytes(size)}
''';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
