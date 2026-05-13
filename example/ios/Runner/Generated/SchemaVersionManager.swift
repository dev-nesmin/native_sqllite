import Foundation

/**
 * Manages database schema versions and migrations
 * AUTO-GENERATED
 */
public class SchemaVersionManager {

    public static let currentVersion = 1

    private static let createMigrationsTable = """
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            applied_at INTEGER NOT NULL
        )
    """

    public static func getCurrentVersion(databaseName: String) throws -> Int {
        let result = try NativeSqliteManager.shared.query(
            name: databaseName,
            sql: "PRAGMA user_version"
        )
        guard let rows = result["rows"] as? [[Any?]],
              let version = rows.first?.first as? Int else {
            return 0
        }
        return version
    }

    public static func setVersion(databaseName: String, version: Int) throws {
        try NativeSqliteManager.shared.execute(
            name: databaseName,
            sql: "PRAGMA user_version = \(version)"
        )
    }

    private static func logMigration(databaseName: String, version: Int) throws {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        try NativeSqliteManager.shared.execute(
            name: databaseName,
            sql: "INSERT OR REPLACE INTO schema_migrations (version, applied_at) VALUES (\(version), \(timestamp))"
        )
    }

    public static func migrate(databaseName: String) throws {
        // Ensure migrations table exists
        try NativeSqliteManager.shared.execute(name: databaseName, sql: createMigrationsTable)

        var version = try getCurrentVersion(databaseName: databaseName)
        if version >= Self.currentVersion { return }

        while version < Self.currentVersion {
            switch version {
            default: break
            }
            try logMigration(databaseName: databaseName, version: version + 1)
            version += 1
        }

        try setVersion(databaseName: databaseName, version: Self.currentVersion)
    }
}
