import Foundation

/**
 * Schema constants for Attachment table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/attachment.dart
 */
public enum AttachmentSchema {
    public static let tableName = "attachments"

    // Column names
    public static let id = "id"
    public static let filename = "filename"
    public static let bytes = "bytes"

    // Same statements as the Dart AttachmentSchema
    public static let createTableSql = "CREATE TABLE \"attachments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"filename\" TEXT NOT NULL, \"bytes\" BLOB NOT NULL)"

    public static let indexSql: [String] = [
    ]
}
