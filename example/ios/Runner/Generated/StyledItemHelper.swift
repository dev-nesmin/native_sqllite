import Foundation

/**
 * Struct for StyledItem.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public struct StyledItem {
    public let id: Int?
    public let name: String
    public let backgroundColor: Any
    public let textColor: Any?
    public let tags: String
    public let createdAt: Int

    public init(
        id: Int? = nil,
        name: String,
        backgroundColor: Any,
        textColor: Any?,
        tags: String,
        createdAt: Int
    ) {
        self.id = id
        self.name = name
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.tags = tags
        self.createdAt = createdAt
    }
}

/**
 * Helper class for StyledItem CRUD operations.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Thread-safe for multi-isolate access.
 *
 * Example usage (single isolate):
 * ```
 * let helper = StyledItemHelper(databaseName: "example_app")
 * let id = try helper.insert(StyledItem(...))
 * let item = try helper.findById(id)
 * ```
 *
 * Example usage (multi-isolate safe):
 * ```
 * // In BGTaskScheduler or background isolate
 * let isolateId = Int64(pthread_self())
 * let helper = StyledItemHelper.getInstance(databaseName: "example_app", isolateId: isolateId)
 * let users = try helper.findAll()
 * // When done, cleanup:
 * StyledItemHelper.cleanupIsolate(isolateId: isolateId)
 * ```
 */
public class StyledItemHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    // Track helper instances per isolate for thread safety
    private static var isolateInstances = [Int64: StyledItemHelper]()
    private static let isolateQueue = DispatchQueue(label: "StyledItemHelper.isolate")

    /**
     * Get or create helper instance for the given isolate.
     * Safe to call from different Dart isolates or native threads.
     *
     * - Parameters:
     *   - databaseName: Name of the database
     *   - isolateId: Unique identifier for the isolate/thread
     * - Returns: Helper instance for this isolate
     */
    public static func getInstance(databaseName: String, isolateId: Int64) -> StyledItemHelper {
        return isolateQueue.sync {
            if let existing = isolateInstances[isolateId] {
                return existing
            }
            let helper = StyledItemHelper(databaseName: databaseName)
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

    public func insert(_ entity: StyledItem) throws -> Int64 {
        var values: [String: Any] = [:]
        values[StyledItemSchema.name] = entity.name
        values[StyledItemSchema.backgroundColor] = entity.backgroundColor
        values[StyledItemSchema.textColor] = entity.textColor ?? NSNull()
        values[StyledItemSchema.tags] = try! String(data: JSONEncoder().encode(entity.tags), encoding: .utf8)!
        values[StyledItemSchema.createdAt] = Int(entity.createdAt.timeIntervalSince1970 * 1000)
        return try manager.insert(name: databaseName, table: StyledItemSchema.tableName, values: values)
    }

    public func findById(_ id: Int) throws -> StyledItem? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(StyledItemSchema.tableName) WHERE \(StyledItemSchema.id) = ? LIMIT 1",
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

    public func findAll() throws -> [StyledItem] {
        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \(StyledItemSchema.tableName)")
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
    public func update(_ entity: StyledItem) throws -> Int {
        var values: [String: Any] = [:]
        values[StyledItemSchema.name] = entity.name
        values[StyledItemSchema.backgroundColor] = entity.backgroundColor
        values[StyledItemSchema.textColor] = entity.textColor ?? NSNull()
        values[StyledItemSchema.tags] = try! String(data: JSONEncoder().encode(entity.tags), encoding: .utf8)!
        values[StyledItemSchema.createdAt] = Int(entity.createdAt.timeIntervalSince1970 * 1000)
        return try manager.update(
            name: databaseName,
            table: StyledItemSchema.tableName,
            values: values,
            whereClause: "\(StyledItemSchema.id) = ?",
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
            table: StyledItemSchema.tableName,
            values: updates,
            whereClause: "\(StyledItemSchema.id) = ?",
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
            table: StyledItemSchema.tableName,
            whereClause: "\(StyledItemSchema.id) = ?",
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
            table: StyledItemSchema.tableName,
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
    public func insertBatch(_ entities: [StyledItem]) throws -> [Int64] {
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
    public func updateBatch(_ entities: [StyledItem]) throws -> Int {
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
    ) throws -> [StyledItem] {
        var sql = "SELECT * FROM \(StyledItemSchema.tableName)"
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
            sql = "SELECT COUNT(*) FROM \(StyledItemSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT COUNT(*) FROM \(StyledItemSchema.tableName)"
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
            sql = "SELECT MAX(\(column)) FROM \(StyledItemSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MAX(\(column)) FROM \(StyledItemSchema.tableName)"
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
            sql = "SELECT MIN(\(column)) FROM \(StyledItemSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT MIN(\(column)) FROM \(StyledItemSchema.tableName)"
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
            sql = "SELECT AVG(\(column)) FROM \(StyledItemSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT AVG(\(column)) FROM \(StyledItemSchema.tableName)"
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
            sql = "SELECT SUM(\(column)) FROM \(StyledItemSchema.tableName) WHERE \(whereClause)"
        } else {
            sql = "SELECT SUM(\(column)) FROM \(StyledItemSchema.tableName)"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }

    private func fromRow(columnMap: [String: Int], row: [Any?]) -> StyledItem {
        return StyledItem(
            id: row[columnMap[StyledItemSchema.id]!] as? Int,
            name: row[columnMap[StyledItemSchema.name]!] as! String,
            backgroundColor: row[columnMap[StyledItemSchema.backgroundColor]!],
            textColor: row[columnMap[StyledItemSchema.textColor]!],
            tags: try! JSONDecoder().decode([Any].self, from: (row[columnMap[StyledItemSchema.tags]!] as! String).data(using: .utf8)!),
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[columnMap[StyledItemSchema.createdAt]!] as! Int) / 1000)
        )
    }
}
