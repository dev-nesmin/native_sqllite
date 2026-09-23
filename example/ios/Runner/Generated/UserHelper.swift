import Foundation
import native_sqlite_ios

/**
 * Struct for User.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public struct User {
    public let id: Int64?
    public let name: String
    public let email: String
    public let phoneNumber: String?
    public let address: String?
    public let age: Int64
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date?

    public init(
        id: Int64? = nil,
        name: String,
        email: String,
        phoneNumber: String? = nil,
        address: String? = nil,
        age: Int64,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.address = address
        self.age = age
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/**
 * Helper class for User CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * let helper = UserHelper(databaseName: "example_app")
 * let id = try helper.insert(User(...))
 * let item = try helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In BGTaskScheduler or background isolate
 * let isolateId = Int64(pthread_self())
 * let helper = UserHelper.getInstance(databaseName: "example_app", isolateId: isolateId)
 * let users = try helper.findAll()
 * // When done, cleanup:
 * UserHelper.cleanupIsolate(isolateId: isolateId)
 * ```
 */
public class UserHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    // Track helper instances per isolate for thread safety
    private static var isolateInstances = [Int64: UserHelper]()
    private static let isolateQueue = DispatchQueue(label: "UserHelper.isolate")

    /**
     * Get or create helper instance for the given isolate.
     * Safe to call from different Dart isolates or native threads.
     *
     * - Parameters:
     *   - databaseName: Name of the database
     *   - isolateId: Unique identifier for the isolate/thread
     * - Returns: Helper instance for this isolate
     */
    public static func getInstance(databaseName: String, isolateId: Int64) -> UserHelper {
        return isolateQueue.sync {
            if let existing = isolateInstances[isolateId] {
                return existing
            }
            let helper = UserHelper(databaseName: databaseName)
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
            _ = isolateInstances.removeValue(forKey: isolateId)
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

    public func insert(_ entity: User) throws -> Int64 {
        let values: [String: Any?] = [
            UserSchema.name: entity.name,
            UserSchema.email: entity.email,
            UserSchema.phoneNumber: entity.phoneNumber,
            UserSchema.address: entity.address,
            UserSchema.age: entity.age,
            UserSchema.isActive: (entity.isActive ? Int64(1) : Int64(0)),
            UserSchema.createdAt: GeneratedValue.milliseconds(entity.createdAt),
            UserSchema.updatedAt: entity.updatedAt.map { GeneratedValue.milliseconds($0) },
        ]
        return try manager.insert(name: databaseName, table: UserSchema.tableName, values: values)
    }

    public func findById(_ id: Int64) throws -> User? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(UserSchema.tableName) WHERE \(UserSchema.id) = ? LIMIT 1",
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
        return try fromRow(columnMap: columnMap, row: rows[0])
    }

    public func findAll() throws -> [User] {
        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \(UserSchema.tableName)")
        guard let rows = result["rows"] as? [[Any?]],
              let columns = result["columns"] as? [String] else {
            return []
        }
        var columnMap: [String: Int] = [:]
        for (index, column) in columns.enumerated() {
            columnMap[column] = index
        }
        return try rows.map { try fromRow(columnMap: columnMap, row: $0) }
    }

    /**
     * Update an existing entity.
     * - Parameter entity: The entity to update (must have a valid primary key)
     * - Returns: Number of rows affected
     * - Throws: Database errors
     */
    public func update(_ entity: User) throws -> Int {
        let values: [String: Any?] = [
            UserSchema.name: entity.name,
            UserSchema.email: entity.email,
            UserSchema.phoneNumber: entity.phoneNumber,
            UserSchema.address: entity.address,
            UserSchema.age: entity.age,
            UserSchema.isActive: (entity.isActive ? Int64(1) : Int64(0)),
            UserSchema.createdAt: GeneratedValue.milliseconds(entity.createdAt),
            UserSchema.updatedAt: entity.updatedAt.map { GeneratedValue.milliseconds($0) },
        ]
        return try manager.update(
            name: databaseName,
            table: UserSchema.tableName,
            values: values,
            whereClause: "\(UserSchema.id) = ?",
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
    public func updatePartial(id: Int64, updates: [String: Any?]) throws -> Int {
        return try manager.update(
            name: databaseName,
            table: UserSchema.tableName,
            values: updates,
            whereClause: "\(UserSchema.id) = ?",
            whereArgs: [id]
        )
    }

    /**
     * Delete an entity by its primary key.
     * - Parameter id: The primary key value
     * - Returns: Number of rows deleted
     * - Throws: Database errors
     */
    public func delete(id: Int64) throws -> Int {
        return try manager.delete(
            name: databaseName,
            table: UserSchema.tableName,
            whereClause: "\(UserSchema.id) = ?",
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
            table: UserSchema.tableName,
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
    public func insertBatch(_ entities: [User]) throws -> [Int64] {
        var results: [Int64] = []
        
        _ = try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            for entity in entities {
                let id = try insert(entity)
                results.append(id)
            }
            _ = try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            _ = try? manager.execute(name: databaseName, sql: "ROLLBACK")
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
    public func updateBatch(_ entities: [User]) throws -> Int {
        var totalAffected = 0
        
        _ = try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            for entity in entities {
                totalAffected += try update(entity)
            }
            _ = try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            _ = try? manager.execute(name: databaseName, sql: "ROLLBACK")
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
    public func deleteBatch(ids: [Int64]) throws -> Int {
        var totalDeleted = 0
        
        _ = try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            for id in ids {
                totalDeleted += try delete(id: id)
            }
            _ = try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            _ = try? manager.execute(name: databaseName, sql: "ROLLBACK")
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
    ) throws -> [User] {
        var sql = "SELECT * FROM \(UserSchema.tableName)"
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
        return try rows.map { try fromRow(columnMap: columnMap, row: $0) }
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
            sql = "SELECT COUNT(*) FROM \(UserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT COUNT(*) FROM \(UserSchema.tableName)"
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
            sql = "SELECT MAX(\(column)) FROM \(UserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MAX(\(column)) FROM \(UserSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first ?? nil
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
            sql = "SELECT MIN(\(column)) FROM \(UserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MIN(\(column)) FROM \(UserSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first ?? nil
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
            sql = "SELECT AVG(\(column)) FROM \(UserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT AVG(\(column)) FROM \(UserSchema.tableName)"
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
            sql = "SELECT SUM(\(column)) FROM \(UserSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT SUM(\(column)) FROM \(UserSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }

    private func fromRow(columnMap: [String: Int], row values: [Any?]) throws -> User {
        let row = GeneratedRow(columnMap: columnMap, values: values)
        return User(
            id: try row.optional(UserSchema.id, GeneratedValue.int64, expected: "Int64"),
            name: try row.required(UserSchema.name, GeneratedValue.string, expected: "String"),
            email: try row.required(UserSchema.email, GeneratedValue.string, expected: "String"),
            phoneNumber: try row.optional(UserSchema.phoneNumber, GeneratedValue.string, expected: "String"),
            address: try row.optional(UserSchema.address, GeneratedValue.string, expected: "String"),
            age: try row.required(UserSchema.age, GeneratedValue.int64, expected: "Int64"),
            isActive: try row.required(UserSchema.isActive, GeneratedValue.bool, expected: "Bool"),
            createdAt: try row.required(UserSchema.createdAt, GeneratedValue.date, expected: "Date"),
            updatedAt: try row.optional(UserSchema.updatedAt, GeneratedValue.date, expected: "Date")
        )
    }
}
