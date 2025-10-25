/// Configuration for opening a SQLite database.
class DatabaseConfig {
  /// The name of the database file (without extension).
  final String name;

  /// The database version for migrations.
  final int version;

  /// SQL statements to execute when creating the database for the first time.
  final List<String>? onCreate;

  /// SQL statements to execute when upgrading the database.
  final List<String>? onUpgrade;

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
    this.enableWAL = true,
    this.enableForeignKeys = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'onCreate': onCreate,
      'onUpgrade': onUpgrade,
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
      enableWAL: map['enableWAL'] as bool? ?? true,
      enableForeignKeys: map['enableForeignKeys'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'DatabaseConfig(name: $name, version: $version, '
        'enableWAL: $enableWAL, enableForeignKeys: $enableForeignKeys)';
  }
}
