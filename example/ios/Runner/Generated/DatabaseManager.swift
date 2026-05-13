import Foundation

/**
 * Auto-generated native database manager.
 * Mirrors DatabaseManager.dart — call DatabaseManager.shared.initialize() from
 * native iOS code (BGTaskScheduler, App Extensions, Share Extensions).
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
public class DatabaseManager {
    public static let shared = DatabaseManager()

    private var initialized = false
    private var currentDatabaseName: String?

    private init() {}

    public static let onCreateStatements: [String] = [
        AdvancedUserSchema.createTableSql,
        CategorySchema.createTableSql,
        StyledItemSchema.createTableSql,
        FreezedAdvancedUserSchema.createTableSql,
        OrderSchema.createTableSql,
        ProductSchema.createTableSql,
        ProfileSchema.createTableSql,
        UserSchema.createTableSql,
    ]

    public static let tableNames: [String] = [
        "advanced_users",
        "categories",
        "styled_items",
        "freezed_advanced_users",
        "orders",
        "products",
        "profiles",
        "users",
    ]

    /**
     * Initialize the database.
     * Creates tables on first run and runs pending migrations.
     *
     * - Parameters:
     *   - name: Database name (default: "example_app")
     *   - enableWAL: Enable Write-Ahead Logging for better concurrency
     *   - enableForeignKeys: Enable foreign key constraints
     */
    public func initialize(
        name: String = "example_app",
        enableWAL: Bool = true,
        enableForeignKeys: Bool = true
    ) throws {
        guard !initialized else {
            print("DatabaseManager: Already initialized")
            return
        }

        _ = try NativeSqliteManager.shared.openDatabase(config: DatabaseConfig(
            name: name,
            version: SchemaVersionManager.currentVersion,
            onCreate: DatabaseManager.onCreateStatements,
            onUpgrade: nil,
            enableWAL: enableWAL,
            enableForeignKeys: enableForeignKeys
        ))

        try SchemaVersionManager.migrate(databaseName: name)

        currentDatabaseName = name
        initialized = true
        print("✅ DatabaseManager initialized (v\(SchemaVersionManager.currentVersion))")
    }

    public func close() throws {
        if let name = currentDatabaseName {
            try NativeSqliteManager.shared.closeDatabase(name: name)
        }
        initialized = false
        currentDatabaseName = nil
    }

    public var isInitialized: Bool { initialized }

    public var currentDatabase: String {
        get throws {
            guard initialized, let name = currentDatabaseName else {
                throw NSError(domain: "DatabaseManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Call DatabaseManager.shared.initialize() first"])
            }
            return name
        }
    }
}
