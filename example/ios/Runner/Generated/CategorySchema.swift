import Foundation

/**
 * Schema constants for Category table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/category.dart
 */
public enum CategorySchema {
    public static let tableName = "categories"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let description = "description"
    public static let createdAt = "created_at"

    // Same statements as the Dart CategorySchema
    public static let createTableSql = "CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, created_at INTEGER NOT NULL)"

    public static let indexSql: [String] = [
    ]
}
