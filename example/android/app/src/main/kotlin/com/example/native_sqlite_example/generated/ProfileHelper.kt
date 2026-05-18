package com.example.native_sqlite_example.generated

import dev.nesmin.native_sqlite.NativeSqliteManager
import java.util.concurrent.ConcurrentHashMap

/**
 * Data class for Profile.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class Profile(
    val id: Long? = null,
    val name: String,
    val email: String,
    val phoneNumber: String?,
    val settings: String?,
    val tags: String?,
    val address: Any?,
    val addresses: String?,
    val metadata: Any
)

/**
 * Helper class for Profile CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * val helper = ProfileHelper("example_app")
 * val id = helper.insert(Profile(...))
 * val item = helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In WorkManager or background task
 * val isolateId = Thread.currentThread().id
 * val helper = ProfileHelper.getInstance("example_app", isolateId)
 * val users = helper.findAll()
 * // When done, cleanup:
 * ProfileHelper.cleanupIsolate(isolateId)
 * ```
 */
class ProfileHelper(private val databaseName: String) {

    companion object {
        // Track helper instances per isolate for thread safety
        private val isolateInstances = ConcurrentHashMap<Long, ProfileHelper>()

        /**
         * Get or create helper instance for the given isolate.
         * Safe to call from different Dart isolates or native threads.
         *
         * @param databaseName Name of the database
         * @param isolateId Unique identifier for the isolate/thread
         * @return Helper instance for this isolate
         */
        @JvmStatic
        fun getInstance(databaseName: String, isolateId: Long): ProfileHelper {
            return isolateInstances.getOrPut(isolateId) {
                ProfileHelper(databaseName)
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

    fun insert(entity: Profile): Long {
        val values: Map<String, Any?> = mapOf(
            ProfileSchema.NAME to entity.name,
            ProfileSchema.EMAIL to entity.email,
            ProfileSchema.PHONE_NUMBER to entity.phoneNumber,
            ProfileSchema.SETTINGS to entity.settings?.let { Json.encodeToString(it) },
            ProfileSchema.TAGS to entity.tags?.let { Json.encodeToString(it) },
            ProfileSchema.ADDRESS to entity.address,
            ProfileSchema.ADDRESSES to entity.addresses?.let { Json.encodeToString(it) },
            ProfileSchema.METADATA to entity.metadata
        )
        return NativeSqliteManager.Instance.insert(databaseName, ProfileSchema.TABLE_NAME, values)
    }

    fun findById(id: Long): Profile? {
        val result = NativeSqliteManager.Instance.query(
            databaseName,
            "SELECT * FROM ${ProfileSchema.TABLE_NAME} WHERE ${ProfileSchema.ID} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<Profile> {
        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM ${ProfileSchema.TABLE_NAME}")
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
    fun update(entity: Profile): Int {
        val values: Map<String, Any?> = mapOf(
            ProfileSchema.NAME to entity.name,
            ProfileSchema.EMAIL to entity.email,
            ProfileSchema.PHONE_NUMBER to entity.phoneNumber,
            ProfileSchema.SETTINGS to entity.settings?.let { Json.encodeToString(it) },
            ProfileSchema.TAGS to entity.tags?.let { Json.encodeToString(it) },
            ProfileSchema.ADDRESS to entity.address,
            ProfileSchema.ADDRESSES to entity.addresses?.let { Json.encodeToString(it) },
            ProfileSchema.METADATA to entity.metadata
        )
        return NativeSqliteManager.Instance.update(
            databaseName,
            ProfileSchema.TABLE_NAME,
            values,
            "${ProfileSchema.ID} = ?",
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
            ProfileSchema.TABLE_NAME,
            updates,
            "${ProfileSchema.ID} = ?",
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
            ProfileSchema.TABLE_NAME,
            "${ProfileSchema.ID} = ?",
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
            ProfileSchema.TABLE_NAME,
            whereClause,
            whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * @param entities List of entities to insert
     * @return List of inserted row IDs
     */
    fun insertBatch(entities: List<Profile>): List<Long> {
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
    fun updateBatch(entities: List<Profile>): Int {
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
    ): List<Profile> {
        val sql = buildString {
            append("SELECT * FROM ${ProfileSchema.TABLE_NAME}")
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
            "SELECT COUNT(*) FROM ${ProfileSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${ProfileSchema.TABLE_NAME}"
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
            "SELECT MAX($column) FROM ${ProfileSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MAX($column) FROM ${ProfileSchema.TABLE_NAME}"
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
            "SELECT MIN($column) FROM ${ProfileSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MIN($column) FROM ${ProfileSchema.TABLE_NAME}"
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
            "SELECT AVG($column) FROM ${ProfileSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT AVG($column) FROM ${ProfileSchema.TABLE_NAME}"
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
            "SELECT SUM($column) FROM ${ProfileSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT SUM($column) FROM ${ProfileSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): Profile {
        return Profile(
            id = row[columnMap[ProfileSchema.ID]!!] as Long?,
            name = row[columnMap[ProfileSchema.NAME]!!] as String,
            email = row[columnMap[ProfileSchema.EMAIL]!!] as String,
            phoneNumber = row[columnMap[ProfileSchema.PHONE_NUMBER]!!] as String?,
            settings = (row[columnMap[ProfileSchema.SETTINGS]!!] as? String)?.let { Json.decodeFromString(it) },
            tags = (row[columnMap[ProfileSchema.TAGS]!!] as? String)?.let { Json.decodeFromString(it) },
            address = row[columnMap[ProfileSchema.ADDRESS]!!],
            addresses = (row[columnMap[ProfileSchema.ADDRESSES]!!] as? String)?.let { Json.decodeFromString(it) },
            metadata = row[columnMap[ProfileSchema.METADATA]!!]
        )
    }
}
