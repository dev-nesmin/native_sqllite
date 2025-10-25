import Foundation
import native_sqlite_ios

/**
 * Struct matching the User model in Dart.
 */
public struct User {
    public let id: Int?
    public let name: String
    public let email: String
    public let age: Int?
    public let isActive: Bool
    public let createdAt: Int
    public let lastLogin: Int?

    public init(
        id: Int? = nil,
        name: String,
        email: String,
        age: Int? = nil,
        isActive: Bool = true,
        createdAt: Int,
        lastLogin: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLogin = lastLogin
    }
}

/**
 * Helper class for User CRUD operations in native Swift code.
 *
 * Example usage:
 * ```swift
 * let userHelper = UserHelper(databaseName: "app_db")
 *
 * // Insert
 * let userId = try userHelper.insert(User(
 *     name: "John Doe",
 *     email: "john@example.com",
 *     createdAt: Int(Date().timeIntervalSince1970 * 1000)
 * ))
 *
 * // Find
 * if let user = try userHelper.findById(userId) {
 *     // Update
 *     try userHelper.update(User(
 *         id: user.id,
 *         name: "Jane Doe",
 *         email: user.email,
 *         isActive: user.isActive,
 *         createdAt: user.createdAt
 *     ))
 * }
 *
 * // Delete
 * try userHelper.delete(userId)
 * ```
 */
public class UserHelper {
    private let databaseName: String
    private let manager = NativeSqliteManager.shared

    public init(databaseName: String) {
        self.databaseName = databaseName
    }

    /**
     * Inserts a new user into the database.
     * - Returns: The ID of the inserted user
     */
    public func insert(_ user: User) throws -> Int {
        var values: [String: Any] = [
            UserSchema.name: user.name,
            UserSchema.email: user.email,
            UserSchema.isActive: user.isActive ? 1 : 0,
            UserSchema.createdAt: user.createdAt
        ]

        if let age = user.age {
            values[UserSchema.age] = age
        }

        if let lastLogin = user.lastLogin {
            values[UserSchema.lastLogin] = lastLogin
        }

        return try manager.insert(
            name: databaseName,
            table: UserSchema.tableName,
            values: values
        )
    }

    /**
     * Finds a user by ID.
     * - Returns: The user if found, nil otherwise
     */
    public func findById(_ id: Int) throws -> User? {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(UserSchema.tableName) WHERE \(UserSchema.id) = ? LIMIT 1",
            arguments: [id]
        )

        guard let rows = result["rows"] as? [[Any?]], !rows.isEmpty,
              let columns = result["columns"] as? [String] else {
            return nil
        }

        return fromRow(columns: columns, row: rows[0])
    }

    /**
     * Finds all users in the database.
     * - Returns: List of all users
     */
    public func findAll() throws -> [User] {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(UserSchema.tableName)"
        )

        guard let rows = result["rows"] as? [[Any?]],
              let columns = result["columns"] as? [String] else {
            return []
        }

        return rows.map { fromRow(columns: columns, row: $0) }
    }

    /**
     * Finds all active users.
     * - Returns: List of active users
     */
    public func findActiveUsers() throws -> [User] {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT * FROM \(UserSchema.tableName) WHERE \(UserSchema.isActive) = ?",
            arguments: [1]
        )

        guard let rows = result["rows"] as? [[Any?]],
              let columns = result["columns"] as? [String] else {
            return []
        }

        return rows.map { fromRow(columns: columns, row: $0) }
    }

    /**
     * Updates an existing user.
     * - Returns: Number of rows affected
     */
    public func update(_ user: User) throws -> Int {
        guard let id = user.id else {
            throw NSError(
                domain: "UserHelper",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "User ID cannot be nil for update"]
            )
        }

        var values: [String: Any] = [
            UserSchema.name: user.name,
            UserSchema.email: user.email,
            UserSchema.isActive: user.isActive ? 1 : 0,
            UserSchema.createdAt: user.createdAt
        ]

        if let age = user.age {
            values[UserSchema.age] = age
        }

        if let lastLogin = user.lastLogin {
            values[UserSchema.lastLogin] = lastLogin
        }

        return try manager.update(
            name: databaseName,
            table: UserSchema.tableName,
            values: values,
            whereClause: "\(UserSchema.id) = ?",
            whereArgs: [id]
        )
    }

    /**
     * Deletes a user by ID.
     * - Returns: Number of rows deleted
     */
    public func delete(_ id: Int) throws -> Int {
        return try manager.delete(
            name: databaseName,
            table: UserSchema.tableName,
            whereClause: "\(UserSchema.id) = ?",
            whereArgs: [id]
        )
    }

    /**
     * Counts total users.
     * - Returns: Total number of users
     */
    public func count() throws -> Int {
        let result = try manager.query(
            name: databaseName,
            sql: "SELECT COUNT(*) as count FROM \(UserSchema.tableName)"
        )

        guard let rows = result["rows"] as? [[Any?]], !rows.isEmpty else {
            return 0
        }

        return rows[0][0] as? Int ?? 0
    }

    /**
     * Converts a database row to a User object.
     */
    private func fromRow(columns: [String], row: [Any?]) -> User {
        var columnMap: [String: Int] = [:]
        for (index, column) in columns.enumerated() {
            columnMap[column] = index
        }

        return User(
            id: row[columnMap[UserSchema.id]!] as? Int,
            name: row[columnMap[UserSchema.name]!] as! String,
            email: row[columnMap[UserSchema.email]!] as! String,
            age: row[columnMap[UserSchema.age]!] as? Int,
            isActive: (row[columnMap[UserSchema.isActive]!] as! Int) == 1,
            createdAt: row[columnMap[UserSchema.createdAt]!] as! Int,
            lastLogin: row[columnMap[UserSchema.lastLogin]!] as? Int
        )
    }
}
