package com.example.native_sqlite_example.generated.migrations

import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Database migration from version 2 to 3
 * AUTO-GENERATED - Customize as needed
 */
object Migration_2_3 {

    fun migrate(databaseName: String) {
        val db = NativeSqliteManager.getDatabase(databaseName)
        db.beginTransaction()
        try {
            // Add your migration logic here
            // Example: Add new column
            // db.execSQL("ALTER TABLE users ADD COLUMN phone TEXT")

            // Example: Create new table
            // db.execSQL("CREATE TABLE IF NOT EXISTS ...")

            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    /**
     * Add a new column to a table
     */
    fun addColumn(
        databaseName: String,
        tableName: String,
        columnName: String,
        columnType: String,
        defaultValue: String? = null
    ) {
        val sql = buildString {
            append("ALTER TABLE $tableName ADD COLUMN $columnName $columnType")
            defaultValue?.let { append(" DEFAULT $it") }
        }
        NativeSqliteManager.execute(databaseName, sql)
    }

    /**
     * Rename a table
     */
    fun renameTable(databaseName: String, oldName: String, newName: String) {
        NativeSqliteManager.execute(
            databaseName,
            "ALTER TABLE $oldName RENAME TO $newName"
        )
    }

    /**
     * Copy data from old table to new table with schema changes
     */
    fun migrateTableData(
        databaseName: String,
        oldTable: String,
        newTable: String,
        columnMapping: Map<String, String>
    ) {
        val columns = columnMapping.entries.joinToString { "${it.key} AS ${it.value}" }
        val sql = "INSERT INTO $newTable SELECT $columns FROM $oldTable"
        NativeSqliteManager.execute(databaseName, sql)
    }
}
