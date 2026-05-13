import Foundation

/**
 * Struct for AdvancedUser.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public struct AdvancedUser {
    public let id: Int?
    public let name: String
    public let phoneNumber: String?
    public let address: String?
    public let country: String?
    public let zipCode: String?
    public let age: Int?
    public let city: String?
    public let loginDuration: Any?
    public let profileUrl: Any?
    public let score: Any?
    public let status: Any
    public let priority: Any?
    public let createdAt: Int
    public let isVerified: Bool

    public init(
        id: Int? = nil,
        name: String,
        phoneNumber: String?,
        address: String?,
        country: String?,
        zipCode: String?,
        age: Int?,
        city: String?,
        loginDuration: Any?,
        profileUrl: Any?,
        score: Any?,
        status: Any,
        priority: Any?,
        createdAt: Int,
        isVerified: Bool
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.address = address
        self.country = country
        self.zipCode = zipCode
        self.age = age
        self.city = city
        self.loginDuration = loginDuration
        self.profileUrl = profileUrl
        self.score = score
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.isVerified = isVerified
    }
}

/**
 * Helper class for AdvancedUser CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * let helper = AdvancedUserHelper(databaseName: "example_app")
 * let id = try helper.insert(AdvancedUser(...))
 * let item = try helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In BGTaskScheduler or background isolate
 * let isolateId = Int64(pthread_self())
 * let helper = AdvancedUserHelper.getInstance(databaseName: "example_app", isolateId: isolateId)
 * let users = try helper.findAll()
 * // When done, cleanup:
 * AdvancedUserHelper.cleanupIsolate(isolateId: isolateId)
 * ```
 */
