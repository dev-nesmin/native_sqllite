package dev.nesmin.native_sqlite

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.util.concurrent.ConcurrentHashMap

/**
 * Singleton manager for SQLite databases.
 *
 * This manager handles multiple databases and ensures thread-safe access.
 * It can be used directly from native Android code (e.g., WorkManager, Services)
 * without going through Flutter method channels.
 *
 * Example usage from native Android code:
 * ```kotlin
 * // In a WorkManager or Service
 * val db = NativeSqliteManager.getDatabase("location_db")
 * db.insert("locations", null, ContentValues().apply {
 *     put("latitude", 37.7749)
 *     put("longitude", -122.4194)
 *     put("timestamp", System.currentTimeMillis())
 * })
 * ```
 */
object NativeSqliteManager {
    private lateinit var appContext: Context
    private val databases = ConcurrentHashMap<String, SQLiteDatabase>()
    private val helpers = ConcurrentHashMap<String, DatabaseHelper>()

    /**
     * Initialize the manager with application context.
     * This should be called once when the plugin is attached.
     */
    fun initialize(context: Context) {
        appContext = context.applicationContext
    }

    /**
     * Opens a database with the given configuration.
     *
     * @return The absolute path to the database file
     */
    fun openDatabase(config: DatabaseConfig): String {
        synchronized(this) {
            // Close existing database if open
            if (databases.containsKey(config.name)) {
                closeDatabase(config.name)
            }

            val helper = DatabaseHelper(appContext, config)
            helpers[config.name] = helper
            val db = helper.writableDatabase

            // Enable WAL mode if requested
            if (config.enableWAL) {
                db.enableWriteAheadLogging()
            }

            // Enable foreign keys if requested
            if (config.enableForeignKeys) {
                db.execSQL("PRAGMA foreign_keys = ON")
            }

            databases[config.name] = db
            return db.path
        }
    }

    /**
     * Gets an open database instance.
     * Throws an exception if the database is not open.
     *
     * This is useful for native code that needs direct database access.
     */
    fun getDatabase(name: String): SQLiteDatabase {
        return databases[name] ?: throw IllegalStateException("Database '$name' is not open")
    }

    /**
     * Checks if a database is currently open.
     */
    fun isDatabaseOpen(name: String): Boolean {
        return databases.containsKey(name)
    }

    /**
     * Closes a database.
     */
    fun closeDatabase(name: String) {
        synchronized(this) {
            databases.remove(name)?.close()
            helpers.remove(name)?.close()
        }
    }

    /**
     * Closes all open databases.
     */
    fun closeAll() {
        synchronized(this) {
            databases.values.forEach { it.close() }
            helpers.values.forEach { it.close() }
            databases.clear()
            helpers.clear()
        }
    }

    /**
     * Executes a raw SQL statement (INSERT, UPDATE, DELETE, etc.)
     *
     * @return Number of rows affected
     */
    fun execute(name: String, sql: String, arguments: List<Any?>? = null): Int {
        val db = getDatabase(name)
        val args = arguments?.toTypedArray()
        if (args != null) {
            db.execSQL(sql, args)
        } else {
            db.execSQL(sql)
        }

        // Return rows affected for DML statements
        return when {
            sql.trim().uppercase().startsWith("INSERT") ||
            sql.trim().uppercase().startsWith("UPDATE") ||
            sql.trim().uppercase().startsWith("DELETE") -> {
                db.compileStatement("SELECT changes()").simpleQueryForLong().toInt()
            }
            else -> 0
        }
    }

    /**
     * Executes a SELECT query and returns the results.
     *
     * @return A map with "columns" and "rows" keys
     */
    fun query(name: String, sql: String, arguments: List<Any?>? = null): Map<String, Any> {
        val db = getDatabase(name)
        val cursor = db.rawQuery(sql, arguments?.map { it?.toString() }?.toTypedArray())

        return cursor.use { c ->
            val columns = c.columnNames.toList()
            val rows = mutableListOf<List<Any?>>()

            while (c.moveToNext()) {
                val row = mutableListOf<Any?>()
                for (i in 0 until c.columnCount) {
                    row.add(c.getValue(i))
                }
                rows.add(row)
            }

            mapOf(
                "columns" to columns,
                "rows" to rows
            )
        }
    }

