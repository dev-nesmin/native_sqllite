package dev.nesmin.native_sqlite.generated.migrations

import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Manages database schema versions and migrations
 * AUTO-GENERATED
 */
object SchemaVersionManager {

    const val CURRENT_VERSION = 1

    private const val CREATE_MIGRATIONS_TABLE = """
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            applied_at INTEGER NOT NULL
        )
    """

    fun getCurrentVersion(databaseName: String): Int {
        val result = NativeSqliteManager.query(
            databaseName,
            "PRAGMA user_version"
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return 0
        return (rows.firstOrNull()?.firstOrNull() as? Long)?.toInt() ?: 0
    }

    fun setVersion(databaseName: String, version: Int) {
        NativeSqliteManager.execute(databaseName, "PRAGMA user_version = $version")
    }

    private fun logMigration(databaseName: String, version: Int) {
        val timestamp = System.currentTimeMillis()
        NativeSqliteManager.execute(
            databaseName,
            "INSERT OR REPLACE INTO schema_migrations (version, applied_at) VALUES ($version, $timestamp)"
        )
    }

    fun migrate(databaseName: String) {
        // Ensure migrations table exists
        NativeSqliteManager.execute(databaseName, CREATE_MIGRATIONS_TABLE)

        val currentVersion = getCurrentVersion(databaseName)
        if (currentVersion >= CURRENT_VERSION) return

        // Add migration steps here
        // when (currentVersion) {
        //     0 -> {
        //         Migration_0_1.migrate(databaseName)
        //         logMigration(databaseName, 1)
        //     }
        //     1 -> {
        //         Migration_1_2.migrate(databaseName)
        //         logMigration(databaseName, 2)
        //     }
        // }

        setVersion(databaseName, CURRENT_VERSION)
    }
}
