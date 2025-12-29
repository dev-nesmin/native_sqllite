import Foundation

/**
 * Schema constants for FreezedAdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/freezed_advanced_user.dart
 */
public enum FreezedAdvancedUserSchema {
    public static let tableName = "advanced_users"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let loginDuration = "loginDuration"
    public static let profileUrl = "profileUrl"
    public static let status = "status"
    public static let priority = "priority"
    public static let createdAt = "createdAt"
    public static let isVerified = "isVerified"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE advanced_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            loginDuration INTEGER,
            profileUrl TEXT,
            status INTEGER NOT NULL,
            priority INTEGER,
            createdAt INTEGER NOT NULL,
            isVerified INTEGER NOT NULL
        )
        """
}
