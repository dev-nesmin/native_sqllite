import Foundation

/**
 * Configuration for opening a database.
 *
 * Public so native iOS code (and generated `DatabaseManager.swift`) can open
 * databases directly through `NativeSqliteManager.shared.openDatabase(config:)`.
 */
public struct DatabaseConfig {
    public let name: String
    public let version: Int
    public let onCreate: [String]?
    /// Statements run on every upgrade, after `migrations`.
    public let onUpgrade: [String]?
    public let enableWAL: Bool
    public let enableForeignKeys: Bool
    /// Versioned steps: `migrations[v]` upgrades a database from version
    /// `v - 1` to `v`. Same semantics as the Dart and Android config.
    public let migrations: [Int: [String]]?

    public init(
        name: String,
        version: Int = 1,
        onCreate: [String]? = nil,
        onUpgrade: [String]? = nil,
        enableWAL: Bool = true,
        enableForeignKeys: Bool = true,
        migrations: [Int: [String]]? = nil
    ) {
        self.name = name
        self.version = version
        self.onCreate = onCreate
        self.onUpgrade = onUpgrade
        self.enableWAL = enableWAL
        self.enableForeignKeys = enableForeignKeys
        self.migrations = migrations
    }

    /// Statements upgrading from `oldVersion` to `version`, in order.
    public func upgradeStatements(from oldVersion: Int) -> [String] {
        guard oldVersion < version else { return onUpgrade ?? [] }
        return ((oldVersion + 1)...version).flatMap { migrations?[$0] ?? [] }
            + (onUpgrade ?? [])
    }
}
