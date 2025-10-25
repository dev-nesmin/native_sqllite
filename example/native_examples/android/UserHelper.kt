package com.example.native_sqlite_example.helpers

import android.content.ContentValues
import com.example.native_sqlite_example.generated.UserSchema
import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Data class matching the User model in Dart.
 */
data class User(
    val id: Long? = null,
    val name: String,
    val email: String,
    val age: Int? = null,
    val isActive: Boolean = true,
    val createdAt: Long,
    val lastLogin: Long? = null
)

/**
 * Helper class for User CRUD operations in native Kotlin code.
 *
 * Example usage:
 * ```kotlin
 * val userHelper = UserHelper("app_db")
 *
 * // Insert
 * val userId = userHelper.insert(User(
 *     name = "John Doe",
 *     email = "john@example.com",
 *     createdAt = System.currentTimeMillis()
 * ))
 *
 * // Find
 * val user = userHelper.findById(userId)
 *
 * // Update
 * user?.let {
 *     userHelper.update(it.copy(name = "Jane Doe"))
 * }
 *
 * // Delete
 * userHelper.delete(userId)
 * ```
 */
class UserHelper(private val databaseName: String) {

    /**
     * Inserts a new user into the database.
     * @return The ID of the inserted user
     */
    fun insert(user: User): Long {
        val values = ContentValues().apply {
            put(UserSchema.NAME, user.name)
            put(UserSchema.EMAIL, user.email)
            user.age?.let { put(UserSchema.AGE, it) }
            put(UserSchema.IS_ACTIVE, if (user.isActive) 1 else 0)
            put(UserSchema.CREATED_AT, user.createdAt)
            user.lastLogin?.let { put(UserSchema.LAST_LOGIN, it) }
        }

        return NativeSqliteManager.insert(
            databaseName,
            UserSchema.TABLE_NAME,
            values
        )
    }

    /**
     * Finds a user by ID.
     * @return The user if found, null otherwise
     */
    fun findById(id: Long): User? {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT * FROM ${UserSchema.TABLE_NAME} WHERE ${UserSchema.ID} = ? LIMIT 1",
            listOf(id)
        )

        val rows = result["rows"] as? List<List<Any?>> ?: return null
        if (rows.isEmpty()) return null

        val columns = result["columns"] as List<String>
        return fromRow(columns, rows[0])
    }

    /**
     * Finds all users in the database.
     * @return List of all users
     */
    fun findAll(): List<User> {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT * FROM ${UserSchema.TABLE_NAME}"
        )

        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()
        val columns = result["columns"] as List<String>

        return rows.map { fromRow(columns, it) }
    }

    /**
     * Finds all active users.
     * @return List of active users
     */
    fun findActiveUsers(): List<User> {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT * FROM ${UserSchema.TABLE_NAME} WHERE ${UserSchema.IS_ACTIVE} = ?",
            listOf(1)
        )

        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()
        val columns = result["columns"] as List<String>

        return rows.map { fromRow(columns, it) }
    }

    /**
     * Updates an existing user.
     * @return Number of rows affected
     */
    fun update(user: User): Int {
        require(user.id != null) { "User ID cannot be null for update" }

        val values = ContentValues().apply {
            put(UserSchema.NAME, user.name)
            put(UserSchema.EMAIL, user.email)
            user.age?.let { put(UserSchema.AGE, it) }
            put(UserSchema.IS_ACTIVE, if (user.isActive) 1 else 0)
            put(UserSchema.CREATED_AT, user.createdAt)
            user.lastLogin?.let { put(UserSchema.LAST_LOGIN, it) }
        }

        return NativeSqliteManager.update(
            databaseName,
            UserSchema.TABLE_NAME,
            values,
            where = "${UserSchema.ID} = ?",
            whereArgs = listOf(user.id)
        )
    }

    /**
     * Deletes a user by ID.
     * @return Number of rows deleted
     */
    fun delete(id: Long): Int {
        return NativeSqliteManager.delete(
            databaseName,
            UserSchema.TABLE_NAME,
            where = "${UserSchema.ID} = ?",
            whereArgs = listOf(id)
        )
    }

    /**
     * Counts total users.
     * @return Total number of users
     */
    fun count(): Int {
        val result = NativeSqliteManager.query(
            databaseName,
            "SELECT COUNT(*) as count FROM ${UserSchema.TABLE_NAME}"
        )

        val rows = result["rows"] as? List<List<Any?>> ?: return 0
        if (rows.isEmpty()) return 0

        return (rows[0][0] as Long).toInt()
    }

    /**
     * Converts a database row to a User object.
     */
    private fun fromRow(columns: List<String>, row: List<Any?>): User {
        val columnMap = columns.withIndex().associate { it.value to it.index }

        return User(
            id = row[columnMap[UserSchema.ID]!!] as Long,
            name = row[columnMap[UserSchema.NAME]!!] as String,
            email = row[columnMap[UserSchema.EMAIL]!!] as String,
            age = row[columnMap[UserSchema.AGE]!!] as? Long?,?.toInt(),
            isActive = (row[columnMap[UserSchema.IS_ACTIVE]!!] as Long) == 1L,
            createdAt = row[columnMap[UserSchema.CREATED_AT]!!] as Long,
            lastLogin = row[columnMap[UserSchema.LAST_LOGIN]!!] as? Long
        )
    }
}
