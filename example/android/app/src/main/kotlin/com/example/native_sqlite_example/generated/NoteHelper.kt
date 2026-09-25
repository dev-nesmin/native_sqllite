@file:Suppress("UNCHECKED_CAST")

package com.example.native_sqlite_example.generated

import dev.nesmin.native_sqlite.NativeSqliteManager
import java.util.UUID

/**
 * Data class for Note.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class Note(
    val id: String? = null,
    val body: String
)

/**
 * Helper class for Note CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Create an instance for each native caller/database.
 *
 * Example usage (single isolate):
 * ```
 * val helper = NoteHelper("example_app")
 * val id = helper.insert(Note(...))
 * val item = helper.findById(id)
 * ```
 */
class NoteHelper(private val databaseName: String) {

    fun insert(entity: Note): String {
        val primaryKeyValue = entity.id ?: UUID.randomUUID().toString()
        val values: Map<String, Any?> = mapOf(
            NoteSchema.ID to primaryKeyValue,
            NoteSchema.BODY to entity.body
        )
        NativeSqliteManager.Instance.insert(databaseName, NoteSchema.TABLE_NAME, values)
        return primaryKeyValue
    }

    fun findById(id: String): Note? {
        val result = NativeSqliteManager.Instance.query(
            databaseName,
            "SELECT * FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)} WHERE ${NativeSqliteManager.quoteIdentifier(NoteSchema.ID)} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<Note> {
        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}")
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
    fun update(entity: Note): Int {
        val values: Map<String, Any?> = mapOf(
            NoteSchema.BODY to entity.body
        )
        return NativeSqliteManager.Instance.update(
            databaseName,
            NoteSchema.TABLE_NAME,
            values,
            "${NoteSchema.ID} = ?",
            listOf(entity.id)
        )
    }

    /**
     * Update specific fields of an entity.
     * @param id The primary key value
     * @param updates Map of column names to new values
     * @return Number of rows affected
     */
    fun updatePartial(id: String, updates: Map<String, Any?>): Int {
        return NativeSqliteManager.Instance.update(
            databaseName,
            NoteSchema.TABLE_NAME,
            updates,
            "${NoteSchema.ID} = ?",
            listOf(id)
        )
    }

    /**
     * Delete an entity by its primary key.
     * @param id The primary key value
     * @return Number of rows deleted
     */
    fun delete(id: String): Int {
        return NativeSqliteManager.Instance.delete(
            databaseName,
            NoteSchema.TABLE_NAME,
            "${NoteSchema.ID} = ?",
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
            NoteSchema.TABLE_NAME,
            whereClause,
            whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * @param entities List of entities to insert
     * @return List of inserted row IDs
     */
    fun insertBatch(entities: List<Note>): List<String> {
        val db = NativeSqliteManager.Instance.getDatabase(databaseName)
        val results = mutableListOf<String>()
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
    fun updateBatch(entities: List<Note>): Int {
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
    fun deleteBatch(ids: List<String>): Int {
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
    ): List<Note> {
        val sql = buildString {
            append("SELECT * FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}")
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
            "SELECT COUNT(*) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}"
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
            "SELECT MAX(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT MAX(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}"
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
            "SELECT MIN(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT MIN(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}"
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
            "SELECT AVG(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT AVG(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}"
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
            "SELECT SUM(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT SUM(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(NoteSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): Note {
        return Note(
            id = row[columnMap.getValue(NoteSchema.ID)]?.let { it as String },
            body = row[columnMap.getValue(NoteSchema.BODY)] as String
        )
    }
}
