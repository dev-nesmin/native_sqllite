@file:Suppress("UNCHECKED_CAST")

package com.example.native_sqlite_example.generated

import android.net.Uri
import dev.nesmin.native_sqlite.NativeSqliteManager
import java.time.Duration
import java.time.Instant

/**
 * Data class for AdvancedUser.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
data class AdvancedUser(
    val id: Long? = null,
    val name: String,
    val phoneNumber: String? = null,
    val address: String? = null,
    val country: String? = null,
    val zipCode: String? = null,
    val age: Long? = null,
    val city: String? = null,
    val loginDuration: Duration? = null,
    val profileUrl: Uri? = null,
    val score: Double? = null,
    val status: UserStatus,
    val priority: Priority? = null,
    val createdAt: Instant,
    val isVerified: Boolean
)

/**
 * Helper class for AdvancedUser CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Create an instance for each native caller/database.
 *
 * Example usage (single isolate):
 * ```
 * val helper = AdvancedUserHelper("example_app")
 * val id = helper.insert(AdvancedUser(...))
 * val item = helper.findById(id)
 * ```
 */
class AdvancedUserHelper(private val databaseName: String) {

    fun insert(entity: AdvancedUser): Long {
        val values: Map<String, Any?> = mapOf(
            AdvancedUserSchema.NAME to entity.name,
            AdvancedUserSchema.PHONE_NUMBER to entity.phoneNumber,
            AdvancedUserSchema.ADDRESS to entity.address,
            AdvancedUserSchema.COUNTRY to entity.country,
            AdvancedUserSchema.ZIP_CODE to entity.zipCode,
            AdvancedUserSchema.AGE to entity.age,
            AdvancedUserSchema.CITY to entity.city,
            AdvancedUserSchema.LOGIN_DURATION to entity.loginDuration?.let { it.toMillis() },
            AdvancedUserSchema.PROFILE_URL to entity.profileUrl?.let { it.toString() },
            AdvancedUserSchema.SCORE to entity.score,
            AdvancedUserSchema.STATUS to entity.status.ordinal.toLong(),
            AdvancedUserSchema.PRIORITY to entity.priority?.let { it.name },
            AdvancedUserSchema.CREATED_AT to entity.createdAt.toEpochMilli(),
            AdvancedUserSchema.IS_VERIFIED to if (entity.isVerified) 1L else 0L
        )
        return NativeSqliteManager.Instance.insert(databaseName, AdvancedUserSchema.TABLE_NAME, values)
    }

    fun findById(id: Long): AdvancedUser? {
        val result = NativeSqliteManager.Instance.query(
            databaseName,
            "SELECT * FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)} WHERE ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.ID)} = ? LIMIT 1",
            listOf(id)
        )
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null
        val columns = result["columns"] as List<String>
        val columnMap = columns.withIndex().associate { it.value to it.index }
        return fromRow(columnMap, rows[0])
    }

    fun findAll(): List<AdvancedUser> {
        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}")
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
        val values: Map<String, Any?> = mapOf(
            AdvancedUserSchema.NAME to entity.name,
            AdvancedUserSchema.PHONE_NUMBER to entity.phoneNumber,
            AdvancedUserSchema.ADDRESS to entity.address,
            AdvancedUserSchema.COUNTRY to entity.country,
            AdvancedUserSchema.ZIP_CODE to entity.zipCode,
            AdvancedUserSchema.AGE to entity.age,
            AdvancedUserSchema.CITY to entity.city,
            AdvancedUserSchema.LOGIN_DURATION to entity.loginDuration?.let { it.toMillis() },
            AdvancedUserSchema.PROFILE_URL to entity.profileUrl?.let { it.toString() },
            AdvancedUserSchema.SCORE to entity.score,
            AdvancedUserSchema.STATUS to entity.status.ordinal.toLong(),
            AdvancedUserSchema.PRIORITY to entity.priority?.let { it.name },
            AdvancedUserSchema.CREATED_AT to entity.createdAt.toEpochMilli(),
            AdvancedUserSchema.IS_VERIFIED to if (entity.isVerified) 1L else 0L
        )
        return NativeSqliteManager.Instance.update(
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
        return NativeSqliteManager.Instance.update(
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
        return NativeSqliteManager.Instance.delete(
            databaseName,
            AdvancedUserSchema.TABLE_NAME,
            "${AdvancedUserSchema.ID} = ?",
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
    fun updateBatch(entities: List<AdvancedUser>): Int {
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
    ): List<AdvancedUser> {
        val sql = buildString {
            append("SELECT * FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}")
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
            "SELECT COUNT(*) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT COUNT(*) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}"
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
            "SELECT MAX(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT MAX(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}"
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
            "SELECT MIN(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT MIN(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}"
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
            "SELECT AVG(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT AVG(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}"
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
            "SELECT SUM(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)} WHERE $whereClause"
        } else {
            "SELECT SUM(${NativeSqliteManager.quoteIdentifier(column)}) FROM ${NativeSqliteManager.quoteIdentifier(AdvancedUserSchema.TABLE_NAME)}"
        }
        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)
        val rows = result["rows"] as? List<List<Any?>> ?: return null
        return rows.firstOrNull()?.firstOrNull() as? Double
    }

    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): AdvancedUser {
        return AdvancedUser(
            id = row[columnMap.getValue(AdvancedUserSchema.ID)]?.let { (it as Number).toLong() },
            name = row[columnMap.getValue(AdvancedUserSchema.NAME)] as String,
            phoneNumber = row[columnMap.getValue(AdvancedUserSchema.PHONE_NUMBER)]?.let { it as String },
            address = row[columnMap.getValue(AdvancedUserSchema.ADDRESS)]?.let { it as String },
            country = row[columnMap.getValue(AdvancedUserSchema.COUNTRY)]?.let { it as String },
            zipCode = row[columnMap.getValue(AdvancedUserSchema.ZIP_CODE)]?.let { it as String },
            age = row[columnMap.getValue(AdvancedUserSchema.AGE)]?.let { (it as Number).toLong() },
            city = row[columnMap.getValue(AdvancedUserSchema.CITY)]?.let { it as String },
            loginDuration = row[columnMap.getValue(AdvancedUserSchema.LOGIN_DURATION)]?.let { Duration.ofMillis((it as Number).toLong()) },
            profileUrl = row[columnMap.getValue(AdvancedUserSchema.PROFILE_URL)]?.let { Uri.parse(it as String) },
            score = row[columnMap.getValue(AdvancedUserSchema.SCORE)]?.let { (it as Number).toDouble() },
            status = UserStatus.entries[(row[columnMap.getValue(AdvancedUserSchema.STATUS)] as Number).toInt()],
            priority = row[columnMap.getValue(AdvancedUserSchema.PRIORITY)]?.let { Priority.valueOf(it as String) },
            createdAt = Instant.ofEpochMilli((row[columnMap.getValue(AdvancedUserSchema.CREATED_AT)] as Number).toLong()),
            isVerified = (row[columnMap.getValue(AdvancedUserSchema.IS_VERIFIED)] as Number).toLong() == 1L
        )
    }
}
