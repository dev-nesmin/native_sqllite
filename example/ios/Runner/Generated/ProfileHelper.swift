import Foundation
import native_sqlite_ios

/**
 * Struct for Profile.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public struct Profile {
    public let id: Int64?
    public let name: String
    public let email: String
    public let phoneNumber: String?
    /// Raw JSON text of Dart `Map<String, dynamic>?`.
    public let settings: String?
    /// Raw JSON text of Dart `List<String>?`.
    public let tags: String?
    /// Raw JSON text of Dart `Address?`.
    public let address: String?
    /// Raw JSON text of Dart `List<Address>?`.
    public let addresses: String?
    /// Raw JSON text of Dart `dynamic`.
    public let metadata: String

    public init(
        id: Int64? = nil,
        name: String,
        email: String,
        phoneNumber: String? = nil,
        settings: String? = nil,
        tags: String? = nil,
        address: String? = nil,
        addresses: String? = nil,
        metadata: String
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
 * Create an instance for each native caller/database.
 *
 * Example usage (single isolate):
 * ```
 * let helper = ProfileHelper(databaseName: "example_app")
 * let id = try helper.insert(Profile(...))
 * let item = try helper.findById(id)
 * ```
 */
public class ProfileHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    public init(databaseName: String) {
        self.databaseName = databaseName
    }

    public func insert(_ entity: Profile) throws -> Int64 {
        let values: [String: Any?] = [
            ProfileSchema.name: entity.name,
            ProfileSchema.email: entity.email,
            ProfileSchema.phoneNumber: entity.phoneNumber,
            ProfileSchema.settings: entity.settings,
            ProfileSchema.tags: entity.tags,
            ProfileSchema.address: entity.address,
            ProfileSchema.addresses: entity.addresses,
            ProfileSchema.metadata: entity.metadata,
        ]
        return try manager.insert(name: databaseName, table: ProfileSchema.tableName, values: values)
    }

    public func findById(_ id: Int64) throws -> Profile? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName)) WHERE \(NativeSqliteManager.quoteIdentifier(ProfileSchema.id)) = ? LIMIT 1",
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

    public func findAll() throws -> [Profile] {
        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))")
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
    public func update(_ entity: Profile) throws -> Int {
        let values: [String: Any?] = [
            ProfileSchema.name: entity.name,
            ProfileSchema.email: entity.email,
            ProfileSchema.phoneNumber: entity.phoneNumber,
            ProfileSchema.settings: entity.settings,
            ProfileSchema.tags: entity.tags,
            ProfileSchema.address: entity.address,
            ProfileSchema.addresses: entity.addresses,
            ProfileSchema.metadata: entity.metadata,
        ]
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
    public func updatePartial(id: Int64, updates: [String: Any?]) throws -> Int {
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
    public func delete(id: Int64) throws -> Int {
        return try manager.delete(
            name: databaseName,
            table: ProfileSchema.tableName,
            whereClause: "\(ProfileSchema.id) = ?",
            whereArgs: [id]
        )
    }

    /**
     * Delete entities matching a WHERE clause.
     * Important: `whereClause` is trusted SQL. Never pass user input; use `whereArgs` for values.
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
    public func updateBatch(_ entities: [Profile]) throws -> Int {
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
     * Important: `whereClause` and `orderBy` are trusted SQL. Never pass user input; use `whereArgs` for values.
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
        var sql = "SELECT * FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))"
        if let whereClause = whereClause {
            sql += " WHERE \(whereClause)"
        }
        if let orderBy = orderBy {
            sql += " ORDER BY \(orderBy)"
        }
        if let limit = limit {
            sql += " LIMIT \(limit)"
        } else if offset != nil {
            sql += " LIMIT -1"
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
     * Important: `whereClause` is trusted SQL. Never pass user input; use `whereArgs` for values.
     * - Parameters:
     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)
     *   - whereArgs: Arguments for the WHERE clause
     * - Returns: Number of matching entities
     * - Throws: Database errors
     */
    public func count(whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Int64 {
        let sql: String
        if let whereClause = whereClause {
            sql = "SELECT COUNT(*) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName)) WHERE \(whereClause)"
        } else {
            sql = "SELECT COUNT(*) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))"
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
     * Important: `whereClause` is trusted SQL. Never pass user input; use `whereArgs` for values.
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
            sql = "SELECT MAX(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName)) WHERE \(whereClause)"
        } else {
            sql = "SELECT MAX(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first ?? nil
    }

    /**
     * Get the minimum value of a column.
     * Important: `whereClause` is trusted SQL. Never pass user input; use `whereArgs` for values.
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
            sql = "SELECT MIN(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName)) WHERE \(whereClause)"
        } else {
            sql = "SELECT MIN(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first ?? nil
    }

    /**
     * Get the average value of a column.
     * Important: `whereClause` is trusted SQL. Never pass user input; use `whereArgs` for values.
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
            sql = "SELECT AVG(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName)) WHERE \(whereClause)"
        } else {
            sql = "SELECT AVG(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }

    /**
     * Get the sum of a column.
     * Important: `whereClause` is trusted SQL. Never pass user input; use `whereArgs` for values.
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
            sql = "SELECT SUM(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName)) WHERE \(whereClause)"
        } else {
            sql = "SELECT SUM(\(NativeSqliteManager.quoteIdentifier(column))) FROM \(NativeSqliteManager.quoteIdentifier(ProfileSchema.tableName))"
        }
        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)
        guard let rows = result["rows"] as? [[Any?]] else { return nil }
        return rows.first?.first as? Double
    }

    private func fromRow(columnMap: [String: Int], row values: [Any?]) throws -> Profile {
        let row = GeneratedRow(columnMap: columnMap, values: values)
        return Profile(
            id: try row.optional(ProfileSchema.id, GeneratedValue.int64, expected: "Int64"),
            name: try row.required(ProfileSchema.name, GeneratedValue.string, expected: "String"),
            email: try row.required(ProfileSchema.email, GeneratedValue.string, expected: "String"),
            phoneNumber: try row.optional(ProfileSchema.phoneNumber, GeneratedValue.string, expected: "String"),
            settings: try row.optional(ProfileSchema.settings, GeneratedValue.string, expected: "String"),
            tags: try row.optional(ProfileSchema.tags, GeneratedValue.string, expected: "String"),
            address: try row.optional(ProfileSchema.address, GeneratedValue.string, expected: "String"),
            addresses: try row.optional(ProfileSchema.addresses, GeneratedValue.string, expected: "String"),
            metadata: try row.required(ProfileSchema.metadata, GeneratedValue.string, expected: "String")
        )
    }
}
