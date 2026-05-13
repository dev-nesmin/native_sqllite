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
    public static let createdAt = "createdAt"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            createdAt INTEGER NOT NULL
        )
        """
}
