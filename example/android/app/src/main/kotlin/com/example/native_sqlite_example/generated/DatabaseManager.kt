package com.example.native_sqlite_example.generated

import android.content.Context
import dev.nesmin.native_sqlite.DatabaseConfig
import dev.nesmin.native_sqlite.NativeSqliteManager
import com.example.native_sqlite_example.generated.migrations.SchemaVersionManager

/**
 * Auto-generated native database manager.
 * Mirrors DatabaseManager.dart — call DatabaseManager.init() from
 * native Android code (WorkManager, Services, App Widgets).
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
object DatabaseManager {

    private var initialized = false
    private var currentDatabaseName: String? = null

    val onCreateStatements: List<String> = listOf(
        AdvancedUserSchema.CREATE_TABLE_SQL,
        CategorySchema.CREATE_TABLE_SQL,
        StyledItemSchema.CREATE_TABLE_SQL,
        FreezedAdvancedUserSchema.CREATE_TABLE_SQL,
        OrderSchema.CREATE_TABLE_SQL,
        ProductSchema.CREATE_TABLE_SQL,
        ProfileSchema.CREATE_TABLE_SQL,
        UserSchema.CREATE_TABLE_SQL,
    )

    val tableNames: List<String> = listOf(
        "advanced_users",
        "categories",
        "styled_items",
        "freezed_advanced_users",
        "orders",
        "products",
        "profiles",
        "users",
    )

    /**
     * Initialize the database.
     * Creates tables on first run and runs pending migrations.
     *
     * @param context Android application context
     * @param name Database name (default: "example_app")
     * @param enableWAL Enable Write-Ahead Logging for better concurrency
     * @param enableForeignKeys Enable foreign key constraints
     */
    fun init(
        context: Context,
        name: String = "example_app",
        enableWAL: Boolean = true,
        enableForeignKeys: Boolean = true,
    ) {
        if (initialized) {
            android.util.Log.d("DatabaseManager", "Already initialized")
            return
        }

        try {
            NativeSqliteManager.Instance.initialize(context)

            NativeSqliteManager.Instance.openDatabase(
                DatabaseConfig(
                    name = name,
                    version = SchemaVersionManager.CURRENT_VERSION,
                    onCreate = onCreateStatements,
                    onUpgrade = null,
                    enableWAL = enableWAL,
                    enableForeignKeys = enableForeignKeys,
                )
            )

            SchemaVersionManager.migrate(name)

            currentDatabaseName = name
            initialized = true
            android.util.Log.d("DatabaseManager", "✅ Initialized (v${SchemaVersionManager.CURRENT_VERSION})")
        } catch (e: Exception) {
            android.util.Log.e("DatabaseManager", "❌ Init failed: ${e.message}", e)
            throw e
        }
    }

    fun close() {
        currentDatabaseName?.let { NativeSqliteManager.Instance.closeDatabase(it) }
        initialized = false
        currentDatabaseName = null
    }

    val isInitialized: Boolean get() = initialized

    val currentDatabase: String
        get() {
            check(initialized && currentDatabaseName != null) {
                "Call DatabaseManager.init() first"
            }
            return currentDatabaseName!!
        }
}
