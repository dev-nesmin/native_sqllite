import Foundation
import native_sqlite_ios

/**
 * Native database manager, mirroring the generated DatabaseManager.dart.
 * Call DatabaseManager.shared.initialize() from native iOS code
 * (BGTaskScheduler, App Extensions) before using the generated helpers.
 * Generated helpers are synchronous; always call them from a background thread.
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
public final class DatabaseManager {
    public static let shared = DatabaseManager()

    public static let schemaVersion = 7
    public static let defaultDatabaseName = "example_app"

    public static let onCreateStatements: [String] = [
        AdvancedUserSchema.createTableSql,
        AttachmentSchema.createTableSql,
        CategorySchema.createTableSql,
        CommentSchema.createTableSql,
        FreezedAdvancedUserSchema.createTableSql,
        NoteSchema.createTableSql,
        UserSchema.createTableSql,
        ProductSchema.createTableSql,
        OrderSchema.createTableSql,
        ProfileSchema.createTableSql,
        StyledItemSchema.createTableSql,
        SyncEventSchema.createTableSql,
        TagSchema.createTableSql,
    ] + [
        AdvancedUserSchema.indexSql,
        AttachmentSchema.indexSql,
        CategorySchema.indexSql,
        CommentSchema.indexSql,
        FreezedAdvancedUserSchema.indexSql,
        NoteSchema.indexSql,
        UserSchema.indexSql,
        ProductSchema.indexSql,
        OrderSchema.indexSql,
        ProfileSchema.indexSql,
        StyledItemSchema.indexSql,
        SyncEventSchema.indexSql,
        TagSchema.indexSql,
    ].flatMap { $0 }

    /// Versioned steps: `migrations[v]` upgrades version `v - 1` to `v`.
    public static let migrations: [Int: [String]] = [
        2: [
            "CREATE TABLE \"notes\" (\"id\" TEXT PRIMARY KEY NOT NULL, \"body\" TEXT NOT NULL)",
        ],
        3: [
            "CREATE UNIQUE INDEX \"idx_users_phone\" ON \"users\" (\"phone_number\")",
        ],
        4: [
            "CREATE TABLE \"styled_items_new\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"background_color\" INTEGER NOT NULL, \"text_color\" INTEGER, \"tags\" BLOB NOT NULL, \"created_at\" INTEGER NOT NULL)",
            "INSERT INTO \"styled_items_new\" (\"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\") SELECT \"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\" FROM \"styled_items\"",
            "DROP TABLE \"styled_items\"",
            "ALTER TABLE \"styled_items_new\" RENAME TO \"styled_items\"",
        ],
        5: [
            "CREATE TABLE \"attachments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"filename\" TEXT NOT NULL, \"bytes\" BLOB NOT NULL)",
            "CREATE TABLE \"comments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"parent_id\" INTEGER, \"body\" TEXT NOT NULL, FOREIGN KEY (\"parent_id\") REFERENCES \"comments\"(\"id\") ON DELETE SET NULL)",
            "CREATE TABLE \"styled_items_new\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"background_color\" INTEGER NOT NULL, \"text_color\" INTEGER, \"tags\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)",
            "INSERT INTO \"styled_items_new\" (\"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\") SELECT \"id\", \"name\", \"background_color\", \"text_color\", \"tags\", \"created_at\" FROM \"styled_items\"",
            "DROP TABLE \"styled_items\"",
            "ALTER TABLE \"styled_items_new\" RENAME TO \"styled_items\"",
            "CREATE TABLE \"tags\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"label_text\" TEXT NOT NULL)",
            "CREATE UNIQUE INDEX \"idx_tags_label_unique\" ON \"tags\" (\"label_text\")",
        ],
        6: [
            "CREATE TABLE \"users_new\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"email\" TEXT NOT NULL UNIQUE, \"phone_number\" TEXT, \"address\" TEXT, \"age\" INTEGER NOT NULL DEFAULT 18, \"is_active\" INTEGER NOT NULL DEFAULT 1, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER)",
            "INSERT INTO \"users_new\" (\"id\", \"name\", \"email\", \"phone_number\", \"address\", \"age\", \"is_active\", \"created_at\", \"updated_at\") SELECT \"id\", \"name\", \"email\", \"phone_number\", \"address\", \"age\", \"is_active\", \"created_at\", \"updated_at\" FROM \"users\"",
            "DROP TABLE \"users\"",
            "ALTER TABLE \"users_new\" RENAME TO \"users\"",
            "CREATE INDEX \"idx_users_email\" ON \"users\" (\"email\")",
            "CREATE INDEX \"idx_users_created_at\" ON \"users\" (\"created_at\")",
            "CREATE UNIQUE INDEX \"idx_users_phone\" ON \"users\" (\"phone_number\")",
        ],
        7: [
            "CREATE TABLE \"sync_events\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"source\" TEXT NOT NULL, \"message\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)",
            "CREATE INDEX \"idx_sync_events_created_at\" ON \"sync_events\" (\"created_at\")",
        ],
    ]

    /// Run after every upgrade: creates any missing table or index.
    public static let ensureSchemaStatements: [String] = [
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
    ]

    public static let tableNames: [String] = [
        AdvancedUserSchema.tableName,
        AttachmentSchema.tableName,
        CategorySchema.tableName,
        CommentSchema.tableName,
        FreezedAdvancedUserSchema.tableName,
        NoteSchema.tableName,
        UserSchema.tableName,
        ProductSchema.tableName,
        OrderSchema.tableName,
        ProfileSchema.tableName,
        StyledItemSchema.tableName,
        SyncEventSchema.tableName,
        TagSchema.tableName,
    ]

    private let lock = NSLock()
    private var currentDatabaseName: String?

    private init() {}

    /**
     * Opens the database, creating it or applying pending migrations.
     */
    public func initialize(
        name: String = DatabaseManager.defaultDatabaseName,
        enableWAL: Bool = true,
        enableForeignKeys: Bool = true
    ) throws {
        lock.lock()
        defer { lock.unlock() }
        let manager = NativeSqliteManager.shared
        // This manager owns one reference. Repeated calls by the same
        // native caller do not acquire additional references.
        if let current = currentDatabaseName {
            guard current == name else {
                throw NSError(
                    domain: "DatabaseManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey:
                        "DatabaseManager is already initialized for '(current)'"]
                )
            }
            return
        }
        _ = try manager.openDatabase(config: DatabaseConfig(
            name: name,
            version: Self.schemaVersion,
            onCreate: Self.onCreateStatements,
            onUpgrade: Self.ensureSchemaStatements,
            enableWAL: enableWAL,
            enableForeignKeys: enableForeignKeys,
            migrations: Self.migrations
        ))
        currentDatabaseName = name
    }

    public func close() throws {
        lock.lock()
        defer { lock.unlock() }
        if let name = currentDatabaseName {
            try NativeSqliteManager.shared.closeDatabase(name: name)
        }
        currentDatabaseName = nil
    }

    public var isInitialized: Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentDatabaseName != nil
    }

    public var currentDatabase: String {
        get throws {
            lock.lock()
            defer { lock.unlock() }
            guard let name = currentDatabaseName else {
                throw NSError(domain: "DatabaseManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Call DatabaseManager.shared.initialize() first"])
            }
            return name
        }
    }
}
