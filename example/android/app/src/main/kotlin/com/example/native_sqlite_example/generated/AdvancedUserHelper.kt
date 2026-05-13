package com.example.native_sqlite_example.generated

import android.content.ContentValues
import dev.nesmin.native_sqlite.NativeSqliteManager
import java.util.concurrent.ConcurrentHashMap

/**
 * Data class for AdvancedUser.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class AdvancedUser(
    val id: Long? = null,
    val name: String,
    val phoneNumber: String?,
    val address: String?,
    val country: String?,
    val zipCode: String?,
    val age: Long?,
    val city: String?,
    val loginDuration: Any?,
    val profileUrl: Any?,
    val score: Any?,
    val status: Any,
    val priority: Any?,
    val createdAt: Long,
    val isVerified: Boolean
)

/**
 * Helper class for AdvancedUser CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * val helper = AdvancedUserHelper("example_app")
 * val id = helper.insert(AdvancedUser(...))
 * val item = helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In WorkManager or background task
 * val isolateId = Thread.currentThread().id
 * val helper = AdvancedUserHelper.getInstance("example_app", isolateId)
 * val users = helper.findAll()
 * // When done, cleanup:
 * AdvancedUserHelper.cleanupIsolate(isolateId)
 * ```
 */
class AdvancedUserHelper(private val databaseName: String) {