public class AdvancedUserHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    // Track helper instances per isolate for thread safety
    private static var isolateInstances = [Int64: AdvancedUserHelper]()
    private static let isolateQueue = DispatchQueue(label: "AdvancedUserHelper.isolate")

    /**
     * Get or create helper instance for the given isolate.
     * Safe to call from different Dart isolates or native threads.
     *
     * - Parameters:
     *   - databaseName: Name of the database
     *   - isolateId: Unique identifier for the isolate/thread
     * - Returns: Helper instance for this isolate
     */
    public static func getInstance(databaseName: String, isolateId: Int64) -> AdvancedUserHelper {
        return isolateQueue.sync {
            if let existing = isolateInstances[isolateId] {
                return existing
            }
            let helper = AdvancedUserHelper(databaseName: databaseName)
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

    public func insert(_ entity: AdvancedUser) throws -> Int {
        var values: [String: Any] = [:]
        values[AdvancedUserSchema.name] = entity.name
        values[AdvancedUserSchema.phoneNumber] = entity.phoneNumber ?? NSNull()
        values[AdvancedUserSchema.address] = entity.address ?? NSNull()
        values[AdvancedUserSchema.country] = entity.country ?? NSNull()
        values[AdvancedUserSchema.zipCode] = entity.zipCode ?? NSNull()
        values[AdvancedUserSchema.age] = entity.age ?? NSNull()
        values[AdvancedUserSchema.city] = entity.city ?? NSNull()
        values[AdvancedUserSchema.loginDuration] = entity.loginDuration ?? NSNull()
        values[AdvancedUserSchema.profileUrl] = entity.profileUrl ?? NSNull()
        values[AdvancedUserSchema.score] = entity.score ?? NSNull()
        values[AdvancedUserSchema.status] = entity.status
        values[AdvancedUserSchema.priority] = entity.priority ?? NSNull()
        values[AdvancedUserSchema.createdAt] = Int(entity.createdAt.timeIntervalSince1970 * 1000)
        values[AdvancedUserSchema.isVerified] = entity.isVerified ? 1 : 0
        return try manager.insert(name: databaseName, table: AdvancedUserSchema.tableName, values: values)
    }

    public func findById(_ id: Int) throws -> AdvancedUser? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(AdvancedUserSchema.tableName) WHERE \(AdvancedUserSchema.id) = ? LIMIT 1",
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

    public func findAll() throws -> [AdvancedUser] {
        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \(AdvancedUserSchema.tableName)")
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
    public func update(_ entity: AdvancedUser) throws -> Int {
        var values: [String: Any] = [:]
        values[AdvancedUserSchema.name] = entity.name
        values[AdvancedUserSchema.phoneNumber] = entity.phoneNumber ?? NSNull()
        values[AdvancedUserSchema.address] = entity.address ?? NSNull()
        values[AdvancedUserSchema.country] = entity.country ?? NSNull()
        values[AdvancedUserSchema.zipCode] = entity.zipCode ?? NSNull()
        values[AdvancedUserSchema.age] = entity.age ?? NSNull()
        values[AdvancedUserSchema.city] = entity.city ?? NSNull()
        values[AdvancedUserSchema.loginDuration] = entity.loginDuration ?? NSNull()
        values[AdvancedUserSchema.profileUrl] = entity.profileUrl ?? NSNull()
        values[AdvancedUserSchema.score] = entity.score ?? NSNull()
        values[AdvancedUserSchema.status] = entity.status
        values[AdvancedUserSchema.priority] = entity.priority ?? NSNull()
        values[AdvancedUserSchema.createdAt] = Int(entity.createdAt.timeIntervalSince1970 * 1000)
        values[AdvancedUserSchema.isVerified] = entity.isVerified ? 1 : 0
        return try manager.update(
            name: databaseName,
            table: AdvancedUserSchema.tableName,
            values: values,
            whereClause: "\(AdvancedUserSchema.id) = ?",
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
            table: AdvancedUserSchema.tableName,
            values: updates,
            whereClause: "\(AdvancedUserSchema.id) = ?",
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
            table: AdvancedUserSchema.tableName,
            whereClause: "\(AdvancedUserSchema.id) = ?",
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
            table: AdvancedUserSchema.tableName,
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
    public func insertBatch(_ entities: [AdvancedUser]) throws -> [Int64] {
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
    public func updateBatch(_ entities: [AdvancedUser]) throws -> Int {
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
    ) throws -> [AdvancedUser] {
        var sql = "SELECT * FROM \(AdvancedUserSchema.tableName)"
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
            sql = "SELECT COUNT(*) FROM \(AdvancedUserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT COUNT(*) FROM \(AdvancedUserSchema.tableName)"
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
            sql = "SELECT MAX(\(column)) FROM \(AdvancedUserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MAX(\(column)) FROM \(AdvancedUserSchema.tableName)"
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
            sql = "SELECT MIN(\(column)) FROM \(AdvancedUserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MIN(\(column)) FROM \(AdvancedUserSchema.tableName)"
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
            sql = "SELECT AVG(\(column)) FROM \(AdvancedUserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT AVG(\(column)) FROM \(AdvancedUserSchema.tableName)"
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
            sql = "SELECT SUM(\(column)) FROM \(AdvancedUserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT SUM(\(column)) FROM \(AdvancedUserSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }
    }

    private func fromRow(columnMap: [String: Int], row: [Any?]) -> AdvancedUser {
        return AdvancedUser(
            id: row[columnMap[AdvancedUserSchema.id]!] as? Int,
            name: row[columnMap[AdvancedUserSchema.name]!] as! String,
            phoneNumber: row[columnMap[AdvancedUserSchema.phoneNumber]!] as? String,
            address: row[columnMap[AdvancedUserSchema.address]!] as? String,
            country: row[columnMap[AdvancedUserSchema.country]!] as? String,
            zipCode: row[columnMap[AdvancedUserSchema.zipCode]!] as? String,
            age: row[columnMap[AdvancedUserSchema.age]!] as? Int,
            city: row[columnMap[AdvancedUserSchema.city]!] as? String,
            loginDuration: row[columnMap[AdvancedUserSchema.loginDuration]!],
            profileUrl: row[columnMap[AdvancedUserSchema.profileUrl]!],
            score: row[columnMap[AdvancedUserSchema.score]!],
            status: row[columnMap[AdvancedUserSchema.status]!],
            priority: row[columnMap[AdvancedUserSchema.priority]!],
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[columnMap[AdvancedUserSchema.createdAt]!] as! Int) / 1000),
            isVerified: (row[columnMap[AdvancedUserSchema.isVerified]!] as! Int) == 1
        )
    }
}
