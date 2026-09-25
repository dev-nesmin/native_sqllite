import Foundation

/**
 * Schema constants for SyncEvent table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/sync_event.dart
 */
public enum SyncEventSchema {
    public static let tableName = "sync_events"

    // Column names
    public static let id = "id"
    public static let source = "source"
    public static let message = "message"
    public static let createdAt = "created_at"

    // Same statements as the Dart SyncEventSchema
    public static let createTableSql = "CREATE TABLE \"sync_events\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"source\" TEXT NOT NULL, \"message\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)"

    public static let indexSql: [String] = [
        "CREATE INDEX \"idx_sync_events_created_at\" ON \"sync_events\" (\"created_at\")",
    ]
}
