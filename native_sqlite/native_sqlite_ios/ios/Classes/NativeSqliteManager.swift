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
            if databases[config.name] != nil {
                try closeDatabase(name: config.name)
            }

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

            // Enable foreign keys if requested
            if config.enableForeignKeys {
                try executeInternal(db: database, sql: "PRAGMA foreign_keys=ON")
            }

            // Get current version
            let currentVersion = try getDatabaseVersion(db: database)

            // Handle database creation or upgrade
            if currentVersion == 0 {
                // New database - run onCreate
                if let onCreate = config.onCreate {
                    for sql in onCreate {
                        try executeInternal(db: database, sql: sql)
                    }
                }
                try setDatabaseVersion(db: database, version: config.version)
            } else if currentVersion < config.version {
                // Upgrade needed
                if let onUpgrade = config.onUpgrade {
                    for sql in onUpgrade {
                        try executeInternal(db: database, sql: sql)
                    }
                }
                try setDatabaseVersion(db: database, version: config.version)
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
        try queue.sync(flags: .barrier) {
            if let db = databases[name] {
                sqlite3_close(db)
                databases.removeValue(forKey: name)
                databaseVersions.removeValue(forKey: name)
            }
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
        return try queue.sync {
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
        return try queue.sync {
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
        return try queue.sync {
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
        return try queue.sync {
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
        return try queue.sync {
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
     */
    public func getDatabasePath(name: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return "\(documentsDirectory)/\(name).db"
    }

    /**
     * Deletes a database file.
     */
    public func deleteDatabase(name: String) throws {
        try queue.sync(flags: .barrier) {
            try? closeDatabase(name: name)
            let path = getDatabasePath(name: name)
            try FileManager.default.removeItem(atPath: path)
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

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "NativeSqlite", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to execute statement: \(String(cString: sqlite3_errmsg(db)))"])
        }
    }

    private func bindArguments(statement: OpaquePointer, arguments: [Any?]) throws {
        for (index, arg) in arguments.enumerated() {
            let bindIndex = Int32(index + 1)

            if arg == nil {
                sqlite3_bind_null(statement, bindIndex)
            } else if let value = arg as? String {
                sqlite3_bind_text(statement, bindIndex, (value as NSString).utf8String, -1, nil)
            } else if let value = arg as? Int {
                sqlite3_bind_int64(statement, bindIndex, Int64(value))
            } else if let value = arg as? Int64 {
                sqlite3_bind_int64(statement, bindIndex, value)
            } else if let value = arg as? Double {
                sqlite3_bind_double(statement, bindIndex, value)
            } else if let value = arg as? Bool {
                sqlite3_bind_int(statement, bindIndex, value ? 1 : 0)
            } else if let value = arg as? Data {
                sqlite3_bind_blob(statement, bindIndex, (value as NSData).bytes, Int32(value.count), nil)
            } else {
                sqlite3_bind_text(statement, bindIndex, (String(describing: arg) as NSString).utf8String, -1, nil)
            }
        }
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

    private func setDatabaseVersion(db: OpaquePointer, version: Int) throws {
        let sql = "PRAGMA user_version = \(version)"
        try executeInternal(db: db, sql: sql)
    }
}
