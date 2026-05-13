import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';

/// Generates migration helper classes for schema versioning
class MigrationGenerator {
  /// Generate Kotlin migration helper
  String generateKotlinMigration({
    required String packageName,
    required String databaseName,
    required List<TableSchemaSnapshot> tables,
    required int fromVersion,
    required int toVersion,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('package $packageName.migrations');
    buffer.writeln();
    buffer.writeln('import dev.nesmin.native_sqlite.NativeSqliteManager');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(
      ' * Database migration from version $fromVersion to $toVersion',
    );
    buffer.writeln(' * AUTO-GENERATED - Customize as needed');
    buffer.writeln(' */');
    buffer.writeln('object Migration_${fromVersion}_${toVersion} {');
    buffer.writeln();
    buffer.writeln('    fun migrate(databaseName: String) {');
    buffer.writeln(
      '        val db = NativeSqliteManager.getDatabase(databaseName)',
    );
    buffer.writeln('        db.beginTransaction()');
    buffer.writeln('        try {');
    buffer.writeln('            // Add your migration logic here');
    buffer.writeln('            // Example: Add new column');
    buffer.writeln(
      '            // db.execSQL("ALTER TABLE users ADD COLUMN phone TEXT")',
    );
    buffer.writeln();
    buffer.writeln('            // Example: Create new table');
    buffer.writeln(
      '            // db.execSQL("CREATE TABLE IF NOT EXISTS ...")',
    );
    buffer.writeln();
    buffer.writeln('            db.setTransactionSuccessful()');
    buffer.writeln('        } finally {');
    buffer.writeln('            db.endTransaction()');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();

    // Add helper methods for common migrations
    buffer.writeln('    /**');
    buffer.writeln('     * Add a new column to a table');
    buffer.writeln('     */');
    buffer.writeln('    fun addColumn(');
    buffer.writeln('        databaseName: String,');
    buffer.writeln('        tableName: String,');
    buffer.writeln('        columnName: String,');
    buffer.writeln('        columnType: String,');
    buffer.writeln('        defaultValue: String? = null');
    buffer.writeln('    ) {');
    buffer.writeln('        val sql = buildString {');
    buffer.writeln(
      '            append("ALTER TABLE \$tableName ADD COLUMN \$columnName \$columnType")',
    );
    buffer.writeln('            defaultValue?.let { append(" DEFAULT \$it") }');
    buffer.writeln('        }');
    buffer.writeln('        NativeSqliteManager.execute(databaseName, sql)');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Rename a table');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun renameTable(databaseName: String, oldName: String, newName: String) {',
    );
    buffer.writeln('        NativeSqliteManager.execute(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            "ALTER TABLE \$oldName RENAME TO \$newName"');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln(
      '     * Copy data from old table to new table with schema changes',
    );
    buffer.writeln('     */');
    buffer.writeln('    fun migrateTableData(');
    buffer.writeln('        databaseName: String,');
    buffer.writeln('        oldTable: String,');
    buffer.writeln('        newTable: String,');
    buffer.writeln('        columnMapping: Map<String, String>');
    buffer.writeln('    ) {');
    buffer.writeln(
      '        val columns = columnMapping.entries.joinToString { "\${it.key} AS \${it.value}" }',
    );
    buffer.writeln(
      '        val sql = "INSERT INTO \$newTable SELECT \$columns FROM \$oldTable"',
    );
    buffer.writeln('        NativeSqliteManager.execute(databaseName, sql)');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate Swift migration helper
  String generateSwiftMigration({
    required String databaseName,
    required List<TableSchemaSnapshot> tables,
    required int fromVersion,
    required int toVersion,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(
      ' * Database migration from version $fromVersion to $toVersion',
    );
    buffer.writeln(' * AUTO-GENERATED - Customize as needed');
    buffer.writeln(' */');
    buffer.writeln('public class Migration_${fromVersion}_${toVersion} {');
    buffer.writeln();
    buffer.writeln(
      '    public static func migrate(databaseName: String) throws {',
    );
    buffer.writeln('        let manager = NativeSqliteManager.shared');
    buffer.writeln('        ');
    buffer.writeln(
      '        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            // Add your migration logic here');
    buffer.writeln('            // Example: Add new column');
    buffer.writeln(
      '            // try manager.execute(name: databaseName, sql: "ALTER TABLE users ADD COLUMN phone TEXT")',
    );
    buffer.writeln();
    buffer.writeln('            // Example: Create new table');
    buffer.writeln(
      '            // try manager.execute(name: databaseName, sql: "CREATE TABLE IF NOT EXISTS ...")',
    );
    buffer.writeln();
    buffer.writeln(
      '            try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            try? manager.execute(name: databaseName, sql: "ROLLBACK")',
    );
    buffer.writeln('            throw error');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();

    // Add helper methods
    buffer.writeln('    /**');
    buffer.writeln('     * Add a new column to a table');
    buffer.writeln('     */');
    buffer.writeln('    public static func addColumn(');
    buffer.writeln('        databaseName: String,');
    buffer.writeln('        tableName: String,');
    buffer.writeln('        columnName: String,');
    buffer.writeln('        columnType: String,');
    buffer.writeln('        defaultValue: String? = nil');
    buffer.writeln('    ) throws {');
    buffer.writeln(
      '        var sql = "ALTER TABLE \\(tableName) ADD COLUMN \\(columnName) \\(columnType)"',
    );
    buffer.writeln('        if let defaultValue = defaultValue {');
    buffer.writeln('            sql += " DEFAULT \\(defaultValue)"');
    buffer.writeln('        }');
    buffer.writeln(
      '        try NativeSqliteManager.shared.execute(name: databaseName, sql: sql)',
    );
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Rename a table');
    buffer.writeln('     */');
    buffer.writeln('    public static func renameTable(');
    buffer.writeln('        databaseName: String,');
    buffer.writeln('        oldName: String,');
    buffer.writeln('        newName: String');
    buffer.writeln('    ) throws {');
    buffer.writeln('        try NativeSqliteManager.shared.execute(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln(
      '            sql: "ALTER TABLE \\(oldName) RENAME TO \\(newName)"',
    );
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln(
      '     * Copy data from old table to new table with schema changes',
    );
    buffer.writeln('     */');
    buffer.writeln('    public static func migrateTableData(');
    buffer.writeln('        databaseName: String,');
    buffer.writeln('        oldTable: String,');
    buffer.writeln('        newTable: String,');
    buffer.writeln('        columnMapping: [String: String]');
    buffer.writeln('    ) throws {');
    buffer.writeln(
      '        let columns = columnMapping.map { "\\(\$0.key) AS \\(\$0.value)" }.joined(separator: ", ")',
    );
    buffer.writeln(
      '        let sql = "INSERT INTO \\(newTable) SELECT \\(columns) FROM \\(oldTable)"',
    );
    buffer.writeln(
      '        try NativeSqliteManager.shared.execute(name: databaseName, sql: sql)',
    );
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate schema version manager for Kotlin
  String generateKotlinVersionManager({
    required String packageName,
    required String databaseName,
    required int currentVersion,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('package $packageName.migrations');
    buffer.writeln();
    buffer.writeln('import dev.nesmin.native_sqlite.NativeSqliteManager');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Manages database schema versions and migrations');
    buffer.writeln(' * AUTO-GENERATED');
    buffer.writeln(' */');
    buffer.writeln('object SchemaVersionManager {');
    buffer.writeln();
    buffer.writeln('    const val CURRENT_VERSION = $currentVersion');
    buffer.writeln();
    buffer.writeln('    private const val CREATE_MIGRATIONS_TABLE = """');
    buffer.writeln('        CREATE TABLE IF NOT EXISTS schema_migrations (');
    buffer.writeln('            version INTEGER PRIMARY KEY,');
    buffer.writeln('            applied_at INTEGER NOT NULL');
    buffer.writeln('        )');
    buffer.writeln('    """');
    buffer.writeln();
    buffer.writeln('    fun getCurrentVersion(databaseName: String): Int {');
    buffer.writeln('        val result = NativeSqliteManager.query(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            "PRAGMA user_version"');
    buffer.writeln('        )');
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return 0',
    );
    buffer.writeln(
      '        return (rows.firstOrNull()?.firstOrNull() as? Long)?.toInt() ?: 0',
    );
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    fun setVersion(databaseName: String, version: Int) {');
    buffer.writeln(
      '        NativeSqliteManager.execute(databaseName, "PRAGMA user_version = \$version")',
    );
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln(
      '    private fun logMigration(databaseName: String, version: Int) {',
    );
    buffer.writeln('        val timestamp = System.currentTimeMillis()');
    buffer.writeln('        NativeSqliteManager.execute(');
    buffer.writeln('            databaseName,');
    buffer.writeln(
      '            "INSERT OR REPLACE INTO schema_migrations (version, applied_at) VALUES (\$version, \$timestamp)"',
    );
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    fun migrate(databaseName: String) {');
    buffer.writeln('        // Ensure migrations table exists');
    buffer.writeln(
      '        NativeSqliteManager.execute(databaseName, CREATE_MIGRATIONS_TABLE)',
    );
    buffer.writeln();
    buffer.writeln(
      '        var version = getCurrentVersion(databaseName)',
    );
    buffer.writeln('        if (version >= CURRENT_VERSION) return');
    buffer.writeln();
    buffer.writeln('        while (version < CURRENT_VERSION) {');
    buffer.writeln('            when (version) {');
    for (var v = 1; v < currentVersion; v++) {
      buffer.writeln('                $v -> Migration_${v}_${v + 1}.migrate(databaseName)');
    }
    buffer.writeln('            }');
    buffer.writeln('            logMigration(databaseName, version + 1)');
    buffer.writeln('            version++');
    buffer.writeln('        }');
    buffer.writeln();
    buffer.writeln('        setVersion(databaseName, CURRENT_VERSION)');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generate schema version manager for Swift
  String generateSwiftVersionManager({
    required String databaseName,
    required int currentVersion,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Manages database schema versions and migrations');
    buffer.writeln(' * AUTO-GENERATED');
    buffer.writeln(' */');
    buffer.writeln('public class SchemaVersionManager {');
    buffer.writeln();
    buffer.writeln('    public static let currentVersion = $currentVersion');
    buffer.writeln();
    buffer.writeln('    private static let createMigrationsTable = """');
    buffer.writeln('        CREATE TABLE IF NOT EXISTS schema_migrations (');
    buffer.writeln('            version INTEGER PRIMARY KEY,');
    buffer.writeln('            applied_at INTEGER NOT NULL');
    buffer.writeln('        )');
    buffer.writeln('    """');
    buffer.writeln();
    buffer.writeln(
      '    public static func getCurrentVersion(databaseName: String) throws -> Int {',
    );
    buffer.writeln(
      '        let result = try NativeSqliteManager.shared.query(',
    );
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            sql: "PRAGMA user_version"');
    buffer.writeln('        )');
    buffer.writeln('        guard let rows = result["rows"] as? [[Any?]],');
    buffer.writeln(
      '              let version = rows.first?.first as? Int else {',
    );
    buffer.writeln('            return 0');
    buffer.writeln('        }');
    buffer.writeln('        return version');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln(
      '    public static func setVersion(databaseName: String, version: Int) throws {',
    );
    buffer.writeln('        try NativeSqliteManager.shared.execute(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            sql: "PRAGMA user_version = \\(version)"');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln(
      '    private static func logMigration(databaseName: String, version: Int) throws {',
    );
    buffer.writeln(
      '        let timestamp = Int(Date().timeIntervalSince1970 * 1000)',
    );
    buffer.writeln('        try NativeSqliteManager.shared.execute(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln(
      '            sql: "INSERT OR REPLACE INTO schema_migrations (version, applied_at) VALUES (\\(version), \\(timestamp))"',
    );
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln(
      '    public static func migrate(databaseName: String) throws {',
    );
    buffer.writeln('        // Ensure migrations table exists');
    buffer.writeln(
      '        try NativeSqliteManager.shared.execute(name: databaseName, sql: createMigrationsTable)',
    );
    buffer.writeln();
    buffer.writeln(
      '        var version = try getCurrentVersion(databaseName: databaseName)',
    );
    buffer.writeln('        if version >= Self.currentVersion { return }');
    buffer.writeln();
    buffer.writeln('        while version < Self.currentVersion {');
    buffer.writeln('            switch version {');
    for (var v = 1; v < currentVersion; v++) {
      buffer.writeln('            case $v:');
      buffer.writeln(
        '                try Migration_${v}_${v + 1}.migrate(databaseName: databaseName)',
      );
    }
    buffer.writeln('            default: break');
    buffer.writeln('            }');
    buffer.writeln(
      '            try logMigration(databaseName: databaseName, version: version + 1)',
    );
    buffer.writeln('            version += 1');
    buffer.writeln('        }');
    buffer.writeln();
    buffer.writeln(
      '        try setVersion(databaseName: databaseName, version: Self.currentVersion)',
    );
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }
}
