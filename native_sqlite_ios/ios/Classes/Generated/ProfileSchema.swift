import Foundation

/**
 * Schema constants for Profile table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/profile.dart
 */
public enum ProfileSchema {
    public static let tableName = "profiles"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let email = "email"
    public static let phoneNumber = "phone_number"
    public static let settings = "settings"
    public static let tags = "tags"
    public static let address = "address"
    public static let addresses = "addresses"
    public static let metadata = "metadata"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone_number TEXT,
            settings TEXT,
            tags TEXT,
            address TEXT,
            addresses TEXT,
            metadata TEXT NOT NULL
        )
        """
}
