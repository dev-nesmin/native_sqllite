import Foundation

/**
 * Struct for Profile.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public struct Profile {
    public let id: Int?
    public let name: String
    public let email: String
    public let phoneNumber: String?
    public let settings: String?
    public let tags: String?
    public let address: Any?
    public let addresses: String?
    public let metadata: Any

    public init(
        id: Int? = nil,
        name: String,
        email: String,
        phoneNumber: String?,
        settings: String?,
        tags: String?,
        address: Any?,
        addresses: String?,
        metadata: Any
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.settings = settings
        self.tags = tags
        self.address = address
        self.addresses = addresses
        self.metadata = metadata
    }
}

/**
 * Helper class for Profile CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * let helper = ProfileHelper(databaseName: "example_app")
 * let id = try helper.insert(Profile(...))
 * let item = try helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In BGTaskScheduler or background isolate
 * let isolateId = Int64(pthread_self())
 * let helper = ProfileHelper.getInstance(databaseName: "example_app", isolateId: isolateId)
 * let users = try helper.findAll()
 * // When done, cleanup:
 * ProfileHelper.cleanupIsolate(isolateId: isolateId)
 * ```
 */
public class ProfileHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    // Track helper instances per isolate for thread safety
    private static var isolateInstances = [Int64: ProfileHelper]()
    private static let isolateQueue = DispatchQueue(label: "ProfileHelper.isolate")

    /**
     * Get or create helper instance for the given isolate.
     * Safe to call from different Dart isolates or native threads.
     *
     * - Parameters:
     *   - databaseName: Name of the database
     *   - isolateId: Unique identifier for the isolate/thread
     * - Returns: Helper instance for this isolate
     */
    public static func getInstance(databaseName: String, isolateId: Int64) -> ProfileHelper {
        return isolateQueue.sync {
            if let existing = isolateInstances[isolateId] {
                return existing
            }
            let helper = ProfileHelper(databaseName: databaseName)
            isolateInstances[isolateId] = helper
            return helper
        }
    }

    /**
     * Cleanup resources for a specific isolate.
     * Call this when an isolate is being destroyed.
     *
     * - Parameter isolateId: The isolate ID to cleanup
     */
    public static func cleanupIsolate(isolateId: Int64) {
        isolateQueue.sync {
            isolateInstances.removeValue(forKey: isolateId)
        }
    }

    /**
     * Get all active isolate IDs currently using this helper.
     * Useful for debugging.
     *
     * - Returns: Set of active isolate IDs
     */
    public static func getActiveIsolates() -> Set<Int64> {
        return isolateQueue.sync {
            return Set(isolateInstances.keys)
        }
    }

    public init(databaseName: String) {
        self.databaseName = databaseName
    }

    public func insert(_ entity: Profile) throws -> Int {
        var values: [String: Any] = [:]
        values[ProfileSchema.name] = entity.name
        values[ProfileSchema.email] = entity.email
        values[ProfileSchema.phoneNumber] = entity.phoneNumber ?? NSNull()
        values[ProfileSchema.settings] = entity.settings.flatMap { try? JSONSerialization.data(withJSONObject: $0) }.flatMap { String(data: $0, encoding: .utf8) } ?? NSNull()
        values[ProfileSchema.tags] = entity.tags.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) } ?? NSNull()
        values[ProfileSchema.address] = entity.address ?? NSNull()
        values[ProfileSchema.addresses] = entity.addresses.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) } ?? NSNull()
        values[ProfileSchema.metadata] = entity.metadata
        return try manager.insert(name: databaseName, table: ProfileSchema.tableName, values: values)
    }

    public func findById(_ id: Int) throws -> Profile? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(ProfileSchema.tableName) WHERE \(ProfileSchema.id) = ? LIMIT 1",
            arguments: [id]
        )
        guard let rows = result["rows"] as? [[Any?]], !rows.isEmpty,
              let columns = result["columns"] as? [String] else {
            return nil
        }
        var columnMap: [String: Int] = [:]
        for (index, column) in columns.enumerated() {
            columnMap[column] = index
        }
        return fromRow(columnMap: columnMap, row: rows[0])
    }

    public func findAll() throws -> [Profile] {
        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \(ProfileSchema.tableName)")
        guard let rows = result["rows"] as? [[Any?]],
              let columns = result["columns"] as? [String] else {
            return []
        }
        var columnMap: [String: Int] = [:]
        for (index, column) in columns.enumerated() {
            columnMap[column] = index
        }
        return rows.map { fromRow(columnMap: columnMap, row: $0) }
    }

    /**
     * Update an existing entity.
     * - Parameter entity: The entity to update (must have a valid primary key)
     * - Returns: Number of rows affected
     * - Throws: Database errors
     */
    public func update(_ entity: Profile) throws -> Int {
        var values: [String: Any] = [:]
        values[ProfileSchema.name] = entity.name
        values[ProfileSchema.email] = entity.email
        values[ProfileSchema.phoneNumber] = entity.phoneNumber ?? NSNull()
        values[ProfileSchema.settings] = entity.settings.flatMap { try? JSONSerialization.data(withJSONObject: $0) }.flatMap { String(data: $0, encoding: .utf8) } ?? NSNull()
        values[ProfileSchema.tags] = entity.tags.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) } ?? NSNull()
        values[ProfileSchema.address] = entity.address ?? NSNull()
        values[ProfileSchema.addresses] = entity.addresses.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) } ?? NSNull()
        values[ProfileSchema.metadata] = entity.metadata
        return try manager.update(
            name: databaseName,
            table: ProfileSchema.tableName,
            values: values,
            whereClause: "\(ProfileSchema.id) = ?",
            whereArgs: [entity.id]
        )
    }

    /**
     * Update specific fields of an entity.
     * - Parameters:
     *   - id: The primary key value
     *   - updates: Dictionary of column names to new values
     * - Returns: Number of rows affected
     * - Throws: Database errors
     */
    public func updatePartial(id: Int, updates: [String: Any]) throws -> Int {
        return try manager.update(
            name: databaseName,
            table: ProfileSchema.tableName,
            values: updates,
            whereClause: "\(ProfileSchema.id) = ?",
            whereArgs: [id]
        )
    }

    /**
     * Delete an entity by its primary key.
     * - Parameter id: The primary key value
     * - Returns: Number of rows deleted
     * - Throws: Database errors
     */
    public func delete(id: Int) throws -> Int {
        return try manager.delete(
            name: databaseName,
            table: ProfileSchema.tableName,
            whereClause: "\(ProfileSchema.id) = ?",
            whereArgs: [id]
        )
    }

    /**
     * Delete entities matching a WHERE clause.
     * - Parameters:
     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)
     *   - whereArgs: Arguments for the WHERE clause
     * - Returns: Number of rows deleted
     * - Throws: Database errors
     */
    public func deleteWhere(whereClause: String, whereArgs: [Any?]? = nil) throws -> Int {
        return try manager.delete(
            name: databaseName,
            table: ProfileSchema.tableName,
            whereClause: whereClause,
            whereArgs: whereArgs
        )
    }

    /**
     * Insert multiple entities in a single transaction.
     * - Parameter entities: Array of entities to insert
     * - Returns: Array of inserted row IDs
     * - Throws: Database errors
     */
    public func insertBatch(_ entities: [Profile]) throws -> [Int64] {
        let db = try manager.getDatabase(name: databaseName)
        var results: [Int64] = []
        
        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            for entity in entities {
                let id = try insert(entity)
                results.append(id)
            }
            try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            try? manager.execute(name: databaseName, sql: "ROLLBACK")
            throw error
        }
        return results
    }

    /**
     * Update multiple entities in a single transaction.
     * - Parameter entities: Array of entities to update
     * - Returns: Total number of rows affected
     * - Throws: Database errors
     */
    public func updateBatch(_ entities: [Profile]) throws -> Int {
        var totalAffected = 0
        
        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            for entity in entities {
                totalAffected += try update(entity)
            }
            try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            try? manager.execute(name: databaseName, sql: "ROLLBACK")
            throw error
        }
        return totalAffected
    }

    /**
     * Delete multiple entities by their IDs in a single transaction.
     * - Parameter ids: Array of primary key values
     * - Returns: Total number of rows deleted
     * - Throws: Database errors
     */
    public func deleteBatch(ids: [Int]) throws -> Int {
        var totalDeleted = 0
        
        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            for id in ids {
                totalDeleted += try delete(id: id)
            }
            try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            try? manager.execute(name: databaseName, sql: "ROLLBACK")
            throw error
        }
        return totalDeleted
    }

    /**
     * Find entities matching a WHERE clause with optional ordering and limit.
     * - Parameters:
     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)
     *   - whereArgs: Arguments for the WHERE clause
     *   - orderBy: Column to order by (e.g., "name ASC", "age DESC")
     *   - limit: Maximum number of results
     *   - offset: Number of results to skip
     * - Returns: Array of matching entities
     * - Throws: Database errors
     */
    public func findWhere(
        whereClause: String? = nil,
        whereArgs: [Any?]? = nil,
        orderBy: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [Profile] {
        var sql = "SELECT * FROM \(ProfileSchema.tableName)"
        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }
        if let orderBy = orderBy {
            sql += " ORDER BY \(orderBy)"
        }
        if let limit = limit {
            sql += " LIMIT \(limit)"
        }
        if let offset = offset {
            sql += " OFFSET \(offset)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]],
              let columns = result["columns"] as? [String] else {
            return []
        }
        var columnMap: [String: Int] = [:]
        for (index, column) in columns.enumerated() {
            columnMap[column] = index
        }
        return rows.map { fromRow(columnMap: columnMap, row: $0) }
    }

    /**
     * Count entities matching a WHERE clause.
     * - Parameters:
     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)
     *   - whereArgs: Arguments for the WHERE clause
     * - Returns: Number of matching entities
     * - Throws: Database errors
     */
    public func count(whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Int64 {
        let sql: String
        if let whereClause = whereClause {
            sql = "SELECT COUNT(*) FROM \(ProfileSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT COUNT(*) FROM \(ProfileSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]],
              let count = rows.first?.first as? Int64 else {
            return 0
        }
        return count
    }

    /**
     * Get the maximum value of a column.
     * - Parameters:
     *   - column: Column name to get max value from
     *   - whereClause: Optional WHERE clause
     *   - whereArgs: Arguments for WHERE clause
     * - Returns: Maximum value or nil
     * - Throws: Database errors
     */
    public func max(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Any? {
        let sql: String
        if let whereClause = whereClause {
            sql = "SELECT MAX(\(column)) FROM \(ProfileSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MAX(\(column)) FROM \(ProfileSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first
    }

    /**
     * Get the minimum value of a column.
     * - Parameters:
     *   - column: Column name to get min value from
     *   - whereClause: Optional WHERE clause
     *   - whereArgs: Arguments for WHERE clause
     * - Returns: Minimum value or nil
     * - Throws: Database errors
     */
    public func min(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Any? {
        let sql: String
        if let whereClause = whereClause {
            sql = "SELECT MIN(\(column)) FROM \(ProfileSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MIN(\(column)) FROM \(ProfileSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first
    }

    /**
     * Get the average value of a column.
     * - Parameters:
     *   - column: Column name to get average from
     *   - whereClause: Optional WHERE clause
     *   - whereArgs: Arguments for WHERE clause
     * - Returns: Average value or nil
     * - Throws: Database errors
     */
    public func avg(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Double? {
        let sql: String
        if let whereClause = whereClause {
            sql = "SELECT AVG(\(column)) FROM \(ProfileSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT AVG(\(column)) FROM \(ProfileSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }

    /**
     * Get the sum of a column.
     * - Parameters:
     *   - column: Column name to sum
     *   - whereClause: Optional WHERE clause
     *   - whereArgs: Arguments for WHERE clause
     * - Returns: Sum value or nil
     * - Throws: Database errors
     */
    public func sum(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Double? {
        let sql: String
        if let whereClause = whereClause {
            sql = "SELECT SUM(\(column)) FROM \(ProfileSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT SUM(\(column)) FROM \(ProfileSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }
    }

    private func fromRow(columnMap: [String: Int], row: [Any?]) -> Profile {
        return Profile(
            id: row[columnMap[ProfileSchema.id]!] as? Int,
            name: row[columnMap[ProfileSchema.name]!] as! String,
            email: row[columnMap[ProfileSchema.email]!] as! String,
            phoneNumber: row[columnMap[ProfileSchema.phoneNumber]!] as? String,
            settings: (row[columnMap[ProfileSchema.settings]!] as? String).flatMap { try? JSONSerialization.jsonObject(with: $0.data(using: .utf8)!) as? [String: Any] },
            tags: (row[columnMap[ProfileSchema.tags]!] as? String).flatMap { try? JSONDecoder().decode([Any].self, from: $0.data(using: .utf8)!) },
            address: row[columnMap[ProfileSchema.address]!],
            addresses: (row[columnMap[ProfileSchema.addresses]!] as? String).flatMap { try? JSONDecoder().decode([Any].self, from: $0.data(using: .utf8)!) },
            metadata: row[columnMap[ProfileSchema.metadata]!]
        )
    }
}