    companion object {
        // Track helper instances per isolate for thread safety
        private val isolateInstances = ConcurrentHashMap<Long, AdvancedUserHelper>()

        /**
         * Get or create helper instance for the given isolate.
         * Safe to call from different Dart isolates or native threads.
         *
         * @param databaseName Name of the database
         * @param isolateId Unique identifier for the isolate/thread
         * @return Helper instance for this isolate
         */
        @JvmStatic
        fun getInstance(databaseName: String, isolateId: Long): AdvancedUserHelper {
            return isolateInstances.getOrPut(isolateId) {
                AdvancedUserHelper(databaseName)
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

    fun insert(entity: AdvancedUser): Long {
        val values = ContentValues().apply {
            put(AdvancedUserSchema.NAME, entity.name)
            put(AdvancedUserSchema.PHONE_NUMBER, entity.phoneNumber)
            put(AdvancedUserSchema.ADDRESS, entity.address)
            put(AdvancedUserSchema.COUNTRY, entity.country)
            put(AdvancedUserSchema.ZIP_CODE, entity.zipCode)
            put(AdvancedUserSchema.AGE, entity.age)
            put(AdvancedUserSchema.CITY, entity.city)
            put(AdvancedUserSchema.LOGIN_DURATION, entity.loginDuration)
            put(AdvancedUserSchema.PROFILE_URL, entity.profileUrl)
            put(AdvancedUserSchema.SCORE, entity.score)
            put(AdvancedUserSchema.STATUS, entity.status)
            put(AdvancedUserSchema.PRIORITY, entity.priority)
            put(AdvancedUserSchema.CREATED_AT, entity.createdAt.toEpochMilliseconds())
            put(AdvancedUserSchema.IS_VERIFIED, if (entity.isVerified) 1 else 0)
        }
        return NativeSqliteManager.insert(databaseName, AdvancedUserSchema.TABLE_NAME, values)
    }

    fun findById(id: Long): AdvancedUser? {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT * FROM ${AdvancedUserSchema.TABLE_NAME} WHERE ${AdvancedUserSchema.ID} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<AdvancedUser> {
        val result = NativeSqliteManager.query(databaseName, "SELECT * FROM ${AdvancedUserSchema.TABLE_NAME}")
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
    fun update(entity: AdvancedUser): Int {
        val values = ContentValues().apply {
            put(AdvancedUserSchema.NAME, entity.name)
            put(AdvancedUserSchema.PHONE_NUMBER, entity.phoneNumber)
            put(AdvancedUserSchema.ADDRESS, entity.address)
            put(AdvancedUserSchema.COUNTRY, entity.country)
            put(AdvancedUserSchema.ZIP_CODE, entity.zipCode)
            put(AdvancedUserSchema.AGE, entity.age)
            put(AdvancedUserSchema.CITY, entity.city)
            put(AdvancedUserSchema.LOGIN_DURATION, entity.loginDuration)
            put(AdvancedUserSchema.PROFILE_URL, entity.profileUrl)
            put(AdvancedUserSchema.SCORE, entity.score)
            put(AdvancedUserSchema.STATUS, entity.status)
            put(AdvancedUserSchema.PRIORITY, entity.priority)
            put(AdvancedUserSchema.CREATED_AT, entity.createdAt.toEpochMilliseconds())
            put(AdvancedUserSchema.IS_VERIFIED, if (entity.isVerified) 1 else 0)
        }
        return NativeSqliteManager.update(
            databaseName,
            AdvancedUserSchema.TABLE_NAME,
            values,
            "${AdvancedUserSchema.ID} = ?",
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
        return NativeSqliteManager.update(
            databaseName,
            AdvancedUserSchema.TABLE_NAME,
            updates,
            "${AdvancedUserSchema.ID} = ?",
            listOf(id)
        )
    }

    /**
     * Delete an entity by its primary key.
     * @param id The primary key value
     * @return Number of rows deleted
     */
    fun delete(id: Long): Int {
        return NativeSqliteManager.delete(
            databaseName,
            AdvancedUserSchema.TABLE_NAME,
            "${AdvancedUserSchema.ID} = ?",
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
        return NativeSqliteManager.delete(
            databaseName,
            AdvancedUserSchema.TABLE_NAME,
            whereClause,
            whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * @param entities List of entities to insert
     * @return List of inserted row IDs
     */
    fun insertBatch(entities: List<AdvancedUser>): List<Long> {
        val db = NativeSqliteManager.getDatabase(databaseName)
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
    fun updateBatch(entities: List<AdvancedUser>): Int {
        val db = NativeSqliteManager.getDatabase(databaseName)
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
        val db = NativeSqliteManager.getDatabase(databaseName)
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
    ): List<AdvancedUser> {
        val sql = buildString {
            append("SELECT * FROM ${AdvancedUserSchema.TABLE_NAME}")
            whereClause?.let { append(" WHERE $it") }
            orderBy?.let { append(" ORDER BY $it") }
            limit?.let { append(" LIMIT $it") }
            offset?.let { append(" OFFSET $it") }
        }
        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)
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
            "SELECT COUNT(*) FROM ${AdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${AdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)
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
            "SELECT MAX($column) FROM ${AdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MAX($column) FROM ${AdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)
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
            "SELECT MIN($column) FROM ${AdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MIN($column) FROM ${AdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)
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
            "SELECT AVG($column) FROM ${AdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT AVG($column) FROM ${AdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)
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
            "SELECT SUM($column) FROM ${AdvancedUserSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT SUM($column) FROM ${AdvancedUserSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): AdvancedUser {
        return AdvancedUser(
            id = row[columnMap[AdvancedUserSchema.ID]!!] as Long?,
            name = row[columnMap[AdvancedUserSchema.NAME]!!] as String,
            phoneNumber = row[columnMap[AdvancedUserSchema.PHONE_NUMBER]!!] as String?,
            address = row[columnMap[AdvancedUserSchema.ADDRESS]!!] as String?,
            country = row[columnMap[AdvancedUserSchema.COUNTRY]!!] as String?,
            zipCode = row[columnMap[AdvancedUserSchema.ZIP_CODE]!!] as String?,
            age = row[columnMap[AdvancedUserSchema.AGE]!!] as Long?,
            city = row[columnMap[AdvancedUserSchema.CITY]!!] as String?,
            loginDuration = row[columnMap[AdvancedUserSchema.LOGIN_DURATION]!!],
            profileUrl = row[columnMap[AdvancedUserSchema.PROFILE_URL]!!],
            score = row[columnMap[AdvancedUserSchema.SCORE]!!],
            status = row[columnMap[AdvancedUserSchema.STATUS]!!],
            priority = row[columnMap[AdvancedUserSchema.PRIORITY]!!],
            createdAt = DateTime.fromEpochMilliseconds(row[columnMap[AdvancedUserSchema.CREATED_AT]!!] as Long),
            isVerified = (row[columnMap[AdvancedUserSchema.IS_VERIFIED]!!] as Long) == 1L
        )
    }
}
