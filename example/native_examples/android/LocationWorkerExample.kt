package com.example.native_sqlite_example.workers

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.example.native_sqlite_example.generated.UserSchema
import com.example.native_sqlite_example.helpers.UserHelper
import dev.nesmin.native_sqlite.DatabaseConfig
import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Example WorkManager worker that uses the generated schema.
 *
 * This demonstrates how to access the database from native Android code
 * (e.g., WorkManager, Services, BroadcastReceivers) using the same schema
 * defined in your Dart models.
 */
class LocationWorkerExample(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val DB_NAME = "app_db"
    }

    override fun doWork(): Result {
        return try {
            // Initialize if needed
            NativeSqliteManager.initialize(applicationContext)

            // Open database with generated schema
            if (!NativeSqliteManager.isDatabaseOpen(DB_NAME)) {
                NativeSqliteManager.openDatabase(
                    DatabaseConfig(
                        name = DB_NAME,
                        version = 1,
                        onCreate = listOf(
                            UserSchema.CREATE_TABLE_SQL
                        ),
                        enableWAL = true,
                        enableForeignKeys = true
                    )
                )
            }

            // Use the helper for type-safe operations
            val userHelper = UserHelper(DB_NAME)

            // Insert a user from background task
            val userId = userHelper.insert(
                User(
                    name = "Background User",
                    email = "bg${System.currentTimeMillis()}@example.com",
                    isActive = true,
                    createdAt = System.currentTimeMillis(),
                    lastLogin = System.currentTimeMillis()
                )
            )

            android.util.Log.d("LocationWorker", "Inserted user with ID: $userId")

            // Query active users
            val activeUsers = userHelper.findActiveUsers()
            android.util.Log.d("LocationWorker", "Found ${activeUsers.size} active users")

            // Update user
            activeUsers.firstOrNull()?.let { user ->
                userHelper.update(user.copy(lastLogin = System.currentTimeMillis()))
                android.util.Log.d("LocationWorker", "Updated user ${user.id}")
            }

            Result.success()
        } catch (e: Exception) {
            android.util.Log.e("LocationWorker", "Error accessing database", e)
            Result.failure()
        }
    }
}
