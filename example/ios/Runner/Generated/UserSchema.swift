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
    public static let phoneNumber = "phone_number"
    public static let address = "address"
    public static let age = "age"
    public static let isActive = "is_active"
    public static let createdAt = "created_at"
    public static let updatedAt = "updated_at"

    // Same statements as the Dart UserSchema
    public static let createTableSql = "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, phone_number TEXT, address TEXT, age INTEGER NOT NULL DEFAULT 1, is_active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL, updated_at INTEGER)"

    public static let indexSql: [String] = [
        "CREATE INDEX idx_users_email ON users (email)",
        "CREATE INDEX idx_users_created_at ON users (created_at)",
    ]
}
