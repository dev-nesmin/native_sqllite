package com.example.native_sqlite_example.generated

import android.content.Context
import dev.nesmin.native_sqlite.DatabaseConfig
import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Native database manager, mirroring the generated DatabaseManager.dart.
 * Call DatabaseManager.init() from native Android code (WorkManager,
 * Services, App Widgets) before using the generated helpers.
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
object DatabaseManager {
    const val SCHEMA_VERSION = 1
    const val DEFAULT_DATABASE_NAME = "example_app"

    val onCreateStatements: List<String> = listOf(
        AdvancedUserSchema.CREATE_TABLE_SQL,
        CategorySchema.CREATE_TABLE_SQL,
        StyledItemSchema.CREATE_TABLE_SQL,
        FreezedAdvancedUserSchema.CREATE_TABLE_SQL,
        OrderSchema.CREATE_TABLE_SQL,
        ProductSchema.CREATE_TABLE_SQL,
        ProfileSchema.CREATE_TABLE_SQL,
        UserSchema.CREATE_TABLE_SQL,
    ) + listOf(
        AdvancedUserSchema.INDEX_SQL,
        CategorySchema.INDEX_SQL,
        StyledItemSchema.INDEX_SQL,
        FreezedAdvancedUserSchema.INDEX_SQL,
        OrderSchema.INDEX_SQL,
        ProductSchema.INDEX_SQL,
        ProfileSchema.INDEX_SQL,
        UserSchema.INDEX_SQL,
    ).flatten()

    /** Versioned steps: `migrations[v]` upgrades version `v - 1` to `v`. */
    val migrations: Map<Int, List<String>> = mapOf(
    )

    /** Run after every upgrade: creates any missing table or index. */
    val ensureSchemaStatements: List<String> = listOf(
        "CREATE TABLE IF NOT EXISTS advanced_users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone_number TEXT, address TEXT, country TEXT, zip_code TEXT, age INTEGER, city TEXT, login_duration INTEGER, profile_url TEXT, score REAL, status INTEGER NOT NULL, priority TEXT, created_at INTEGER NOT NULL, is_verified INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, created_at INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS styled_items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, background_color INTEGER NOT NULL, text_color INTEGER, tags TEXT NOT NULL, created_at INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS freezed_advanced_users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, login_duration INTEGER, profile_url TEXT, status INTEGER NOT NULL, priority INTEGER, created_at INTEGER NOT NULL, is_verified INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL, total_price REAL NOT NULL, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, created_at INTEGER NOT NULL, updated_at INTEGER, delivered_at INTEGER, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE)",
        "CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, price REAL NOT NULL, stock INTEGER NOT NULL DEFAULT 0, is_available INTEGER NOT NULL DEFAULT 1, category_id INTEGER NOT NULL, image_url TEXT, created_at INTEGER NOT NULL, updated_at INTEGER, FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE)",
        "CREATE TABLE IF NOT EXISTS profiles (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL, phone_number TEXT, settings TEXT, tags TEXT, address TEXT, addresses TEXT, metadata TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, phone_number TEXT, address TEXT, age INTEGER NOT NULL DEFAULT 1, is_active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL, updated_at INTEGER)",
        "CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at ON orders (user_id, created_at)",
        "CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status)",
        "CREATE INDEX IF NOT EXISTS idx_products_category_id_price ON products (category_id, price)",
        "CREATE INDEX IF NOT EXISTS idx_products_name ON products (name)",
        "CREATE INDEX IF NOT EXISTS idx_users_email ON users (email)",
        "CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at)",
    )

    val tableNames: List<String> = listOf(
        AdvancedUserSchema.TABLE_NAME,
        CategorySchema.TABLE_NAME,
        StyledItemSchema.TABLE_NAME,
        FreezedAdvancedUserSchema.TABLE_NAME,
        OrderSchema.TABLE_NAME,
        ProductSchema.TABLE_NAME,
        ProfileSchema.TABLE_NAME,
        UserSchema.TABLE_NAME,
    )

    @Volatile
    private var currentDatabaseName: String? = null

    /**
     * Opens the database, creating it or applying pending migrations.
     *
     * @param context Any context; the application context is kept
     * @param name Database name (default: example_app)
     */
    @Synchronized
    fun init(
        context: Context,
        name: String = DEFAULT_DATABASE_NAME,
        enableWAL: Boolean = true,
        enableForeignKeys: Boolean = true,
    ) {
        val manager = NativeSqliteManager.Instance
        manager.initialize(context)
        // Already opened (e.g. by Dart through the plugin, which shares this
        // manager) with the same generated schema and migrations.
        if (manager.isDatabaseOpen(name)) {
            currentDatabaseName = name
            return
        }
        manager.openDatabase(
            DatabaseConfig(
                name = name,
                version = SCHEMA_VERSION,
                onCreate = onCreateStatements,
                onUpgrade = ensureSchemaStatements,
                enableWAL = enableWAL,
                enableForeignKeys = enableForeignKeys,
                migrations = migrations,
            )
        )
        currentDatabaseName = name
    }

    @Synchronized
    fun close() {
        currentDatabaseName?.let { NativeSqliteManager.Instance.closeDatabase(it) }
        currentDatabaseName = null
    }

    val isInitialized: Boolean get() = currentDatabaseName != null

    val currentDatabase: String
        get() = checkNotNull(currentDatabaseName) { "Call DatabaseManager.init() first" }
}
