import Foundation

/**
 * Schema constants for Tag table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/tag.dart
 */
public enum TagSchema {
    public static let tableName = "tags"

    // Column names
    public static let id = "id"
    public static let label = "label_text"

    // Same statements as the Dart TagSchema
    public static let createTableSql = "CREATE TABLE \"tags\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"label_text\" TEXT NOT NULL)"

    public static let indexSql: [String] = [
        "CREATE UNIQUE INDEX \"idx_tags_label_unique\" ON \"tags\" (\"label_text\")",
    ]
}
