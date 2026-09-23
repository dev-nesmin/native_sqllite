/// Configuration for opening a SQLite database.
class DatabaseConfig {
  /// The name of the database file (without extension).
  final String name;

  /// The database version for migrations.
  final int version;

  /// SQL statements to execute when creating the database for the first time.
  final List<String>? onCreate;

  /// SQL statements to execute on every upgrade, after the applicable
  /// [migrations] steps (e.g. idempotent `CREATE ... IF NOT EXISTS`).
  final List<String>? onUpgrade;

  /// Versioned migration steps: `migrations[v]` upgrades a database from
  /// version `v - 1` to `v`.
  ///
  /// When an existing database at version `old` is opened with [version],
  /// every step `old + 1 .. version` runs in ascending order, followed by
  /// [onUpgrade], in a single transaction with foreign keys disabled (so
  /// table rebuilds can't cascade), and must leave no foreign key violations.
  /// Android, iOS and web apply exactly the same rules.
  final Map<int, List<String>>? migrations;

  /// Whether to enable Write-Ahead Logging (WAL) mode.
  ///
  /// WAL mode allows concurrent reads and writes, which is essential
  /// when both native code and Flutter code access the database.
  ///
  /// Defaults to true.
  final bool enableWAL;

  /// Whether to enable foreign key constraints.
  ///
  /// Defaults to true.
  final bool enableForeignKeys;

  const DatabaseConfig({
    required this.name,
    this.version = 1,
    this.onCreate,
    this.onUpgrade,
    this.migrations,
    this.enableWAL = true,
    this.enableForeignKeys = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'onCreate': onCreate,
      'onUpgrade': onUpgrade,
      'migrations': migrations,
      'enableWAL': enableWAL,
      'enableForeignKeys': enableForeignKeys,
    };
  }

  factory DatabaseConfig.fromMap(Map<String, dynamic> map) {
    return DatabaseConfig(
      name: map['name'] as String,
      version: map['version'] as int? ?? 1,
      onCreate: (map['onCreate'] as List<dynamic>?)?.cast<String>(),
      onUpgrade: (map['onUpgrade'] as List<dynamic>?)?.cast<String>(),
      migrations: (map['migrations'] as Map<dynamic, dynamic>?)?.map(
        (version, sql) =>
            MapEntry(version as int, (sql as List<dynamic>).cast<String>()),
      ),
      enableWAL: map['enableWAL'] as bool? ?? true,
      enableForeignKeys: map['enableForeignKeys'] as bool? ?? true,
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
        enableWAL == other.enableWAL &&
        enableForeignKeys == other.enableForeignKeys;
  }

  @override
  int get hashCode {
    return Object.hash(name, version, enableWAL, enableForeignKeys);
  }
}
