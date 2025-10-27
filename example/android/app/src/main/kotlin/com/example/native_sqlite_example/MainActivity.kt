package com.example.native_sqlite_example

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.native_sqlite_example.generated.UserSchema
import com.example.native_sqlite_example.generated.ProductSchema
import com.example.native_sqlite_example.generated.OrderSchema
import dev.nesmin.native_sqlite_android.NativeSqliteManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.native_sqlite_example/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "testNativeAccess" -> {
                    try {
                        val testResult = testNativeAccess()
                        result.success(testResult)
                    } catch (e: Exception) {
                        result.error("ERROR", "Native access failed: ${e.message}", null)
                    }
                }
                "createUserFromNative" -> {
                    try {
                        val name = call.argument<String>("name") ?: "Unknown"
                        val email = call.argument<String>("email") ?: "unknown@example.com"
                        val userId = createUserFromNative(name, email)
                        result.success(userId)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to create user: ${e.message}", null)
                    }
                }
                "getUsersFromNative" -> {
                    try {
                        val users = getUsersFromNative()
                        result.success(users)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get users: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Demonstrates native SQLite access from Kotlin code
     * This code can be called from anywhere in your Android app
     * without going through Flutter
     */
    private fun testNativeAccess(): String {
        val dbName = "example_app"
        val results = StringBuilder()

        try {
            // Test 1: Create a user using generated schema constants
            results.append("Test 1: Creating user using generated schema...\n")
            val userId = NativeSqliteManager.insert(
                dbName,
                UserSchema.TABLE_NAME,
                mapOf(
                    UserSchema.NAME to "Native Android User",
                    UserSchema.EMAIL to "android${System.currentTimeMillis()}@native.com",
                    UserSchema.AGE to 30,
                    UserSchema.IS_ACTIVE to 1,
                    UserSchema.CREATED_AT to System.currentTimeMillis()
                )
            )
            results.append("✓ Created user with ID: $userId\n\n")

            // Test 2: Query users
            results.append("Test 2: Querying users...\n")
            val queryResult = NativeSqliteManager.query(
                dbName,
                "SELECT ${UserSchema.NAME}, ${UserSchema.EMAIL} FROM ${UserSchema.TABLE_NAME} " +
                        "WHERE ${UserSchema.IS_ACTIVE} = ? LIMIT 5",
                listOf(1)
            )

            val users = queryResult.mapList
            results.append("✓ Found ${users.size} active users:\n")
            users.forEach { user ->
                results.append("  - ${user[UserSchema.NAME]}: ${user[UserSchema.EMAIL]}\n")
            }
            results.append("\n")

            // Test 3: Update user
            results.append("Test 3: Updating user...\n")
            val updatedRows = NativeSqliteManager.update(
                dbName,
                UserSchema.TABLE_NAME,
                mapOf(UserSchema.NAME to "Updated Native User"),
                "id = ?",
                listOf(userId)
            )
            results.append("✓ Updated $updatedRows row(s)\n\n")

            // Test 4: Count users
            results.append("Test 4: Counting users...\n")
            val countResult = NativeSqliteManager.query(
                dbName,
                "SELECT COUNT(*) as count FROM ${UserSchema.TABLE_NAME}",
                emptyList()
            )
            val count = countResult.mapList.firstOrNull()?.get("count")
            results.append("✓ Total users: $count\n\n")

            // Test 5: Complex query with join (if products exist)
            results.append("Test 5: Complex JOIN query...\n")
            try {
                val joinResult = NativeSqliteManager.query(
                    dbName,
                    """
                    SELECT
                        u.${UserSchema.NAME} as user_name,
                        COUNT(o.id) as order_count
                    FROM ${UserSchema.TABLE_NAME} u
                    LEFT JOIN ${OrderSchema.TABLE_NAME} o ON u.id = o.${OrderSchema.USER_ID}
                    GROUP BY u.id
                    LIMIT 5
                    """.trimIndent(),
                    emptyList()
                )
                results.append("✓ Found ${joinResult.mapList.size} users with order counts\n")
                joinResult.mapList.forEach { row ->
                    results.append("  - ${row["user_name"]}: ${row["order_count"]} orders\n")
                }
            } catch (e: Exception) {
                results.append("⚠ JOIN query skipped (tables may be empty)\n")
            }

            results.append("\n✅ All native access tests completed successfully!")
        } catch (e: Exception) {
            results.append("\n❌ Error: ${e.message}")
            e.printStackTrace()
        }

        return results.toString()
    }

    /**
     * Create a user from native Android code
     */
    private fun createUserFromNative(name: String, email: String): Long {
        return NativeSqliteManager.insert(
            "example_app",
            UserSchema.TABLE_NAME,
            mapOf(
                UserSchema.NAME to name,
                UserSchema.EMAIL to email,
                UserSchema.AGE to 25,
                UserSchema.IS_ACTIVE to 1,
                UserSchema.CREATED_AT to System.currentTimeMillis()
            )
        )
    }

    /**
     * Get users from native Android code
     */
    private fun getUsersFromNative(): List<Map<String, Any?>> {
        val result = NativeSqliteManager.query(
            "example_app",
            "SELECT * FROM ${UserSchema.TABLE_NAME} ORDER BY ${UserSchema.CREATED_AT} DESC LIMIT 10",
            emptyList()
        )
        return result.mapList
    }
}
