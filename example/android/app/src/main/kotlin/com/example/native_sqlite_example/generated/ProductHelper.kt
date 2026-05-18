package com.example.native_sqlite_example.generated

import dev.nesmin.native_sqlite.NativeSqliteManager
import java.util.concurrent.ConcurrentHashMap

/**
 * Data class for Product.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class Product(
    val id: Long? = null,
    val name: String,
    val description: String?,
    val price: Double,
    val stock: Long,
    val isAvailable: Boolean,
    val categoryId: Long,
    val imageUrl: String?,
    val createdAt: Long,
    val updatedAt: Long?
)

/**
 * Helper class for Product CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * val helper = ProductHelper("example_app")
 * val id = helper.insert(Product(...))
 * val item = helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In WorkManager or background task
 * val isolateId = Thread.currentThread().id
 * val helper = ProductHelper.getInstance("example_app", isolateId)
 * val users = helper.findAll()
 * // When done, cleanup:
 * ProductHelper.cleanupIsolate(isolateId)
 * ```
 */
class ProductHelper(private val databaseName: String) {

    companion object {
        // Track helper instances per isolate for thread safety
        private val isolateInstances = ConcurrentHashMap<Long, ProductHelper>()

        /**
         * Get or create helper instance for the given isolate.
         * Safe to call from different Dart isolates or native threads.
         *
         * @param databaseName Name of the database
         * @param isolateId Unique identifier for the isolate/thread
         * @return Helper instance for this isolate
         */
        @JvmStatic
        fun getInstance(databaseName: String, isolateId: Long): ProductHelper {
            return isolateInstances.getOrPut(isolateId) {
                ProductHelper(databaseName)
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

    fun insert(entity: Product): Long {
        val values: Map<String, Any?> = mapOf(
            ProductSchema.NAME to entity.name,
            ProductSchema.DESCRIPTION to entity.description,
            ProductSchema.PRICE to entity.price,
            ProductSchema.STOCK to entity.stock,
            ProductSchema.IS_AVAILABLE to if (entity.isAvailable) 1 else 0,
            ProductSchema.CATEGORY_ID to entity.categoryId,
            ProductSchema.IMAGE_URL to entity.imageUrl,
            ProductSchema.CREATED_AT to entity.createdAt.toEpochMilliseconds(),
            ProductSchema.UPDATED_AT to entity.updatedAt?.toEpochMilliseconds()
        )
        return NativeSqliteManager.Instance.insert(databaseName, ProductSchema.TABLE_NAME, values)
    }

    fun findById(id: Long): Product? {
        val result = NativeSqliteManager.Instance.query(
            databaseName,
            "SELECT * FROM ${ProductSchema.TABLE_NAME} WHERE ${ProductSchema.ID} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<Product> {
        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM ${ProductSchema.TABLE_NAME}")
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
    fun update(entity: Product): Int {
        val values: Map<String, Any?> = mapOf(
            ProductSchema.NAME to entity.name,
            ProductSchema.DESCRIPTION to entity.description,
            ProductSchema.PRICE to entity.price,
            ProductSchema.STOCK to entity.stock,
            ProductSchema.IS_AVAILABLE to if (entity.isAvailable) 1 else 0,
            ProductSchema.CATEGORY_ID to entity.categoryId,
            ProductSchema.IMAGE_URL to entity.imageUrl,
            ProductSchema.CREATED_AT to entity.createdAt.toEpochMilliseconds(),
            ProductSchema.UPDATED_AT to entity.updatedAt?.toEpochMilliseconds()
        )
        return NativeSqliteManager.Instance.update(
            databaseName,
            ProductSchema.TABLE_NAME,
            values,
            "${ProductSchema.ID} = ?",
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
            ProductSchema.TABLE_NAME,
            updates,
            "${ProductSchema.ID} = ?",
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
            ProductSchema.TABLE_NAME,
            "${ProductSchema.ID} = ?",
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
            ProductSchema.TABLE_NAME,
            whereClause,
            whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * @param entities List of entities to insert
     * @return List of inserted row IDs
     */
    fun insertBatch(entities: List<Product>): List<Long> {
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
    fun updateBatch(entities: List<Product>): Int {
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
    ): List<Product> {
        val sql = buildString {
            append("SELECT * FROM ${ProductSchema.TABLE_NAME}")
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
            "SELECT COUNT(*) FROM ${ProductSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${ProductSchema.TABLE_NAME}"
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
            "SELECT MAX($column) FROM ${ProductSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MAX($column) FROM ${ProductSchema.TABLE_NAME}"
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
            "SELECT MIN($column) FROM ${ProductSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT MIN($column) FROM ${ProductSchema.TABLE_NAME}"
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
            "SELECT AVG($column) FROM ${ProductSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT AVG($column) FROM ${ProductSchema.TABLE_NAME}"
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
            "SELECT SUM($column) FROM ${ProductSchema.TABLE_NAME} WHERE $whereClause"
        } else {
            "SELECT SUM($column) FROM ${ProductSchema.TABLE_NAME}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): Product {
        return Product(
            id = row[columnMap[ProductSchema.ID]!!] as Long?,
            name = row[columnMap[ProductSchema.NAME]!!] as String,
            description = row[columnMap[ProductSchema.DESCRIPTION]!!] as String?,
            price = row[columnMap[ProductSchema.PRICE]!!] as Double,
            stock = row[columnMap[ProductSchema.STOCK]!!] as Long,
            isAvailable = (row[columnMap[ProductSchema.IS_AVAILABLE]!!] as Long) == 1L,
            categoryId = row[columnMap[ProductSchema.CATEGORY_ID]!!] as Long,
            imageUrl = row[columnMap[ProductSchema.IMAGE_URL]!!] as String?,
            createdAt = DateTime.fromEpochMilliseconds(row[columnMap[ProductSchema.CREATED_AT]!!] as Long),
            updatedAt = (row[columnMap[ProductSchema.UPDATED_AT]!!] as? Long)?.let { DateTime.fromEpochMilliseconds(it) }
        )
    }
}
