import Foundation

/**
 * Configuration for opening a database.
 *
 * Public so native iOS code (and generated `DatabaseManager.swift`) can open
 * databases directly through `NativeSqliteManager.shared.openDatabase(config:)`.
 */
public struct DatabaseConfig: Equatable {
    public let name: String
    public let version: Int
    public let onCreate: [String]?
    /// Statements run on every upgrade, after `migrations`.
    public let onUpgrade: [String]?
    /// Statements applied after built-in connection configuration.
    public let onConfigure: [String]?
    public let enableWAL: Bool
    public let enableForeignKeys: Bool
    /// Milliseconds SQLite waits for a busy database.
    public let busyTimeout: Int
    /// Whether to open an existing database without write permission.
    public let readOnly: Bool
    /// Optional absolute directory for the database file.
    public let directory: String?
    /// Optional App Group identifier whose shared container stores the file.
    public let iosAppGroup: String?
    /// Versioned steps: `migrations[v]` upgrades a database from version
    /// `v - 1` to `v`. Same semantics as the Dart and Android config.
    public let migrations: [Int: [String]]?

    public init(
        name: String,
        version: Int = 1,
        onCreate: [String]? = nil,
        onUpgrade: [String]? = nil,
        onConfigure: [String]? = nil,
        enableWAL: Bool = true,
        enableForeignKeys: Bool = true,
        busyTimeout: Int = 5_000,
        readOnly: Bool = false,
        migrations: [Int: [String]]? = nil,
        directory: String? = nil,
        iosAppGroup: String? = nil
    ) {
        self.name = name
        self.version = version
        self.onCreate = onCreate
        self.onUpgrade = onUpgrade
        self.onConfigure = onConfigure
        self.enableWAL = enableWAL
        self.enableForeignKeys = enableForeignKeys
        self.busyTimeout = busyTimeout
        self.readOnly = readOnly
        self.migrations = migrations
        self.directory = directory
        self.iosAppGroup = iosAppGroup
    }

    /// Statements upgrading from `oldVersion` to `version`, in order.
    public func upgradeStatements(from oldVersion: Int) -> [String] {
        guard oldVersion < version else { return onUpgrade ?? [] }
        return ((oldVersion + 1)...version).flatMap { migrations?[$0] ?? [] }
            + (onUpgrade ?? [])
    }
}
