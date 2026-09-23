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
    public static let backgroundColor = "background_color"
    public static let textColor = "text_color"
    public static let tags = "tags"
    public static let createdAt = "created_at"

    // Same statements as the Dart StyledItemSchema
    public static let createTableSql = "CREATE TABLE styled_items (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, background_color INTEGER NOT NULL, text_color INTEGER, tags TEXT NOT NULL, created_at INTEGER NOT NULL)"

    public static let indexSql: [String] = [
    ]
}
