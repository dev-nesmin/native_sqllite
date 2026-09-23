package com.example.native_sqlite_example

import com.example.native_sqlite_example.generated.DatabaseManager
import com.example.native_sqlite_example.generated.OrderSchema
import com.example.native_sqlite_example.generated.User
import com.example.native_sqlite_example.generated.UserHelper
import com.example.native_sqlite_example.generated.UserSchema
import dev.nesmin.native_sqlite.NativeSqliteManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.Instant

/**
 * Handles the example's "Native Integration" screen: the same database the
 * Flutter side uses, accessed from Kotlin through the generated helpers.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.native_sqlite_example/native",
        ).setMethodCallHandler { call, result ->
            try {
                // Reuses the connection Flutter opened, or opens and migrates it.
                DatabaseManager.init(applicationContext)
                val users = UserHelper(DatabaseManager.currentDatabase)

                when (call.method) {
                    "testNativeAccess" -> result.success(runAccessTests(users))
                    "createUserFromNative" -> {
                        val name = call.argument<String>("name")
                        val email = call.argument<String>("email")
                        if (name == null || email == null) {
                            result.error("INVALID_ARGS", "name and email are required", null)
                        } else {
                            result.success(
                                users.insert(
                                    User(name = name, email = email, age = 25, isActive = true, createdAt = Instant.now())
                                )
                            )
                        }
                    }
                    "getUsersFromNative" -> result.success(
                        users.findWhere(orderBy = "${UserSchema.CREATED_AT} DESC", limit = 10).map(::toMap)
                    )
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("NATIVE_SQLITE_ERROR", e.message, null)
            }
        }
    }

    private fun runAccessTests(users: UserHelper): String = buildString {
        appendLine("Native SQLite access from Kotlin\n")

        val id = users.insert(
            User(
                name = "Native Android User",
                email = "android${System.currentTimeMillis()}@native.dev",
                age = 30,
                isActive = true,
                createdAt = Instant.now(),
            )
        )
        appendLine("✓ Inserted user #$id")

        val user = checkNotNull(users.findById(id)) { "User #$id not found" }
        appendLine("✓ Read back: ${user.name} <${user.email}>, created ${user.createdAt}")

        val updated = users.update(user.copy(name = "Updated Native User", updatedAt = Instant.now()))
        appendLine("✓ Updated $updated row(s)")

        val active = users.count("${UserSchema.IS_ACTIVE} = ?", listOf(1))
        appendLine("✓ Active users: $active")

        val joined = NativeSqliteManager.Instance.query(
            DatabaseManager.currentDatabase,
            """
            SELECT u.${UserSchema.NAME} AS user_name, COUNT(o.${OrderSchema.ID}) AS order_count
            FROM ${UserSchema.TABLE_NAME} u
            LEFT JOIN ${OrderSchema.TABLE_NAME} o ON o.${OrderSchema.USER_ID} = u.${UserSchema.ID}
            GROUP BY u.${UserSchema.ID} LIMIT 5
            """.trimIndent(),
        )
        @Suppress("UNCHECKED_CAST")
        val rows = joined["rows"] as? List<List<Any?>> ?: emptyList()
        appendLine("✓ JOIN returned ${rows.size} row(s)")
        rows.forEach { appendLine("  - ${it[0]}: ${it[1]} orders") }

        append("\n✅ All native access tests passed")
    }

    private fun toMap(user: User): Map<String, Any?> = mapOf(
        "id" to user.id,
        "name" to user.name,
        "email" to user.email,
        "age" to user.age,
    )
}
