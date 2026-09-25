import Foundation

/**
 * Schema constants for Comment table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/comment.dart
 */
public enum CommentSchema {
    public static let tableName = "comments"

    // Column names
    public static let id = "id"
    public static let parentId = "parent_id"
    public static let body = "body"

    // Same statements as the Dart CommentSchema
    public static let createTableSql = "CREATE TABLE \"comments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"parent_id\" INTEGER, \"body\" TEXT NOT NULL, FOREIGN KEY (\"parent_id\") REFERENCES \"comments\"(\"id\") ON DELETE SET NULL)"

    public static let indexSql: [String] = [
    ]
}
