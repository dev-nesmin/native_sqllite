@file:Suppress("UNCHECKED_CAST")

package com.example.native_sqlite_example.generated

import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Data class for Attachment.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class Attachment(
    val id: Long? = null,
    val filename: String,
    val bytes: ByteArray
)

/**
 * Helper class for Attachment CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Create an instance for each native caller/database.
 *
 * Example usage (single isolate):
 * ```
 * val helper = AttachmentHelper("example_app")
 * val id = helper.insert(Attachment(...))
 * val item = helper.findById(id)
 * ```
 */
class AttachmentHelper(private val databaseName: String) {

    fun insert(entity: Attachment): Long {
        val values: Map<String, Any?> = mapOf(
            AttachmentSchema.FILENAME to entity.filename,
            AttachmentSchema.BYTES to entity.bytes
        )
        return NativeSqliteManager.Instance.insert(databaseName, AttachmentSchema.TABLE_NAME, values)
    }

    fun findById(id: Long): Attachment? {
        val result = NativeSqliteManager.Instance.query(
            databaseName,
            "SELECT * FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)} WHERE ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.ID)} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<Attachment> {
        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}")
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
    fun update(entity: Attachment): Int {
        val values: Map<String, Any?> = mapOf(
            AttachmentSchema.FILENAME to entity.filename,
            AttachmentSchema.BYTES to entity.bytes
        )
        return NativeSqliteManager.Instance.update(
            databaseName,
            AttachmentSchema.TABLE_NAME,
            values,
            "${AttachmentSchema.ID} = ?",
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
            AttachmentSchema.TABLE_NAME,
            updates,
            "${AttachmentSchema.ID} = ?",
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
            AttachmentSchema.TABLE_NAME,
            "${AttachmentSchema.ID} = ?",
            listOf(id)
        )
    }

    /**
     * Delete entities matching a WHERE clause.
     * IMPORTANT: whereClause is trusted SQL. Never pass user input; use whereArgs for values.
     * @param whereClause SQL WHERE clause (without "WHERE" keyword)
     * @param whereArgs Arguments for the WHERE clause
     * @return Number of rows deleted
     */
    fun deleteWhere(whereClause: String, whereArgs: List<Any?>? = null): Int {
        return NativeSqliteManager.Instance.delete(
            databaseName,
            AttachmentSchema.TABLE_NAME,
            whereClause,
            whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * @param entities List of entities to insert
     * @return List of inserted row IDs
     */
    fun insertBatch(entities: List<Attachment>): List<Long> {
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
    fun updateBatch(entities: List<Attachment>): Int {
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
     * IMPORTANT: whereClause and orderBy are trusted SQL. Never pass user input; use whereArgs for values.
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
    ): List<Attachment> {
        val sql = buildString {
            append("SELECT * FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}")
            whereClause?.let { append(" WHERE $it") }
            orderBy?.let { append(" ORDER BY $it") }
            if (limit != null) {
                append(" LIMIT $limit")
            } else if (offset != null) {
                append(" LIMIT -1")
            }
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
     * IMPORTANT: whereClause is trusted SQL. Never pass user input; use whereArgs for values.
     * @param whereClause SQL WHERE clause (without "WHERE" keyword)
     * @param whereArgs Arguments for the WHERE clause
     * @return Number of matching entities
     */
    fun count(whereClause: String? = null, whereArgs: List<Any?>? = null): Long {
        val sql = if (whereClause != null) {
            "SELECT COUNT(*) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return 0
        return (rows.firstOrNull()?.firstOrNull() as? Long) ?: 0
    }

    /**
     * Get the maximum value of a column.
     * IMPORTANT: whereClause is trusted SQL. Never pass user input; use whereArgs for values.
     * @param column Column name to get max value from
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Maximum value or null
     */
    fun max(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Any? {
        val sql = if (whereClause != null) {
            "SELECT MAX(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT MAX(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull()
    }

    /**
     * Get the minimum value of a column.
     * IMPORTANT: whereClause is trusted SQL. Never pass user input; use whereArgs for values.
     * @param column Column name to get min value from
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Minimum value or null
     */
    fun min(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Any? {
        val sql = if (whereClause != null) {
            "SELECT MIN(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT MIN(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull()
    }

    /**
     * Get the average value of a column.
     * IMPORTANT: whereClause is trusted SQL. Never pass user input; use whereArgs for values.
     * @param column Column name to get average from
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Average value or null
     */
    fun avg(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Double? {
        val sql = if (whereClause != null) {
            "SELECT AVG(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT AVG(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    /**
     * Get the sum of a column.
     * IMPORTANT: whereClause is trusted SQL. Never pass user input; use whereArgs for values.
     * @param column Column name to sum
     * @param whereClause Optional WHERE clause
     * @param whereArgs Arguments for WHERE clause
     * @return Sum value or null
     */
    fun sum(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Double? {
        val sql = if (whereClause != null) {
            "SELECT SUM(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT SUM(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AttachmentSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): Attachment {
        return Attachment(
            id = row[columnMap.getValue(AttachmentSchema.ID)]?.let { (it as Number).toLong() },
            filename = row[columnMap.getValue(AttachmentSchema.FILENAME)] as String,
            bytes = row[columnMap.getValue(AttachmentSchema.BYTES)] as ByteArray
        )
    }
}
