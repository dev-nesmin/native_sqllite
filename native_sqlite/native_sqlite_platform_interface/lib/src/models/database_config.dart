import 'collection_equality.dart';

/// Configuration for opening a SQLite database.
class DatabaseConfig {
  /// The name of the database file (without extension).
  final String name;

  /// The database version for migrations.
  final int version;

  /// SQL statements to execute when creating the database for the first time.
  ///
  /// Each list entry must contain exactly one executable SQL statement. Put
  /// multiple statements in separate entries so every platform applies the
  /// same transaction and error behavior.
  final List<String>? onCreate;

  /// SQL statements to execute on every upgrade, after the applicable
  /// [migrations] steps (e.g. idempotent `CREATE ... IF NOT EXISTS`).
  /// Each list entry must contain exactly one executable SQL statement.
  final List<String>? onUpgrade;

  /// SQL statements applied after built-in connection configuration.
  ///
  /// Use single-statement PRAGMAs here. They run whenever a new platform
  /// connection is opened, after schema creation or migration.
  final List<String>? onConfigure;

  /// Versioned migration steps: `migrations[v]` upgrades a database from
  /// version `v - 1` to `v`.
  ///
  /// When an existing database at version `old` is opened with [version],
  /// every step `old + 1 .. version` runs in ascending order, followed by
  /// [onUpgrade], in a single transaction with foreign keys disabled (so
  /// table rebuilds can't cascade), and must leave no foreign key violations.
  /// Every platform implementation applies exactly the same rules.
  /// Each list entry must contain exactly one executable SQL statement.
  final Map<int, List<String>>? migrations;

  /// Whether to enable Write-Ahead Logging (WAL) mode.
  ///
  /// WAL can improve read/write overlap on Android and iOS. Same-process
  /// native and Flutter access is serialized independently of this setting.
  /// Web falls back to MEMORY journal mode.
  ///
  /// Defaults to true.
  final bool enableWAL;

  /// Whether to enable foreign key constraints.
  ///
  /// Defaults to true.
  final bool enableForeignKeys;

  /// Time in milliseconds SQLite waits for a busy database before failing.
  final int busyTimeout;

  /// Whether to open an existing database without write permission.
  ///
  /// Read-only opens never create or migrate a database and fail when its
  /// `user_version` differs from [version].
  final bool readOnly;

  /// Optional absolute directory for the database file on native platforms.
  ///
  /// The platform app must have permission to access this directory. This is
  /// unsupported on web and mutually exclusive with [iosAppGroup].
  final String? directory;

  /// Optional iOS App Group identifier whose shared container stores the file.
  ///
  /// The App Group must be present in the application's entitlements. This is
  /// unsupported on Android/web and mutually exclusive with [directory].
  final String? iosAppGroup;

