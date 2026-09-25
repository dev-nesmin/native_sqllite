package com.example.native_sqlite_example.generated

import android.content.Context
import dev.nesmin.native_sqlite.DatabaseConfig
import dev.nesmin.native_sqlite.NativeSqliteManager

/**
 * Native database manager, mirroring the generated DatabaseManager.dart.
 * Call DatabaseManager.init() from native Android code (WorkManager,
 * Services, App Widgets) before using the generated helpers.
 * Generated helpers are synchronous; always call them from a background thread.
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
object DatabaseManager {
    const val SCHEMA_VERSION = 7
    const val DEFAULT_DATABASE_NAME = "example_app"

    val onCreateStatements: List<String> = listOf(
        AdvancedUserSchema.CREATE_TABLE_SQL,
        AttachmentSchema.CREATE_TABLE_SQL,
        CategorySchema.CREATE_TABLE_SQL,
        CommentSchema.CREATE_TABLE_SQL,
        FreezedAdvancedUserSchema.CREATE_TABLE_SQL,
        NoteSchema.CREATE_TABLE_SQL,
        UserSchema.CREATE_TABLE_SQL,
        ProductSchema.CREATE_TABLE_SQL,
        OrderSchema.CREATE_TABLE_SQL,
        ProfileSchema.CREATE_TABLE_SQL,
        StyledItemSchema.CREATE_TABLE_SQL,
        SyncEventSchema.CREATE_TABLE_SQL,
        TagSchema.CREATE_TABLE_SQL,
    ) + listOf(
        AdvancedUserSchema.INDEX_SQL,
        AttachmentSchema.INDEX_SQL,
        CategorySchema.INDEX_SQL,
        CommentSchema.INDEX_SQL,
        FreezedAdvancedUserSchema.INDEX_SQL,
        NoteSchema.INDEX_SQL,
        UserSchema.INDEX_SQL,
        ProductSchema.INDEX_SQL,
        OrderSchema.INDEX_SQL,
        ProfileSchema.INDEX_SQL,
        StyledItemSchema.INDEX_SQL,
        SyncEventSchema.INDEX_SQL,
        TagSchema.INDEX_SQL,
    ).flatten()

    /** Versioned steps: `migrations[v]` upgrades version `v - 1` to `v`. */
    val migrations: Map<Int, List<String>> = mapOf(
        2 to listOf(
            "CREATE TABLE \"notes\" (\"id\" TEXT PRIMARY KEY NOT NULL, \"body\" TEXT NOT NULL)",
        ),
        3 to listOf(
            "CREATE UNIQUE INDEX \"idx_users_phone\" ON \"users\" (\"phone_number\")",
        ),
        4 to listOf(
            "CREATE TABLE \"styled_items_new\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"background_color\" INTEGER NOT NULL, \"text_color\" INTEGER, \"tags\" BLOB NOT NULL, \"created_at\" INTEGER NOT NULL)",
            "INSERT INTO \"styled_items_new\" (\"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\") SELECT \"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\" FROM \"styled_items\"",
            "DROP TABLE \"styled_items\"",
            "ALTER TABLE \"styled_items_new\" RENAME TO \"styled_items\"",
        ),
        5 to listOf(
            "CREATE TABLE \"attachments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"filename\" TEXT NOT NULL, \"bytes\" BLOB NOT NULL)",
            "CREATE TABLE \"comments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"parent_id\" INTEGER, \"body\" TEXT NOT NULL, FOREIGN KEY (\"parent_id\") REFERENCES \"comments\"(\"id\") ON DELETE SET NULL)",
            "CREATE TABLE \"styled_items_new\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"background_color\" INTEGER NOT NULL, \"text_color\" INTEGER, \"tags\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)",
            "INSERT INTO \"styled_items_new\" (\"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\") SELECT \"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\" FROM \"styled_items\"",
            "DROP TABLE \"styled_items\"",
            "ALTER TABLE \"styled_items_new\" RENAME TO \"styled_items\"",
            "CREATE TABLE \"tags\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"label_text\" TEXT NOT NULL)",
            "CREATE UNIQUE INDEX \"idx_tags_label_unique\" ON \"tags\" (\"label_text\")",
        ),
        6 to listOf(
            "CREATE TABLE \"users_new\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"email\" TEXT NOT NULL UNIQUE, \"phone_number\" TEXT, \"address\" TEXT, \"age\" INTEGER NOT NULL DEFAULT 18, \"is_active\" INTEGER NOT NULL DEFAULT 1, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER)",
            "INSERT INTO \"users_new\" (\"id\", \"name\", \"email\", \"phone_number\", \"address\", \"age\", \"is_active\", \"created_at\", \"updated_at\") SELECT \"id\", \"name\", \"email\", \"phone_number\", \"address\", \"age\", \"is_active\", \"created_at\", \"updated_at\" FROM \"users\"",
            "DROP TABLE \"users\"",
            "ALTER TABLE \"users_new\" RENAME TO \"users\"",
            "CREATE INDEX \"idx_users_email\" ON \"users\" (\"email\")",
            "CREATE INDEX \"idx_users_created_at\" ON \"users\" (\"created_at\")",
            "CREATE UNIQUE INDEX \"idx_users_phone\" ON \"users\" (\"phone_number\")",
        ),
        7 to listOf(
            "CREATE TABLE \"sync_events\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"source\" TEXT NOT NULL, \"message\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)",
            "CREATE INDEX \"idx_sync_events_created_at\" ON \"sync_events\" (\"created_at\")",
        ),
    )

    /** Run after every upgrade: creates any missing table or index. */
    val ensureSchemaStatements: List<String> = listOf(
        "CREATE TABLE IF NOT EXISTS \"advanced_users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"phone_number\" TEXT, \"address\" TEXT, \"country\" TEXT, \"zip_code\" TEXT, \"age\" INTEGER, \"city\" TEXT, \"login_duration\" INTEGER, \"profile_url\" TEXT, \"score\" REAL, \"status\" INTEGER NOT NULL, \"priority\" TEXT, \"created_at\" INTEGER NOT NULL, \"is_verified\" INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"attachments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"filename\" TEXT NOT NULL, \"bytes\" BLOB NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"categories\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL UNIQUE, \"description\" TEXT, \"created_at\" INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"comments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"parent_id\" INTEGER, \"body\" TEXT NOT NULL, FOREIGN KEY (\"parent_id\") REFERENCES \"comments\"(\"id\") ON DELETE SET NULL)",
        "CREATE TABLE IF NOT EXISTS \"freezed_advanced_users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"login_duration\" INTEGER, \"profile_url\" TEXT, \"status\" INTEGER NOT NULL, \"priority\" INTEGER, \"created_at\" INTEGER NOT NULL, \"is_verified\" INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"notes\" (\"id\" TEXT PRIMARY KEY NOT NULL, \"body\" TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"orders\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"user_id\" INTEGER NOT NULL, \"product_id\" INTEGER NOT NULL, \"quantity\" INTEGER NOT NULL, \"total_price\" REAL NOT NULL, \"status\" TEXT NOT NULL DEFAULT 'pending', \"notes\" TEXT, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER, \"delivered_at\" INTEGER, FOREIGN KEY (\"user_id\") REFERENCES \"users\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY (\"product_id\") REFERENCES \"products\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE)",
        "CREATE TABLE IF NOT EXISTS \"products\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"description\" TEXT, \"price\" REAL NOT NULL, \"stock\" INTEGER NOT NULL DEFAULT 0, \"is_available\" INTEGER NOT NULL DEFAULT 1, \"category_id\" INTEGER NOT NULL, \"image_url\" TEXT, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER, FOREIGN KEY (\"category_id\") REFERENCES \"categories\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE)",
        "CREATE TABLE IF NOT EXISTS \"profiles\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"email\" TEXT NOT NULL, \"phone_number\" TEXT, \"settings\" TEXT, \"tags\" TEXT, \"address\" TEXT, \"addresses\" TEXT, \"metadata\" TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"styled_items\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"background_color\" INTEGER NOT NULL, \"text_color\" INTEGER, \"tags\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"sync_events\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"source\" TEXT NOT NULL, \"message\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"tags\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"label_text\" TEXT NOT NULL)",
        "CREATE TABLE IF NOT EXISTS \"users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"email\" TEXT NOT NULL UNIQUE, \"phone_number\" TEXT, \"address\" TEXT, \"age\" INTEGER NOT NULL DEFAULT 18, \"is_active\" INTEGER NOT NULL DEFAULT 1, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER)",
        "CREATE INDEX IF NOT EXISTS \"idx_orders_user_id_created_at\" ON \"orders\" (\"user_id\", \"created_at\")",
        "CREATE INDEX IF NOT EXISTS \"idx_orders_status\" ON \"orders\" (\"status\")",
        "CREATE INDEX IF NOT EXISTS \"idx_products_category_id_price\" ON \"products\" (\"category_id\", \"price\")",
        "CREATE INDEX IF NOT EXISTS \"idx_products_name\" ON \"products\" (\"name\")",
        "CREATE INDEX IF NOT EXISTS \"idx_sync_events_created_at\" ON \"sync_events\" (\"created_at\")",
        "CREATE UNIQUE INDEX IF NOT EXISTS \"idx_tags_label_unique\" ON \"tags\" (\"label_text\")",
        "CREATE INDEX IF NOT EXISTS \"idx_users_email\" ON \"users\" (\"email\")",
        "CREATE INDEX IF NOT EXISTS \"idx_users_created_at\" ON \"users\" (\"created_at\")",
        "CREATE UNIQUE INDEX IF NOT EXISTS \"idx_users_phone\" ON \"users\" (\"phone_number\")",
    )

    val tableNames: List<String> = listOf(
        AdvancedUserSchema.TABLE_NAME,
        AttachmentSchema.TABLE_NAME,
        CategorySchema.TABLE_NAME,
        CommentSchema.TABLE_NAME,
        FreezedAdvancedUserSchema.TABLE_NAME,
        NoteSchema.TABLE_NAME,
        UserSchema.TABLE_NAME,
        ProductSchema.TABLE_NAME,
        OrderSchema.TABLE_NAME,
        ProfileSchema.TABLE_NAME,
        StyledItemSchema.TABLE_NAME,
        SyncEventSchema.TABLE_NAME,
        TagSchema.TABLE_NAME,
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
        // This manager owns one reference. Repeated calls by the same
        // native caller do not acquire additional references.
        currentDatabaseName?.let { current ->
            check(current == name) {
                "DatabaseManager is already initialized for '$current'"
            }
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
