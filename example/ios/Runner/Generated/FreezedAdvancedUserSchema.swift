import Foundation

/**
 * Schema constants for FreezedAdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/freezed_advanced_user.dart
 */
public enum FreezedAdvancedUserSchema {
    public static let tableName = "freezed_advanced_users"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let loginDuration = "login_duration"
    public static let profileUrl = "profile_url"
    public static let status = "status"
    public static let priority = "priority"
    public static let createdAt = "created_at"
    public static let isVerified = "is_verified"

    // Same statements as the Dart FreezedAdvancedUserSchema
    public static let createTableSql = "CREATE TABLE freezed_advanced_users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, login_duration INTEGER, profile_url TEXT, status INTEGER NOT NULL, priority INTEGER, created_at INTEGER NOT NULL, is_verified INTEGER NOT NULL)"

    public static let indexSql: [String] = [
    ]
}
