import Foundation
import SQLite3

/**
 * Singleton manager for SQLite databases on iOS.
 *
 * This manager handles multiple databases and ensures thread-safe access.
 * It can be used directly from native iOS code (e.g., Background Tasks, App Extensions)
 * without going through Flutter method channels.
 *
 * Example usage from native iOS code:
 * ```swift
 * // In a Background Task or App Extension
 * let db = try NativeSqliteManager.shared.getDatabase(name: "location_db")
 * try NativeSqliteManager.shared.insert(
 *     name: "location_db",
 *     table: "locations",
 *     values: [
 *         "latitude": 37.7749,
 *         "longitude": -122.4194,
 *         "timestamp": Date().timeIntervalSince1970
 *     ]
 * )
 * ```
 */
public class NativeSqliteManager {
    public static let shared = NativeSqliteManager()

    private var databases: [String: OpaquePointer] = [:]
    private var databaseVersions: [String: Int] = [:]
    private let queue = DispatchQueue(label: "dev.nesmin.native_sqlite", attributes: .concurrent)

    private init() {}

    /**
     * Opens a database with the given configuration.
     *
     * - Returns: The absolute path to the database file
     */
    public func openDatabase(config: DatabaseConfig) throws -> String {
        return try queue.sync(flags: .barrier) {
            // Close existing database if open
            closeDatabaseLocked(name: config.name)

            let path = getDatabasePath(name: config.name)
            var db: OpaquePointer?

            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
            guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to open database: \(String(cString: sqlite3_errmsg(db)))"])
            }

            guard let database = db else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database handle is nil"])
            }

            // Enable WAL mode if requested
            if config.enableWAL {
                try executeInternal(db: database, sql: "PRAGMA journal_mode=WAL")
            }

            // Get current version
            let currentVersion = try getDatabaseVersion(db: database)
            if currentVersion > config.version {
                sqlite3_close(database)
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database is at version \(currentVersion), newer than the requested version \(config.version); downgrades are not supported"])
            }

