@file:Suppress("UNCHECKED_CAST")

package com.example.native_sqlite_example.generated

import android.net.Uri
import dev.nesmin.native_sqlite.NativeSqliteManager
import java.time.Duration
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

/**
 * Data class for FreezedAdvancedUser.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class FreezedAdvancedUser(
    val id: Long? = null,
    val name: String,
    val loginDuration: Duration? = null,
    val profileUrl: Uri? = null,
    val status: UserStatus,
    val priority: Priority? = null,
    val createdAt: Instant,
    val isVerified: Boolean
)

/**
 * Helper class for FreezedAdvancedUser CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * val helper = FreezedAdvancedUserHelper("example_app")
 * val id = helper.insert(FreezedAdvancedUser(...))
 * val item = helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In WorkManager or background task
 * val isolateId = Thread.currentThread().id
 * val helper = FreezedAdvancedUserHelper.getInstance("example_app", isolateId)
 * val users = helper.findAll()
 * // When done, cleanup:
 * FreezedAdvancedUserHelper.cleanupIsolate(isolateId)
 * ```
 */
class FreezedAdvancedUserHelper(private val databaseName: String) {

    companion object {
        // Track helper instances per isolate for thread safety
        private val isolateInstances = ConcurrentHashMap<Long, FreezedAdvancedUserHelper>()

        /**
         * Get or create helper instance for the given isolate.
         * Safe to call from different Dart isolates or native threads.
         *
         * @param databaseName Name of the database
         * @param isolateId Unique identifier for the isolate/thread
         * @return Helper instance for this isolate
         */
        @JvmStatic
        fun getInstance(databaseName: String, isolateId: Long): FreezedAdvancedUserHelper {
            return isolateInstances.getOrPut(isolateId) {
                FreezedAdvancedUserHelper(databaseName)
            }
        }

        /**
         * Cleanup resources for a specific isolate.
         * Call this when an isolate is being destroyed.
         *
         * @param isolateId The isolate ID to cleanup
         */
        @JvmStatic
        fun cleanupIsolate(isolateId: Long) {
            isolateInstances.remove(isolateId)
        }

        /**
         * Get all active isolate IDs currently using this helper.
         * Useful for debugging.
         */
        @JvmStatic
        fun getActiveIsolates(): Set<Long> {
            return isolateInstances.keys.toSet()
        }
    }

    fun insert(entity: FreezedAdvancedUser): Long {
        val values: Map<String, Any?> = mapOf(
            FreezedAdvancedUserSchema.NAME to entity.name,
            FreezedAdvancedUserSchema.LOGIN_DURATION to entity.loginDuration?.let { it.toMillis() },
            FreezedAdvancedUserSchema.PROFILE_URL to entity.profileUrl?.let { it.toString() },
            FreezedAdvancedUserSchema.STATUS to entity.status.ordinal.toLong(),
            FreezedAdvancedUserSchema.PRIORITY to entity.priority?.let { it.ordinal.toLong() },
            FreezedAdvancedUserSchema.CREATED_AT to entity.createdAt.toEpochMilli(),
            FreezedAdvancedUserSchema.IS_VERIFIED to if (entity.isVerified) 1L else 0L
        )
        return NativeSqliteManager.Instance.insert(databaseName, FreezedAdvancedUserSchema.TABLE_NAME, values)
    }

