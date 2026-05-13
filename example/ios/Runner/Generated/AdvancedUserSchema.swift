import Foundation

/**
 * Schema constants for AdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/advanced_user.dart
 */
public enum AdvancedUserSchema {
    public static let tableName = "advanced_users"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let phoneNumber = "phoneNumber"
    public static let address = "address"
    public static let country = "country"
    public static let zipCode = "zipCode"
    public static let age = "age"
    public static let city = "city"
    public static let loginDuration = "loginDuration"
    public static let profileUrl = "profileUrl"
    public static let score = "score"
    public static let status = "status"
    public static let priority = "priority"
    public static let createdAt = "createdAt"
    public static let isVerified = "isVerified"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE advanced_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phoneNumber TEXT,
            address TEXT,
            country TEXT,
            zipCode TEXT,
            age INTEGER,
            city TEXT,
            loginDuration INTEGER,
            profileUrl TEXT,
            score REAL,
            status INTEGER NOT NULL,
            priority TEXT,
            createdAt INTEGER NOT NULL,
            isVerified INTEGER NOT NULL
        )
        """
}