            // Handle database creation or upgrade. Like Android's
            // SQLiteOpenHelper, statements and the version bump run in one
            // transaction so a failure never leaves a half-created schema.
            // Foreign keys are still off here (enabled below), so table
            // rebuilds during a migration can't trigger ON DELETE actions.
            let statements: [String]?
            if currentVersion == 0 {
                statements = config.onCreate ?? []
            } else if currentVersion < config.version {
                statements = config.upgradeStatements(from: currentVersion)
            } else {
                statements = nil
            }
            if let statements = statements {
                do {
                    try executeInternal(db: database, sql: "PRAGMA foreign_keys=OFF")
                    try executeInternal(db: database, sql: "BEGIN IMMEDIATE")
                    for sql in statements {
                        try executeInternal(db: database, sql: sql)
                    }
                    let violations = try countRows(db: database, sql: "PRAGMA foreign_key_check")
                    if violations > 0 {
                        throw NSError(domain: "NativeSqlite", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Migration to version \(config.version) left \(violations) foreign key violation(s)"])
                    }
                    try setDatabaseVersion(db: database, version: config.version)
                    try executeInternal(db: database, sql: "COMMIT")
                } catch {
                    try? executeInternal(db: database, sql: "ROLLBACK")
                    sqlite3_close(database)
                    throw error
                }
            }

            if config.enableForeignKeys {
                do {
                    try executeInternal(db: database, sql: "PRAGMA foreign_keys=ON")
                } catch {
                    sqlite3_close(database)
                    throw error
                }
            }

            databases[config.name] = database
            databaseVersions[config.name] = config.version

            return path
        }
    }

    /**
     * Gets an open database instance.
     * Throws an error if the database is not open.
     *
     * This is useful for native code that needs direct database access.
     */
    public func getDatabase(name: String) throws -> OpaquePointer {
        return try queue.sync {
            guard let db = databases[name] else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database '\(name)' is not open"])
            }
            return db
        }
    }

    /**
     * Checks if a database is currently open.
     */
    public func isDatabaseOpen(name: String) -> Bool {
        return queue.sync {
            return databases[name] != nil
        }
    }

    /**
     * Closes a database.
     */
    public func closeDatabase(name: String) throws {
        queue.sync(flags: .barrier) {
            closeDatabaseLocked(name: name)
        }
    }

    /// Must be called while holding the queue barrier. `queue.sync` is not
    /// re-entrant, so callers already on the queue must not use
    /// `closeDatabase(name:)`.
    private func closeDatabaseLocked(name: String) {
        if let db = databases[name] {
            sqlite3_close(db)
            databases.removeValue(forKey: name)
            databaseVersions.removeValue(forKey: name)
        }
    }

    /**
     * Closes all open databases.
     */
    public func closeAll() {
        queue.sync(flags: .barrier) {
            for (_, db) in databases {
                sqlite3_close(db)
            }
            databases.removeAll()
            databaseVersions.removeAll()
        }
    }

    /**
     * Executes a raw SQL statement (INSERT, UPDATE, DELETE, etc.)
     *
     * - Returns: Number of rows affected
     */
    public func execute(name: String, sql: String, arguments: [Any?]? = nil) throws -> Int {
        let db = try getDatabase(name: name)
        return try queue.sync(flags: .barrier) {
            try executeInternal(db: db, sql: sql, arguments: arguments)
            return Int(sqlite3_changes(db))
        }
    }

    /**
     * Executes a SELECT query and returns the results.
     *
     * - Returns: A dictionary with "columns" and "rows" keys
     */
    public func query(name: String, sql: String, arguments: [Any?]? = nil) throws -> [String: Any] {
        let db = try getDatabase(name: name)
        return try queue.sync {
            var statement: OpaquePointer?

            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to prepare statement: \(String(cString: sqlite3_errmsg(db)))"])
            }

            defer {
                sqlite3_finalize(statement)
            }

            // Bind arguments
            if let args = arguments {
                try bindArguments(statement: statement!, arguments: args)
            }

            // Get column names
            let columnCount = sqlite3_column_count(statement)
            var columns: [String] = []
            for i in 0..<columnCount {
                if let name = sqlite3_column_name(statement, i) {
                    columns.append(String(cString: name))
                }
            }

            // Fetch rows
            var rows: [[Any?]] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [Any?] = []
                for i in 0..<columnCount {
                    row.append(getColumnValue(statement: statement!, index: i))
                }
                rows.append(row)
            }

            return [
                "columns": columns,
                "rows": rows
            ]
        }
    }

    /**
     * Inserts a row into a table.
     *
     * - Returns: The row ID of the newly inserted row
     */
    public func insert(name: String, table: String, values: [String: Any?]) throws -> Int64 {
        let db = try getDatabase(name: name)
        return try queue.sync(flags: .barrier) {
            let columns = values.keys.joined(separator: ", ")
            let placeholders = values.keys.map { _ in "?" }.joined(separator: ", ")
            let sql = "INSERT INTO \(table) (\(columns)) VALUES (\(placeholders))"

            try executeInternal(db: db, sql: sql, arguments: Array(values.values))
            return sqlite3_last_insert_rowid(db)
        }
    }

    /**
     * Updates rows in a table.
     *
     * - Returns: The number of rows affected
     */
    public func update(name: String, table: String, values: [String: Any?],
                      whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Int {
        let db = try getDatabase(name: name)
        return try queue.sync(flags: .barrier) {
            let setClause = values.keys.map { "\($0) = ?" }.joined(separator: ", ")
            var sql = "UPDATE \(table) SET \(setClause)"

            var arguments = Array(values.values)

            if let whereClause = whereClause {
                sql += " WHERE \(whereClause)"
                if let whereArgs = whereArgs {
                    arguments.append(contentsOf: whereArgs)
                }
            }

            try executeInternal(db: db, sql: sql, arguments: arguments)
            return Int(sqlite3_changes(db))
        }
    }

    /**
     * Deletes rows from a table.
     *
     * - Returns: The number of rows deleted
     */
    public func delete(name: String, table: String, whereClause: String? = nil,
                      whereArgs: [Any?]? = nil) throws -> Int {
        let db = try getDatabase(name: name)
        return try queue.sync(flags: .barrier) {
            var sql = "DELETE FROM \(table)"

            if let whereClause = whereClause {
                sql += " WHERE \(whereClause)"
            }

            try executeInternal(db: db, sql: sql, arguments: whereArgs)
            return Int(sqlite3_changes(db))
        }
    }

    /**
     * Executes multiple SQL statements in a transaction.
     *
     * - Returns: true if the transaction was successful
     */
    public func transaction(name: String, statements: [String]) throws -> Bool {
        let db = try getDatabase(name: name)
        return try queue.sync(flags: .barrier) {
            try executeInternal(db: db, sql: "BEGIN TRANSACTION")

            do {
                for sql in statements {
                    try executeInternal(db: db, sql: sql)
                }
                try executeInternal(db: db, sql: "COMMIT")
                return true
            } catch {
                try? executeInternal(db: db, sql: "ROLLBACK")
                throw error
            }
        }
    }

    /**
     * Gets the absolute path to a database file.
     *
     * Databases are stored in Library/Application Support, which is:
     * - Not exposed via iTunes File Sharing
     * - Excluded from user-visible Documents
     * - Backed up to iCloud only when the app opts in
     *
     * The name is sanitised to alphanumerics, underscores, and hyphens so
     * a crafted name cannot escape the application sandbox via path traversal.
     */
    public func getDatabasePath(name: String) -> String {
        // Sanitise: keep only alphanumerics, underscores, and hyphens.
        let safeName = name.unicodeScalars.filter {
            CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-")).contains($0)
        }.map(Character.init).reduce("") { $0 + String($1) }

        let appSupportDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NativeSqlite", isDirectory: true)

        // Create the directory if it doesn't exist yet.
        try? FileManager.default.createDirectory(
            at: appSupportDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        return appSupportDir.appendingPathComponent("\(safeName).db").path
    }

    /**
     * Deletes a database file.
     */
    public func deleteDatabase(name: String) throws {
        try queue.sync(flags: .barrier) {
            closeDatabaseLocked(name: name)
            let path = getDatabasePath(name: name)
            // Remove WAL/shared-memory files too; a stale -wal file would be
            // replayed into a new database created under the same name.
            for file in [path, path + "-wal", path + "-shm"]
            where FileManager.default.fileExists(atPath: file) {
                try FileManager.default.removeItem(atPath: file)
            }
        }
    }

    // MARK: - Private Helper Methods

    private func executeInternal(db: OpaquePointer, sql: String, arguments: [Any?]? = nil) throws {
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "NativeSqlite", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to prepare statement: \(String(cString: sqlite3_errmsg(db)))"])
        }

        defer {
            sqlite3_finalize(statement)
        }

        if let args = arguments {
            try bindArguments(statement: statement!, arguments: args)
        }

        // Statements such as `PRAGMA journal_mode=WAL` return a row; step
        // through any rows so they execute fully instead of failing.
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW {
            result = sqlite3_step(statement)
        }
        guard result == SQLITE_DONE else {
            throw NSError(domain: "NativeSqlite", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to execute statement: \(String(cString: sqlite3_errmsg(db)))"])
        }
    }

    private func bindArguments(statement: OpaquePointer, arguments: [Any?]) throws {
        // SQLITE_TRANSIENT (-1) tells SQLite to copy the value immediately so
        // we don't need to keep the Swift string alive for the statement's lifetime.
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        for (index, argument) in arguments.enumerated() {
            let bindIndex = Int32(index + 1)
            let result: Int32

            switch Self.unwrap(argument) {
            case nil:
                result = sqlite3_bind_null(statement, bindIndex)
            case let value as String:
                result = sqlite3_bind_text(statement, bindIndex, (value as NSString).utf8String, -1, SQLITE_TRANSIENT)
            case let number as NSNumber:
                // Swift Bool/Int/Int64/Double and Flutter's NSNumbers all land
                // here; bind by the number's real type so 1.0 stays REAL and
                // true stays INTEGER 1.
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    result = sqlite3_bind_int64(statement, bindIndex, number.boolValue ? 1 : 0)
                } else if CFNumberIsFloatType(number) {
                    result = sqlite3_bind_double(statement, bindIndex, number.doubleValue)
                } else {
                    result = sqlite3_bind_int64(statement, bindIndex, number.int64Value)
                }
            case let value as Data:
                result = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, bindIndex, bytes.baseAddress, Int32(value.count), SQLITE_TRANSIENT)
                }
            case let value?:
                // Never store a description of an unsupported value silently.
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Unsupported argument type \(type(of: value)) at index \(index)"])
            }

            guard result == SQLITE_OK else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to bind argument \(index): \(String(cString: sqlite3_errstr(result)))"])
            }
        }
    }

    /// Flattens nested optionals (e.g. `Any?` holding `String?`) and maps
    /// NSNull to nil.
    private static func unwrap(_ value: Any?) -> Any? {
        guard let value = value, !(value is NSNull) else { return nil }
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return unwrap(mirror.children.first?.value)
        }
        return value
    }

    private func getColumnValue(statement: OpaquePointer, index: Int32) -> Any? {
        let type = sqlite3_column_type(statement, index)

        switch type {
        case SQLITE_NULL:
            return nil
        case SQLITE_INTEGER:
            return sqlite3_column_int64(statement, index)
        case SQLITE_FLOAT:
            return sqlite3_column_double(statement, index)
        case SQLITE_TEXT:
            if let cString = sqlite3_column_text(statement, index) {
                return String(cString: cString)
            }
            return nil
        case SQLITE_BLOB:
            if let blob = sqlite3_column_blob(statement, index) {
                let size = sqlite3_column_bytes(statement, index)
                return Data(bytes: blob, count: Int(size))
            }
            return nil
        default:
            return nil
        }
    }

    private func getDatabaseVersion(db: OpaquePointer) throws -> Int {
        var statement: OpaquePointer?
        let sql = "PRAGMA user_version"

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "NativeSqlite", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to get database version"])
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }

        return Int(sqlite3_column_int(statement, 0))
    }

    private func countRows(db: OpaquePointer, sql: String) throws -> Int {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "NativeSqlite", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to prepare statement: \(String(cString: sqlite3_errmsg(db)))"])
        }
        defer { sqlite3_finalize(statement) }
        var count = 0
        while sqlite3_step(statement) == SQLITE_ROW {
            count += 1
        }
        return count
    }

    private func setDatabaseVersion(db: OpaquePointer, version: Int) throws {
        let sql = "PRAGMA user_version = \(version)"
        try executeInternal(db: db, sql: sql)
    }
}
