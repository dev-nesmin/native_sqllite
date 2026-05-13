import Foundation

/**
 * Schema constants for User table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/user.dart
 */
public enum UserSchema {
    public static let tableName = "users"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let email = "email"
    public static let phoneNumber = "phoneNumber"
    public static let address = "address"
    public static let age = "age"
    public static let isActive = "isActive"
    public static let createdAt = "createdAt"
    public static let updatedAt = "updatedAt"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            phoneNumber TEXT,
            address TEXT,
            age INTEGER NOT NULL,
            isActive INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER
        )
        """
}
