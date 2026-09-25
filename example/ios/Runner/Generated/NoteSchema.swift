import Foundation

/**
 * Schema constants for Note table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/note.dart
 */
public enum NoteSchema {
    public static let tableName = "notes"

    // Column names
    public static let id = "id"
    public static let body = "body"

    // Same statements as the Dart NoteSchema
    public static let createTableSql = "CREATE TABLE \"notes\" (\"id\" TEXT PRIMARY KEY NOT NULL, \"body\" TEXT NOT NULL)"

    public static let indexSql: [String] = [
    ]
}