    /**
     * Inserts a row into a table.
     *
     * @return The row ID of the newly inserted row, or -1 if an error occurred
     */
    fun insert(name: String, table: String, values: Map<String, Any?>): Long {
        val db = getDatabase(name)
        val contentValues = ContentValues().apply {
            values.forEach { (key, value) ->
                putValue(key, value)
            }
        }
        return db.insert(table, null, contentValues)
    }

    /**
     * Updates rows in a table.
     *
     * @return The number of rows affected
     */
    fun update(
        name: String,
        table: String,
        values: Map<String, Any?>,
        where: String? = null,
        whereArgs: List<Any?>? = null
    ): Int {
        val db = getDatabase(name)
        val contentValues = ContentValues().apply {
            values.forEach { (key, value) ->
                putValue(key, value)
            }
        }
        return db.update(
            table,
            contentValues,
            where,
            whereArgs?.map { it?.toString() }?.toTypedArray()
        )
    }

    /**
     * Deletes rows from a table.
     *
     * @return The number of rows deleted
     */
    fun delete(
        name: String,
        table: String,
        where: String? = null,
        whereArgs: List<Any?>? = null
    ): Int {
        val db = getDatabase(name)
        return db.delete(table, where, whereArgs?.map { it?.toString() }?.toTypedArray())
    }

    /**
     * Executes multiple SQL statements in a transaction.
     *
     * @return true if the transaction was successful, false otherwise
     */
    fun transaction(name: String, statements: List<String>): Boolean {
        val db = getDatabase(name)
        db.beginTransaction()
        return try {
            statements.forEach { sql ->
                db.execSQL(sql)
            }
            db.setTransactionSuccessful()
            true
        } catch (e: Exception) {
            false
        } finally {
            db.endTransaction()
        }
    }

    /**
     * Gets the absolute path to a database file.
     */
    fun getDatabasePath(name: String): String {
        return appContext.getDatabasePath("$name.db").absolutePath
    }

    /**
     * Deletes a database file.
     */
    fun deleteDatabase(name: String) {
        synchronized(this) {
            closeDatabase(name)
            appContext.deleteDatabase("$name.db")
        }
    }

    // Helper extensions
    private fun Cursor.getValue(index: Int): Any? {
        return when (getType(index)) {
            Cursor.FIELD_TYPE_NULL -> null
            Cursor.FIELD_TYPE_INTEGER -> getLong(index)
            Cursor.FIELD_TYPE_FLOAT -> getDouble(index)
            Cursor.FIELD_TYPE_STRING -> getString(index)
            Cursor.FIELD_TYPE_BLOB -> getBlob(index)
            else -> null
        }
    }

    private fun ContentValues.putValue(key: String, value: Any?) {
        when (value) {
            null -> putNull(key)
            is String -> put(key, value)
            is Int -> put(key, value)
            is Long -> put(key, value)
            is Double -> put(key, value)
            is Float -> put(key, value)
            is Boolean -> put(key, value)
            is ByteArray -> put(key, value)
            else -> put(key, value.toString())
        }
    }

    /**
     * SQLiteOpenHelper implementation
     */
    private class DatabaseHelper(
        context: Context,
        private val config: DatabaseConfig
    ) : SQLiteOpenHelper(context, "${config.name}.db", null, config.version) {

        override fun onCreate(db: SQLiteDatabase) {
            config.onCreate?.forEach { sql ->
                db.execSQL(sql)
            }
        }

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            config.onUpgrade?.forEach { sql ->
                db.execSQL(sql)
            }
        }
    }
}
