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
 * try NativeSqliteManager.shared.withConnection(name: "location_db") { db in
 *     // Use the SQLite handle only inside this closure. The manager keeps it
 *     // alive and prevents concurrent close/delete operations.
 * }
 * ```
 */
public class NativeSqliteManager {
    /// Quotes a SQLite identifier and escapes embedded double quotes.
    public static func quoteIdentifier(_ identifier: String) -> String {
        "\"\(identifier.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    public static let shared = NativeSqliteManager()

    private final class ManagedConnection {
        let config: DatabaseConfig
        let queue: DispatchQueue
        var database: OpaquePointer?
        var referenceCount = 1
        var activeTransactionId: String?

        init(database: OpaquePointer, config: DatabaseConfig) {
            self.database = database
            self.config = config
            self.queue = DispatchQueue(label: "dev.nesmin.native_sqlite.\(config.name)")
        }
    }

    private var connections: [String: ManagedConnection] = [:]
    private let stateQueue = DispatchQueue(
        label: "dev.nesmin.native_sqlite.state",
        attributes: .concurrent
    )

    private init() {}

    private func assertNotMainThread() {
        assert(
            !Thread.isMainThread,
            "NativeSqliteManager performs synchronous SQLite work; call it from a background thread"
        )
    }

    /**
     * Opens a database with the given configuration.
     *
     * - Returns: The absolute path to the database file
     */
    public func openDatabase(config: DatabaseConfig) throws -> String {
        assertNotMainThread()
        return try stateQueue.sync(flags: .barrier) {
            try Self.validate(config: config)
            let path = try getDatabasePath(
                name: config.name,
                directory: config.directory,
                iosAppGroup: config.iosAppGroup
            )
            if let existing = connections[config.name] {
                guard Self.configsMatch(existing.config, config) else {
                    throw NSError(
                        domain: "NativeSqlite",
                        code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey:
                            "Database '\(config.name)' is already open with a different configuration"]
                    )
                }
                existing.referenceCount += 1
                return path
            }

            var db: OpaquePointer?

            let flags = config.readOnly
                ? SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
                : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
            guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
                let message = db.map { String(cString: sqlite3_errmsg($0)) }
                    ?? "Database handle is nil"
                if let db = db { sqlite3_close_v2(db) }
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to open database: \(message)"])
            }

            guard let database = db else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database handle is nil"])
            }

            // Keep the precise constraint reason (UNIQUE, NOT NULL, FK, ...)
            // available for the public NativeSqliteException contract.
            sqlite3_extended_result_codes(database, 1)

            let busyResult = sqlite3_busy_timeout(database, Int32(config.busyTimeout))
            guard busyResult == SQLITE_OK else {
                let message = String(cString: sqlite3_errmsg(database))
                sqlite3_close_v2(database)
                throw NSError(domain: "NativeSqlite", code: Int(busyResult),
                            userInfo: [NSLocalizedDescriptionKey: "Failed to set busy timeout: \(message)"])
            }

            // Apply the requested journal mode even when reopening an
            // existing database that was previously configured differently.
            if !config.readOnly {
                do {
                    try executeInternal(
                        db: database,
                        sql: config.enableWAL
                            ? "PRAGMA journal_mode=WAL"
                            : "PRAGMA journal_mode=DELETE"
                    )
                } catch {
                    sqlite3_close_v2(database)
                    throw error
                }
            }

            // Get current version
            let currentVersion = try getDatabaseVersion(db: database)
            if config.readOnly && currentVersion != config.version {
                sqlite3_close_v2(database)
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Read-only database is at version \(currentVersion), expected \(config.version)"])
            } else if currentVersion > config.version {
                sqlite3_close_v2(database)
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database is at version \(currentVersion), newer than the requested version \(config.version); downgrades are not supported"])
            }

            // Handle database creation or upgrade. Like Android's
            // SQLiteOpenHelper, statements and the version bump run in one
            // transaction so a failure never leaves a half-created schema.
            // Foreign keys are still off here (enabled below), so table
            // rebuilds during a migration can't trigger ON DELETE actions.
            let statements: [String]?
            if config.readOnly {
                statements = nil
            } else if currentVersion == 0 {
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
                    sqlite3_close_v2(database)
                    throw error
                }
            }

            if config.enableForeignKeys {
                do {
                    try executeInternal(db: database, sql: "PRAGMA foreign_keys=ON")
                } catch {
                    sqlite3_close_v2(database)
                    throw error
                }
            }
            do {
                for sql in config.onConfigure ?? [] {
                    try executeInternal(db: database, sql: sql)
                }
            } catch {
                sqlite3_close_v2(database)
                throw error
            }

            connections[config.name] = ManagedConnection(
                database: database,
                config: config
            )

            return path
        }
    }

    /**
     * Runs native work while the named connection is guaranteed to stay open.
     * The handle must not escape the closure.
     */
    public func withConnection<T>(
        name: String,
        transactionId: String? = nil,
        _ operation: (OpaquePointer) throws -> T
    ) throws -> T {
        assertNotMainThread()
        let connection = try stateQueue.sync {
            guard let connection = connections[name] else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database '\(name)' is not open"])
            }
            return connection
        }
        return try connection.queue.sync {
            guard let db = connection.database else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database '\(name)' is not open"])
            }
            guard connection.activeTransactionId == transactionId else {
                let message = transactionId == nil
                    ? "Database '\(name)' has an active transaction"
                    : "Transaction '\(transactionId!)' is not active for database '\(name)'"
                throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                            userInfo: [NSLocalizedDescriptionKey: message])
            }
            return try operation(db)
        }
    }

    /**
     * Checks if a database is currently open.
     */
    public func isDatabaseOpen(name: String) -> Bool {
        assertNotMainThread()
        return stateQueue.sync {
            return connections[name] != nil
        }
    }

    /**
     * Closes a database.
     */
    public func closeDatabase(name: String) throws {
        assertNotMainThread()
        stateQueue.sync(flags: .barrier) {
            closeDatabaseLocked(name: name)
        }
    }

    /// Must be called while holding the state queue barrier. Callers already
    /// on that queue must not use
    /// `closeDatabase(name:)`.
    private func closeDatabaseLocked(name: String) {
        guard let connection = connections[name] else { return }
        if connection.referenceCount > 1 {
            connection.referenceCount -= 1
            return
        }
        forceCloseDatabaseLocked(name: name)
    }

    private func forceCloseDatabaseLocked(name: String) {
        guard let connection = connections.removeValue(forKey: name) else { return }
        connection.queue.sync {
            if let db = connection.database {
                sqlite3_close_v2(db)
                connection.database = nil
            }
        }
    }

    /**
     * Closes all open databases.
     */
    public func closeAll() {
        assertNotMainThread()
        stateQueue.sync(flags: .barrier) {
            for (_, connection) in connections {
                connection.queue.sync {
                    if let db = connection.database {
                        sqlite3_close_v2(db)
                        connection.database = nil
                    }
                }
            }
            connections.removeAll()
        }
    }

    /**
     * Executes a raw SQL statement (INSERT, UPDATE, DELETE, etc.)
     *
     * - Returns: Number of rows affected
     */
    public func execute(name: String, sql: String, arguments: [Any?]? = nil,
                        transactionId: String? = nil) throws -> Int {
        return try withConnection(name: name, transactionId: transactionId) { db in
            let changesBefore = sqlite3_total_changes(db)
            try executeInternal(db: db, sql: sql, arguments: arguments)
            return Int(sqlite3_total_changes(db) - changesBefore)
        }
    }

    /** Executes a raw INSERT and returns its SQLite row ID. */
    public func executeInsert(name: String, sql: String,
                              arguments: [Any?]? = nil,
                              transactionId: String? = nil) throws -> Int64 {
        return try withConnection(name: name, transactionId: transactionId) { db in
            try executeInternal(db: db, sql: sql, arguments: arguments)
            return sqlite3_last_insert_rowid(db)
        }
    }

    /**
     * Executes a SELECT query and returns the results.
     *
     * - Returns: A dictionary with "columns" and "rows" keys
     */
    public func query(name: String, sql: String, arguments: [Any?]? = nil,
                      transactionId: String? = nil) throws -> [String: Any] {
        return try withConnection(name: name, transactionId: transactionId) { db in
            let statement = try prepareStatement(db: db, sql: sql)

            defer {
                sqlite3_finalize(statement)
            }

            // Bind arguments
            if let args = arguments {
                try bindArguments(statement: statement, arguments: args)
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
            var stepResult = sqlite3_step(statement)
            while stepResult == SQLITE_ROW {
                var row: [Any?] = []
                for i in 0..<columnCount {
                    row.append(getColumnValue(statement: statement, index: i))
                }
                rows.append(row)
                stepResult = sqlite3_step(statement)
            }
            guard stepResult == SQLITE_DONE else {
                throw sqliteError(
                    db: db,
                    code: stepResult,
                    message: "Failed while reading query results: \(String(cString: sqlite3_errmsg(db)))",
                    sql: sql
                )
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
    public func insert(name: String, table: String, values: [String: Any?],
                       transactionId: String? = nil) throws -> Int64 {
        return try withConnection(name: name, transactionId: transactionId) { db in
            let entries = Array(values)
            let columns = entries
                .map { Self.quoteIdentifier($0.key) }
                .joined(separator: ", ")
            let placeholders = entries.map { _ in "?" }.joined(separator: ", ")
            let sql = "INSERT INTO \(Self.quoteIdentifier(table)) (\(columns)) VALUES (\(placeholders))"

            try executeInternal(db: db, sql: sql, arguments: entries.map(\.value))
            return sqlite3_last_insert_rowid(db)
        }
    }

    /**
     * Updates rows in a table.
     *
     * - Returns: The number of rows affected
     */
    public func update(name: String, table: String, values: [String: Any?],
                      whereClause: String? = nil, whereArgs: [Any?]? = nil,
                      transactionId: String? = nil) throws -> Int {
        guard whereArgs?.isEmpty != false || !(whereClause?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "whereArgs requires a non-empty where clause"])
        }
        return try withConnection(name: name, transactionId: transactionId) { db in
            let entries = Array(values)
            let setClause = entries
                .map { "\(Self.quoteIdentifier($0.key)) = ?" }
                .joined(separator: ", ")
            var sql = "UPDATE \(Self.quoteIdentifier(table)) SET \(setClause)"

            var arguments = entries.map(\.value)

            let normalizedWhere = whereClause?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let normalizedWhere, !normalizedWhere.isEmpty {
                sql += " WHERE \(normalizedWhere)"
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
                      whereArgs: [Any?]? = nil,
                      transactionId: String? = nil) throws -> Int {
        guard whereArgs?.isEmpty != false || !(whereClause?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "whereArgs requires a non-empty where clause"])
        }
        return try withConnection(name: name, transactionId: transactionId) { db in
            var sql = "DELETE FROM \(Self.quoteIdentifier(table))"

            let normalizedWhere = whereClause?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let normalizedWhere, !normalizedWhere.isEmpty {
                sql += " WHERE \(normalizedWhere)"
            }

            try executeInternal(db: db, sql: sql, arguments: whereArgs)
            return Int(sqlite3_changes(db))
        }
    }

    /**
     * Executes multiple SQL statements in a transaction.
     *
     * Throws and rolls back if any statement fails.
     */
    public func transaction(name: String, statements: [String]) throws {
        try withConnection(name: name) { db in
            try executeInternal(db: db, sql: "BEGIN TRANSACTION")

            do {
                for sql in statements {
                    try executeInternal(db: db, sql: sql)
                }
                try executeInternal(db: db, sql: "COMMIT")
            } catch {
                try? executeInternal(db: db, sql: "ROLLBACK")
                throw error
            }
        }
    }

    /// Runs native database work atomically on the calling background thread.
    public func transaction<T>(
        name: String,
        _ block: (NativeSqliteTransaction) throws -> T
    ) throws -> T {
        let transactionId = "native-\(UUID().uuidString)"
        try beginTransaction(name: name, transactionId: transactionId)
        let transaction = NativeSqliteTransaction(
            manager: self,
            databaseName: name,
            transactionId: transactionId
        )
        do {
            let value = try block(transaction)
            transaction.finish()
            try endTransaction(name: name, transactionId: transactionId, commit: true)
            return value
        } catch {
            transaction.finish()
            try? endTransaction(name: name, transactionId: transactionId, commit: false)
            throw error
        }
    }

    public func beginTransaction(name: String, transactionId: String) throws {
        let connection = try connection(named: name)
        try connection.queue.sync {
            guard connection.activeTransactionId == nil,
                  let db = connection.database else {
                throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                            userInfo: [NSLocalizedDescriptionKey: "Database '\(name)' already has an active transaction"])
            }
            try executeInternal(db: db, sql: "BEGIN TRANSACTION")
            connection.activeTransactionId = transactionId
        }
    }

    public func endTransaction(name: String, transactionId: String,
                               commit: Bool) throws {
        let connection = try connection(named: name)
        try connection.queue.sync {
            guard connection.activeTransactionId == transactionId,
                  let db = connection.database else {
                throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                            userInfo: [NSLocalizedDescriptionKey: "Transaction '\(transactionId)' is not active"])
            }
            defer { connection.activeTransactionId = nil }
            do {
                try executeInternal(db: db, sql: commit ? "COMMIT" : "ROLLBACK")
            } catch {
                if commit { try? executeInternal(db: db, sql: "ROLLBACK") }
                throw error
            }
        }
    }

    public func batch(name: String, operations: [[String: Any]]) throws -> [Any] {
        let transactionId = "batch-\(UUID().uuidString)"
        try beginTransaction(name: name, transactionId: transactionId)
        do {
            let results: [Any] = try operations.map { operation in
                let type = operation["type"] as? String
                switch type {
                case "execute":
                    return try execute(
                        name: name,
                        sql: operation["sql"] as! String,
                        arguments: operation["arguments"] as? [Any?],
                        transactionId: transactionId
                    )
                case "query":
                    return try query(
                        name: name,
                        sql: operation["sql"] as! String,
                        arguments: operation["arguments"] as? [Any?],
                        transactionId: transactionId
                    )
                case "insert":
                    return try insert(
                        name: name,
                        table: operation["table"] as! String,
                        values: operation["values"] as! [String: Any?],
                        transactionId: transactionId
                    )
                case "update":
                    return try update(
                        name: name,
                        table: operation["table"] as! String,
                        values: operation["values"] as! [String: Any?],
                        whereClause: operation["where"] as? String,
                        whereArgs: operation["whereArgs"] as? [Any?],
                        transactionId: transactionId
                    )
                case "delete":
                    return try delete(
                        name: name,
                        table: operation["table"] as! String,
                        whereClause: operation["where"] as? String,
                        whereArgs: operation["whereArgs"] as? [Any?],
                        transactionId: transactionId
                    )
                default:
                    throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                                userInfo: [NSLocalizedDescriptionKey: "Unknown batch operation: \(type ?? "nil")"])
                }
            }
            try endTransaction(name: name, transactionId: transactionId, commit: true)
            return results
        } catch {
            try? endTransaction(name: name, transactionId: transactionId, commit: false)
            throw error
        }
    }

    private func connection(named name: String) throws -> ManagedConnection {
        try stateQueue.sync {
            guard let connection = connections[name] else {
                throw NSError(domain: "NativeSqlite", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Database '\(name)' is not open"])
            }
            return connection
        }
    }

    /**
     * Gets the absolute path to a database file.
     *
     * Databases are stored in Library/Application Support, which is:
     * - Not exposed via iTunes File Sharing
     * - Excluded from user-visible Documents
     * - Included in device backups by default
     *
     * The name is sanitised to alphanumerics, underscores, and hyphens so
     * a crafted name cannot escape the application sandbox via path traversal.
     */
    public func getDatabasePath(
        name: String,
        directory: String? = nil,
        iosAppGroup: String? = nil
    ) throws -> String {
        assertNotMainThread()
        try Self.validateLocation(
            name: name,
            directory: directory,
            iosAppGroup: iosAppGroup
        )

        let appSupportDir: URL
        if let directory {
            appSupportDir = URL(fileURLWithPath: directory, isDirectory: true)
        } else if let iosAppGroup {
            guard let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: iosAppGroup
            ) else {
                throw NSError(domain: "NativeSqlite", code: Int(SQLITE_CANTOPEN),
                            userInfo: [NSLocalizedDescriptionKey: "App Group '\(iosAppGroup)' is unavailable; add it to the app entitlements"])
            }
            appSupportDir = container.appendingPathComponent("NativeSqlite", isDirectory: true)
        } else {
            appSupportDir = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("NativeSqlite", isDirectory: true)
        }

        // Create the directory if it doesn't exist yet.
        try FileManager.default.createDirectory(
            at: appSupportDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        return appSupportDir.appendingPathComponent("\(name).db").path
    }

    /// Returns whether a database file exists at the configured location.
    public func databaseExists(
        name: String,
        directory: String? = nil,
        iosAppGroup: String? = nil
    ) throws -> Bool {
        let path = try getDatabasePath(
            name: name,
            directory: directory,
            iosAppGroup: iosAppGroup
        )
        return FileManager.default.fileExists(atPath: path)
    }

    /// Writes a complete database file while no connection is open.
    public func importDatabase(
        name: String,
        data: Data,
        directory: String? = nil,
        iosAppGroup: String? = nil,
        overwrite: Bool = false
    ) throws {
        assertNotMainThread()
        try stateQueue.sync(flags: .barrier) {
            guard connections[name] == nil else {
                throw NSError(
                    domain: "NativeSqlite",
                    code: Int(SQLITE_BUSY),
                    userInfo: [NSLocalizedDescriptionKey: "Database '\(name)' is open"]
                )
            }
            let path = try getDatabasePath(
                name: name,
                directory: directory,
                iosAppGroup: iosAppGroup
            )
            if FileManager.default.fileExists(atPath: path), !overwrite {
                return
            }
            if overwrite {
                for file in [path + "-journal", path + "-wal", path + "-shm"]
                where FileManager.default.fileExists(atPath: file) {
                    try FileManager.default.removeItem(atPath: file)
                }
            }
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }

    /**
     * Deletes a database file.
     */
    public func deleteDatabase(
        name: String,
        directory: String? = nil,
        iosAppGroup: String? = nil
    ) throws {
        assertNotMainThread()
        try stateQueue.sync(flags: .barrier) {
            forceCloseDatabaseLocked(name: name)
            let path = try getDatabasePath(
                name: name,
                directory: directory,
                iosAppGroup: iosAppGroup
            )
            // Remove WAL/shared-memory files too; a stale -wal file would be
            // replayed into a new database created under the same name.
            for file in [path, path + "-journal", path + "-wal", path + "-shm"]
            where FileManager.default.fileExists(atPath: file) {
                try FileManager.default.removeItem(atPath: file)
            }
        }
    }

    // MARK: - Private Helper Methods

    private func executeInternal(db: OpaquePointer, sql: String, arguments: [Any?]? = nil) throws {
        let statement = try prepareStatement(db: db, sql: sql)

        defer {
            sqlite3_finalize(statement)
        }

        if let args = arguments {
            try bindArguments(statement: statement, arguments: args)
        }

        // Statements such as `PRAGMA journal_mode=WAL` return a row; step
        // through any rows so they execute fully instead of failing.
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW {
            result = sqlite3_step(statement)
        }
        guard result == SQLITE_DONE else {
            throw sqliteError(
                db: db,
                code: result,
                message: "Failed to execute statement: \(String(cString: sqlite3_errmsg(db)))",
                sql: sql
            )
        }
    }

    private func sqliteError(
        db: OpaquePointer,
        code: Int32,
        message: String,
        sql: String? = nil
    ) -> NSError {
        let reportedExtendedCode = sqlite3_extended_errcode(db)
        let extendedCode = reportedExtendedCode == SQLITE_OK ? code : reportedExtendedCode
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: message,
            "extendedCode": Int(extendedCode),
        ]
        if let sql = sql { userInfo["sql"] = sql }
        return NSError(
            domain: "NativeSqlite",
            code: Int(extendedCode & 0xff),
            userInfo: userInfo
        )
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
                result = value.utf8CString.withUnsafeBufferPointer { bytes in
                    sqlite3_bind_text(
                        statement,
                        bindIndex,
                        bytes.baseAddress,
                        Int32(bytes.count - 1),
                        SQLITE_TRANSIENT
                    )
                }
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
                result = value.isEmpty
                    ? sqlite3_bind_zeroblob(statement, bindIndex, 0)
                    : value.withUnsafeBytes { bytes in
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
            let size = Int(sqlite3_column_bytes(statement, index))
            guard let bytes = sqlite3_column_text(statement, index) else {
                return size == 0 ? "" : nil
            }
            return String(
                data: Data(bytes: bytes, count: size),
                encoding: .utf8
            )
        case SQLITE_BLOB:
            let size = Int(sqlite3_column_bytes(statement, index))
            guard size > 0 else { return Data() }
            guard let blob = sqlite3_column_blob(statement, index) else { return nil }
            return Data(bytes: blob, count: size)
        default:
            return nil
        }
    }

    private func getDatabaseVersion(db: OpaquePointer) throws -> Int {
        let sql = "PRAGMA user_version"
        let statement = try prepareStatement(db: db, sql: sql)

        defer {
            sqlite3_finalize(statement)
        }

        let rowResult = sqlite3_step(statement)
        guard rowResult == SQLITE_ROW else {
            throw NSError(domain: "NativeSqlite", code: Int(rowResult),
                        userInfo: [NSLocalizedDescriptionKey: "Failed to read database version: \(String(cString: sqlite3_errmsg(db)))"])
        }

        let version = Int(sqlite3_column_int(statement, 0))
        let finalResult = sqlite3_step(statement)
        guard finalResult == SQLITE_DONE else {
            throw NSError(domain: "NativeSqlite", code: Int(finalResult),
                        userInfo: [NSLocalizedDescriptionKey: "Failed to finish reading database version: \(String(cString: sqlite3_errmsg(db)))"])
        }
        return version
    }

    private func countRows(db: OpaquePointer, sql: String) throws -> Int {
        let statement = try prepareStatement(db: db, sql: sql)
        defer { sqlite3_finalize(statement) }
        var count = 0
        var stepResult = sqlite3_step(statement)
        while stepResult == SQLITE_ROW {
            count += 1
            stepResult = sqlite3_step(statement)
        }
        guard stepResult == SQLITE_DONE else {
            throw NSError(domain: "NativeSqlite", code: Int(stepResult),
                        userInfo: [NSLocalizedDescriptionKey: "Failed while reading rows: \(String(cString: sqlite3_errmsg(db)))"])
        }
        return count
    }

    private func prepareStatement(db: OpaquePointer, sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        var result = Int32(SQLITE_OK)
        var trailingResult = Int32(SQLITE_OK)
        var hasTrailingStatement = false

        sql.withCString { source in
            var tail: UnsafePointer<CChar>?
            result = sqlite3_prepare_v2(db, source, -1, &statement, &tail)
            guard result == SQLITE_OK else { return }

            // Ask SQLite to parse the tail too, so whitespace, comments and
            // empty semicolons remain valid while a second statement does not.
            while let remainder = tail, remainder.pointee != 0 {
                var trailingStatement: OpaquePointer?
                var nextTail: UnsafePointer<CChar>?
                trailingResult = sqlite3_prepare_v2(
                    db,
                    remainder,
                    -1,
                    &trailingStatement,
                    &nextTail
                )
                if let trailingStatement = trailingStatement {
                    sqlite3_finalize(trailingStatement)
                    hasTrailingStatement = true
                    break
                }
                guard trailingResult == SQLITE_OK, nextTail != remainder else {
                    break
                }
                tail = nextTail
            }
        }
        guard result == SQLITE_OK else {
            throw sqliteError(
                db: db,
                code: result,
                message: "Failed to prepare statement: \(String(cString: sqlite3_errmsg(db)))",
                sql: sql
            )
        }
        guard trailingResult == SQLITE_OK else {
            sqlite3_finalize(statement)
            throw sqliteError(
                db: db,
                code: trailingResult,
                message: "Failed to prepare trailing SQL: \(String(cString: sqlite3_errmsg(db)))",
                sql: sql
            )
        }
        guard !hasTrailingStatement else {
            sqlite3_finalize(statement)
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "Exactly one SQL statement is allowed per string"])
        }
        guard let statement else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "SQL contains no executable statement"])
        }
        return statement
    }

    private func setDatabaseVersion(db: OpaquePointer, version: Int) throws {
        let sql = "PRAGMA user_version = \(version)"
        try executeInternal(db: db, sql: sql)
    }

    private static func configsMatch(_ left: DatabaseConfig, _ right: DatabaseConfig) -> Bool {
        left.name == right.name
            && left.version == right.version
            && sqlListsMatch(left.onCreate, right.onCreate)
            && sqlListsMatch(left.onUpgrade, right.onUpgrade)
            && sqlListsMatch(left.onConfigure, right.onConfigure)
            && migrationMapsMatch(left.migrations, right.migrations)
            && left.enableWAL == right.enableWAL
            && left.enableForeignKeys == right.enableForeignKeys
            && left.busyTimeout == right.busyTimeout
            && left.readOnly == right.readOnly
            && left.directory == right.directory
            && left.iosAppGroup == right.iosAppGroup
    }

    private static func validate(config: DatabaseConfig) throws {
        guard config.version >= 1 else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "Database version must be at least 1"])
        }
        guard config.busyTimeout >= 0 && config.busyTimeout <= Int(Int32.max) else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "Busy timeout must fit a non-negative 32-bit integer"])
        }
        try validateLocation(
            name: config.name,
            directory: config.directory,
            iosAppGroup: config.iosAppGroup
        )
    }

    private static func validateLocation(
        name: String,
        directory: String?,
        iosAppGroup: String?
    ) throws {
        guard name.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "Database name must contain only ASCII letters, digits, underscores, and hyphens"])
        }
        guard directory == nil || directory!.hasPrefix("/") else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "Database directory must be an absolute path"])
        }
        guard directory == nil || iosAppGroup == nil else {
            throw NSError(domain: "NativeSqlite", code: Int(SQLITE_MISUSE),
                        userInfo: [NSLocalizedDescriptionKey: "directory and iosAppGroup are mutually exclusive"])
        }
    }

    private static func sqlListsMatch(_ left: [String]?, _ right: [String]?) -> Bool {
        switch (left, right) {
        case (nil, nil):
            return true
        case let (.some(left), .some(right)):
            guard left.count == right.count else { return false }
            return zip(left, right).allSatisfy { pair in
                sqlTokens(pair.0) == sqlTokens(pair.1)
            }
        default:
            return false
        }
    }

    private static func migrationMapsMatch(
        _ left: [Int: [String]]?,
        _ right: [Int: [String]]?
    ) -> Bool {
        switch (left, right) {
        case (nil, nil):
            return true
        case let (.some(left), .some(right)):
            guard Set(left.keys) == Set(right.keys) else { return false }
            return left.allSatisfy { version, statements in
                sqlListsMatch(statements, right[version])
            }
        default:
            return false
        }
    }

    /// Tokenizes SQL so formatting and comments don't make otherwise
    /// identical native/Dart configurations conflict.
    private static func sqlTokens(_ sql: String) -> String {
        let bytes = Array(sql.utf8)
        var tokens: [String] = []
        var index = 0

        func isWhitespace(_ byte: UInt8) -> Bool {
            byte == 9 || byte == 10 || byte == 11 || byte == 12 || byte == 13 || byte == 32
        }
        func isWord(_ byte: UInt8) -> Bool {
            (byte >= 48 && byte <= 57)
                || (byte >= 65 && byte <= 90)
                || (byte >= 97 && byte <= 122)
                || byte == 95 || byte == 36 || byte >= 128
        }
        func token(_ start: Int, _ end: Int) -> String {
            String(decoding: bytes[start..<end], as: UTF8.self)
        }

        while index < bytes.count {
            let byte = bytes[index]
            if isWhitespace(byte) {
                index += 1
            } else if byte == 45 && index + 1 < bytes.count && bytes[index + 1] == 45 {
                index += 2
                while index < bytes.count && bytes[index] != 10 && bytes[index] != 13 {
                    index += 1
                }
            } else if byte == 47 && index + 1 < bytes.count && bytes[index + 1] == 42 {
                index += 2
                while index + 1 < bytes.count && !(bytes[index] == 42 && bytes[index + 1] == 47) {
                    index += 1
                }
                index = min(index + 2, bytes.count)
            } else if byte == 39 || byte == 34 || byte == 96 {
                let start = index
                index += 1
                while index < bytes.count {
                    if bytes[index] == byte {
                        if index + 1 < bytes.count && bytes[index + 1] == byte {
                            index += 2
                        } else {
                            index += 1
                            break
                        }
                    } else {
                        index += 1
                    }
                }
                tokens.append(token(start, index))
            } else if byte == 91 {
                let start = index
                index += 1
                while index < bytes.count && bytes[index] != 93 { index += 1 }
                if index < bytes.count { index += 1 }
                tokens.append(token(start, index))
            } else if isWord(byte) {
                let start = index
                index += 1
                while index < bytes.count && isWord(bytes[index]) { index += 1 }
                tokens.append(token(start, index))
            } else {
                tokens.append(token(index, index + 1))
                index += 1
            }
        }
        return tokens.joined(separator: "\u{001f}")
    }
}

/// Database operations scoped to a native interactive transaction.
public final class NativeSqliteTransaction {
    private let manager: NativeSqliteManager
    private let databaseName: String
    private let transactionId: String
    private var active = true

    fileprivate init(
        manager: NativeSqliteManager,
        databaseName: String,
        transactionId: String
    ) {
        self.manager = manager
        self.databaseName = databaseName
        self.transactionId = transactionId
    }

    public func execute(sql: String, arguments: [Any?]? = nil) throws -> Int {
        try checkActive()
        return try manager.execute(
            name: databaseName,
            sql: sql,
            arguments: arguments,
            transactionId: transactionId
        )
    }

    public func query(sql: String, arguments: [Any?]? = nil) throws -> [String: Any] {
        try checkActive()
        return try manager.query(
            name: databaseName,
            sql: sql,
            arguments: arguments,
            transactionId: transactionId
        )
    }

    public func insert(table: String, values: [String: Any?]) throws -> Int64 {
        try checkActive()
        return try manager.insert(
            name: databaseName,
            table: table,
            values: values,
            transactionId: transactionId
        )
    }

    public func update(
        table: String,
        values: [String: Any?],
        whereClause: String? = nil,
        whereArgs: [Any?]? = nil
    ) throws -> Int {
        try checkActive()
        return try manager.update(
            name: databaseName,
            table: table,
            values: values,
            whereClause: whereClause,
            whereArgs: whereArgs,
            transactionId: transactionId
        )
    }

    public func delete(
        table: String,
        whereClause: String? = nil,
        whereArgs: [Any?]? = nil
    ) throws -> Int {
        try checkActive()
        return try manager.delete(
            name: databaseName,
            table: table,
            whereClause: whereClause,
            whereArgs: whereArgs,
            transactionId: transactionId
        )
    }

    fileprivate func finish() {
        active = false
    }

    private func checkActive() throws {
        guard active else {
            throw NSError(
                domain: "NativeSqlite",
                code: Int(SQLITE_MISUSE),
                userInfo: [NSLocalizedDescriptionKey: "This transaction has already completed"]
            )
        }
    }
}