    fun findById(id: Long): FreezedAdvancedUser? {
        val result = NativeSqliteManager.Instance.query(
            databaseName,
            "SELECT * FROM ${FreezedAdvancedUserSchema.TABLE_NAME} WHERE ${FreezedAdvancedUserSchema.ID} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<FreezedAdvancedUser> {
        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM ${FreezedAdvancedUserSchema.TABLE_NAME}")
        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return rows.map { fromRow(columnMap, it) }
    }

    /**
     * Update an existing entity.
     * @param entity The entity to update (must have a valid primary key)
     * @return Number of rows affected
     */
    fun update(entity: FreezedAdvancedUser): Int {
        val values: Map<String, Any?> = mapOf(
            FreezedAdvancedUserSchema.NAME to entity.name,
            FreezedAdvancedUserSchema.LOGIN_DURATION to entity.loginDuration?.let { it.toMillis() },
            FreezedAdvancedUserSchema.PROFILE_URL to entity.profileUrl?.let { it.toString() },
            FreezedAdvancedUserSchema.STATUS to entity.status.ordinal.toLong(),
            FreezedAdvancedUserSchema.PRIORITY to entity.priority?.let { it.ordinal.toLong() },
            FreezedAdvancedUserSchema.CREATED_AT to entity.createdAt.toEpochMilli(),
            FreezedAdvancedUserSchema.IS_VERIFIED to if (entity.isVerified) 1L else 0L
        )
        return NativeSqliteManager.Instance.update(
            databaseName,
            FreezedAdvancedUserSchema.TABLE_NAME,
            values,
            "${FreezedAdvancedUserSchema.ID} = ?",
            listOf(entity.id)
        )
    }

    /**
     * Update specific fields of an entity.
     * @param id The primary key value
     * @param updates Map of column names to new values
     * @return Number of rows affected
     */
    fun updatePartial(id: Long, updates: Map<String, Any?>): Int {
        return NativeSqliteManager.Instance.update(
            databaseName,
            FreezedAdvancedUserSchema.TABLE_NAME,
            updates,
            "${FreezedAdvancedUserSchema.ID} = ?",
            listOf(id)
        )
    }

    /**
     * Delete an entity by its primary key.
     * @param id The primary key value
     * @return Number of rows deleted
     */
    fun delete(id: Long): Int {
        return NativeSqliteManager.Instance.delete(
            databaseName,
            FreezedAdvancedUserSchema.TABLE_NAME,
            "${FreezedAdvancedUserSchema.ID} = ?",
            listOf(id)
        )
    }

    /**
     * Delete entities matching a WHERE clause.
     * @param whereClause SQL WHERE clause (without "WHERE" keyword)
     * @param whereArgs Arguments for the WHERE clause
     * @return Number of rows deleted
     */
    fun deleteWhere(whereClause: String, whereArgs: List<Any?>? = null): Int {
        return NativeSqliteManager.Instance.delete(
            databaseName,
            FreezedAdvancedUserSchema.TABLE_NAME,
            whereClause,
            whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * @param entities List of entities to insert
     * @return List of inserted row IDs
     */
    fun insertBatch(entities: List<FreezedAdvancedUser>): List<Long> {
        val db = NativeSqliteManager.Instance.getDatabase(databaseName)
        val results = mutableListOf<Long>()
        db.beginTransaction()
        try {
            entities.forEach { entity ->
                results.add(insert(entity))
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        return results
    }

    /**
     * Update multiple entities in a single transaction.
     * @param entities List of entities to update
     * @return Total number of rows affected
     */
    fun updateBatch(entities: List<FreezedAdvancedUser>): Int {
        val db = NativeSqliteManager.Instance.getDatabase(databaseName)
        var totalAffected = 0
        db.beginTransaction()
        try {
            entities.forEach { entity ->
                totalAffected += update(entity)
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        return totalAffected
    }

    /**
     * Delete multiple entities by their IDs in a single transaction.
     * @param ids List of primary key values
     * @return Total number of rows deleted
     */
    fun deleteBatch(ids: List<Long>): Int {
        val db = NativeSqliteManager.Instance.getDatabase(databaseName)
        var totalDeleted = 0
        db.beginTransaction()
        try {
            ids.forEach { id ->
                totalDeleted += delete(id)
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        return totalDeleted
    }

    /**
     * Find entities matching a WHERE clause with optional ordering and limit.
     * @param whereClause SQL WHERE clause (without "WHERE" keyword)
     * @param whereArgs Arguments for the WHERE clause
     * @param orderBy Column to order by (e.g., "name ASC", "age DESC")
     * @param limit Maximum number of results
     * @param offset Number of results to skip
     * @return List of matching entities
     */
    fun findWhere(
        whereClause: String? = null,
        whereArgs: List<Any?>? = null,
        orderBy: String? = null,
        limit: Int? = null,
        offset: Int? = null
    ): List<FreezedAdvancedUser> {
        val sql = buildString {
            append("SELECT * FROM ${FreezedAdvancedUserSchema.TABLE_NAME}")
            whereClause?.let { append(" WHERE $it") }
            orderBy?.let { append(" ORDER BY $it") }
            limit?.let { append(" LIMIT $it") }
            offset?.let { append(" OFFSET $it") }
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return rows.map { fromRow(columnMap, it) }
    }

    /**
     * Count entities matching a WHERE clause.
     * @param whereClause SQL WHERE clause (without "WHERE" keyword)
     * @param whereArgs Arguments for the WHERE clause
     * @return Number of matching entities
     */
    fun count(whereClause: String? = null, whereArgs: List<Any?>? = null): Long {
        val sql = if (whereClause != null) {
            "SELECT COUNT(*) FROM ${FreezedAdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${FreezedAdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return 0
        return (rows.firstOrNull()?.firstOrNull() as? Long) ?: 0
    }

    /**
     * Get the maximum value of a column.
     * @param column Column name to get max value from
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Maximum value or null
     */
    fun max(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Any? {
        val sql = if (whereClause != null) {
            "SELECT MAX($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MAX($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull()
    }

    /**
     * Get the minimum value of a column.
     * @param column Column name to get min value from
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Minimum value or null
     */
    fun min(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Any? {
        val sql = if (whereClause != null) {
            "SELECT MIN($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MIN($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull()
    }

    /**
     * Get the average value of a column.
     * @param column Column name to get average from
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Average value or null
     */
    fun avg(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Double? {
        val sql = if (whereClause != null) {
            "SELECT AVG($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT AVG($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    /**
     * Get the sum of a column.
     * @param column Column name to sum
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Sum value or null
     */
    fun sum(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Double? {
        val sql = if (whereClause != null) {
            "SELECT SUM($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT SUM($column) FROM ${FreezedAdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): FreezedAdvancedUser {
        return FreezedAdvancedUser(
            id = row[columnMap.getValue(FreezedAdvancedUserSchema.ID)]?.let { (it as Number).toLong() },
            name = row[columnMap.getValue(FreezedAdvancedUserSchema.NAME)] as String,
            loginDuration = row[columnMap.getValue(FreezedAdvancedUserSchema.LOGIN_DURATION)]?.let { Duration.ofMillis((it as Number).toLong()) },
            profileUrl = row[columnMap.getValue(FreezedAdvancedUserSchema.PROFILE_URL)]?.let { Uri.parse(it as String) },
            status = UserStatus.entries[(row[columnMap.getValue(FreezedAdvancedUserSchema.STATUS)] as Number).toInt()],
            priority = row[columnMap.getValue(FreezedAdvancedUserSchema.PRIORITY)]?.let { Priority.entries[(it as Number).toInt()] },
            createdAt = Instant.ofEpochMilli((row[columnMap.getValue(FreezedAdvancedUserSchema.CREATED_AT)] as Number).toLong()),
            isVerified = (row[columnMap.getValue(FreezedAdvancedUserSchema.IS_VERIFIED)] as Number).toLong() == 1L
        )
    }
}
