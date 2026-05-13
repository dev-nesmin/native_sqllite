import Foundation

/**
 * Schema constants for StyledItem table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/styled_item.dart
 */
public enum StyledItemSchema {
    public static let tableName = "styled_items"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let backgroundColor = "backgroundColor"
    public static let textColor = "textColor"
    public static let tags = "tags"
    public static let createdAt = "createdAt"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE styled_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            backgroundColor INTEGER NOT NULL,
            textColor INTEGER,
            tags TEXT NOT NULL,
            createdAt INTEGER NOT NULL
        )
        """
}
