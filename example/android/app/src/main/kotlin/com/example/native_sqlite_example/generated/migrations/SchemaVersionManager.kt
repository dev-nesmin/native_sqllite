package com.example.native_sqlite_example.generated.migrations

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

        var version = getCurrentVersion(databaseName)
        if (version >= CURRENT_VERSION) return

        while (version < CURRENT_VERSION) {
            when (version) {
            }
            logMigration(databaseName, version + 1)
            version++
        }

        setVersion(databaseName, CURRENT_VERSION)
    }
}
