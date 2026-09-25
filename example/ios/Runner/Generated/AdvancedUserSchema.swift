import Foundation

/**
 * Schema constants for AdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/advanced.dart
 */
public enum AdvancedUserSchema {
    public static let tableName = "advanced_users"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let phoneNumber = "phone_number"
    public static let address = "address"
    public static let country = "country"
    public static let zipCode = "zip_code"
    public static let age = "age"
    public static let city = "city"
    public static let loginDuration = "login_duration"
    public static let profileUrl = "profile_url"
    public static let score = "score"
    public static let status = "status"
    public static let priority = "priority"
    public static let createdAt = "created_at"
    public static let isVerified = "is_verified"

    // Same statements as the Dart AdvancedUserSchema
    public static let createTableSql = "CREATE TABLE \"advanced_users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"phone_number\" TEXT, \"address\" TEXT, \"country\" TEXT, \"zip_code\" TEXT, \"age\" INTEGER, \"city\" TEXT, \"login_duration\" INTEGER, \"profile_url\" TEXT, \"score\" REAL, \"status\" INTEGER NOT NULL, \"priority\" TEXT, \"created_at\" INTEGER NOT NULL, \"is_verified\" INTEGER NOT NULL)"

    public static let indexSql: [String] = [
    ]
}