  /// Creates validated database open configuration.
  DatabaseConfig({
    required this.name,
    this.version = 1,
    this.onCreate,
    this.onUpgrade,
    this.onConfigure,
    this.migrations,
    this.enableWAL = true,
    this.enableForeignKeys = true,
    this.busyTimeout = 5000,
    this.readOnly = false,
    this.directory,
    this.iosAppGroup,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'must contain only ASCII letters, digits, underscores, and hyphens',
      );
    }
    if (version < 1) {
      throw RangeError.range(version, 1, null, 'version');
    }
    if (busyTimeout < 0 || busyTimeout > 0x7fffffff) {
      throw RangeError.range(busyTimeout, 0, 0x7fffffff, 'busyTimeout');
    }
    if (directory != null && !directory!.startsWith('/')) {
      throw ArgumentError.value(directory, 'directory', 'must be absolute');
    }
    if (directory != null && directory!.trim().isEmpty) {
      throw ArgumentError.value(directory, 'directory', 'must not be empty');
    }
    if (iosAppGroup != null && iosAppGroup!.trim().isEmpty) {
      throw ArgumentError.value(
        iosAppGroup,
        'iosAppGroup',
        'must not be empty',
      );
    }
    if (directory != null && iosAppGroup != null) {
      throw ArgumentError('directory and iosAppGroup are mutually exclusive');
    }
  }

  /// Encodes this configuration for a platform channel call.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'onCreate': onCreate,
      'onUpgrade': onUpgrade,
      'onConfigure': onConfigure,
      'migrations': migrations,
      'enableWAL': enableWAL,
      'enableForeignKeys': enableForeignKeys,
      'busyTimeout': busyTimeout,
      'readOnly': readOnly,
      'directory': directory,
      'iosAppGroup': iosAppGroup,
    };
  }

  /// Decodes configuration received through a platform channel.
  factory DatabaseConfig.fromMap(Map<String, dynamic> map) {
    return DatabaseConfig(
      name: map['name'] as String,
      version: map['version'] as int? ?? 1,
      onCreate: (map['onCreate'] as List<dynamic>?)?.cast<String>(),
      onUpgrade: (map['onUpgrade'] as List<dynamic>?)?.cast<String>(),
      onConfigure: (map['onConfigure'] as List<dynamic>?)?.cast<String>(),
      migrations: (map['migrations'] as Map<dynamic, dynamic>?)?.map(
        (version, sql) =>
            MapEntry(version as int, (sql as List<dynamic>).cast<String>()),
      ),
      enableWAL: map['enableWAL'] as bool? ?? true,
      enableForeignKeys: map['enableForeignKeys'] as bool? ?? true,
      busyTimeout: map['busyTimeout'] as int? ?? 5000,
      readOnly: map['readOnly'] as bool? ?? false,
      directory: map['directory'] as String?,
      iosAppGroup: map['iosAppGroup'] as String?,
    );
  }

  /// Statements that upgrade a database from [oldVersion] to [version]:
  /// the [migrations] steps in version order, then [onUpgrade].
  List<String> upgradeStatements(int oldVersion) {
    return [
      for (var v = oldVersion + 1; v <= version; v++) ...?migrations?[v],
      ...?onUpgrade,
    ];
  }

  /// Whether this configuration can share an already-open connection.
  ///
  /// SQL formatting and comments are ignored, but statement order and every
  /// behavioral setting must match.
  bool hasSameOpenConfiguration(DatabaseConfig other) {
    return name == other.name &&
        version == other.version &&
        _sqlListsMatch(onCreate, other.onCreate) &&
        _sqlListsMatch(onUpgrade, other.onUpgrade) &&
        _sqlListsMatch(onConfigure, other.onConfigure) &&
        _migrationMapsMatch(migrations, other.migrations) &&
        enableWAL == other.enableWAL &&
        enableForeignKeys == other.enableForeignKeys &&
        busyTimeout == other.busyTimeout &&
        readOnly == other.readOnly &&
        directory == other.directory &&
        iosAppGroup == other.iosAppGroup;
  }

  @override
  String toString() {
    return 'DatabaseConfig(name: $name, version: $version, '
        'enableWAL: $enableWAL, enableForeignKeys: $enableForeignKeys)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DatabaseConfig) return false;
    return name == other.name &&
        version == other.version &&
        deepCollectionEquals(onCreate, other.onCreate) &&
        deepCollectionEquals(onUpgrade, other.onUpgrade) &&
        deepCollectionEquals(onConfigure, other.onConfigure) &&
        deepCollectionEquals(migrations, other.migrations) &&
        enableWAL == other.enableWAL &&
        enableForeignKeys == other.enableForeignKeys &&
        busyTimeout == other.busyTimeout &&
        readOnly == other.readOnly &&
        directory == other.directory &&
        iosAppGroup == other.iosAppGroup;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      version,
      deepCollectionHash(onCreate),
      deepCollectionHash(onUpgrade),
      deepCollectionHash(onConfigure),
      deepCollectionHash(migrations),
      enableWAL,
      enableForeignKeys,
      busyTimeout,
      readOnly,
      directory,
      iosAppGroup,
    );
  }
}

bool _sqlListsMatch(List<String>? left, List<String>? right) {
  if (left == null || right == null) return left == right;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (_sqlTokens(left[index]) != _sqlTokens(right[index])) return false;
  }
  return true;
}

bool _migrationMapsMatch(
  Map<int, List<String>>? left,
  Map<int, List<String>>? right,
) {
  if (left == null || right == null) return left == right;
  if (left.length != right.length ||
      !left.keys.toSet().containsAll(right.keys)) {
    return false;
  }
  return left.entries.every(
    (entry) => _sqlListsMatch(entry.value, right[entry.key]),
  );
}

String _sqlTokens(String sql) {
  final tokens = <String>[];
  var index = 0;
  while (index < sql.length) {
    final char = sql[index];
    if (RegExp(r'\s').hasMatch(char)) {
      index++;
      continue;
    }
    if (char == '-' && index + 1 < sql.length && sql[index + 1] == '-') {
      index += 2;
      while (index < sql.length && sql[index] != '\n' && sql[index] != '\r') {
        index++;
      }
      continue;
    }
    if (char == '/' && index + 1 < sql.length && sql[index + 1] == '*') {
      index += 2;
      while (index + 1 < sql.length &&
          !(sql[index] == '*' && sql[index + 1] == '/')) {
        index++;
      }
      index = (index + 2).clamp(0, sql.length);
      continue;
    }
    if (char == "'" || char == '"' || char == '`') {
      final start = index++;
      while (index < sql.length) {
        if (sql[index] == char) {
          if (index + 1 < sql.length && sql[index + 1] == char) {
            index += 2;
          } else {
            index++;
            break;
          }
        } else {
          index++;
        }
      }
      tokens.add(sql.substring(start, index));
      continue;
    }
    if (char == '[') {
      final start = index++;
      while (index < sql.length && sql[index] != ']') {
        index++;
      }
      if (index < sql.length) index++;
      tokens.add(sql.substring(start, index));
      continue;
    }
    if (RegExp(r'[A-Za-z0-9_\$]').hasMatch(char)) {
      final start = index++;
      while (index < sql.length &&
          RegExp(r'[A-Za-z0-9_\$]').hasMatch(sql[index])) {
        index++;
      }
      tokens.add(sql.substring(start, index));
      continue;
    }
    tokens.add(char);
    index++;
  }
  return tokens.join('\u001f');
}
